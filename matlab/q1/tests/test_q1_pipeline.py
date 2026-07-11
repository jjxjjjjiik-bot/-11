import unittest
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import least_squares


Q1_DIR = Path(__file__).resolve().parents[1]
OUTPUT_DIR = Q1_DIR / "output"
YEARS = np.array([1992.0, 2002.0, 2012.0, 2020.0, 2023.0])
RATES = np.array([20.0, 29.9, 42.0, 50.7, 57.0])
FUTURE_YEARS = np.array([2025.0, 2030.0, 2035.0, 2040.0, 2045.0, 2050.0])


def fit_model(model, years, rates, carrying_capacity=100.0):
    if model == "Logistic":
        func = lambda p, t: carrying_capacity / (
            1.0 + np.exp(-p[0] * (t - p[1]))
        )
        initial = np.array([0.05, 2018.0])
        bounds = (np.array([0.001, 1950.0]), np.array([0.5, 2100.0]))
    elif model == "Gompertz":
        func = lambda p, t: carrying_capacity * np.exp(
            -p[0] * np.exp(-p[1] * (t - 1992.0))
        )
        initial = np.array([1.5, 0.03])
        bounds = (np.array([0.001, 0.001]), np.array([10.0, 0.5]))
    else:
        raise ValueError(model)

    result = least_squares(
        lambda p: func(p, years) - rates,
        initial,
        bounds=bounds,
        ftol=1e-13,
        xtol=1e-13,
        gtol=1e-13,
        max_nfev=100000,
    )
    return result.x, func


def expected_metrics(model, carrying_capacity=100.0):
    params, func = fit_model(model, YEARS, RATES, carrying_capacity)
    fitted = func(params, YEARS)
    residual = RATES - fitted
    metrics = {
        "rmse": np.sqrt(np.mean(residual**2)),
        "mape": np.mean(np.abs(residual / RATES)) * 100.0,
        "r2": 1.0 - np.sum(residual**2) / np.sum((RATES - RATES.mean()) ** 2),
    }

    loo_errors = []
    for held_out in range(len(YEARS)):
        train = np.arange(len(YEARS)) != held_out
        loo_params, loo_func = fit_model(
            model, YEARS[train], RATES[train], carrying_capacity
        )
        prediction = float(loo_func(loo_params, YEARS[held_out]))
        loo_errors.append(RATES[held_out] - prediction)
    loo_errors = np.asarray(loo_errors)
    metrics["loo_rmse"] = np.sqrt(np.mean(loo_errors**2))
    metrics["loo_mape"] = np.mean(np.abs(loo_errors / RATES)) * 100.0
    return params, func, metrics


class Q1PipelineTest(unittest.TestCase):
    def test_source_manifest_covers_exactly_the_five_verified_points(self):
        manifest = pd.read_csv(Q1_DIR / "q1_source_manifest.csv")
        self.assertEqual(manifest["year"].tolist(), YEARS.astype(int).tolist())
        np.testing.assert_allclose(manifest["rate_percent"], RATES, atol=0.0)
        self.assertFalse(manifest["source_citation"].isna().any())
        self.assertTrue((manifest["verification_status"] == "verified").all())

    def test_matlab_model_results_match_independent_recalculation(self):
        results = pd.read_csv(OUTPUT_DIR / "q1_model_results.csv").set_index("model")
        for model in ("Logistic", "Gompertz"):
            params, _, metrics = expected_metrics(model)
            row = results.loc[model]
            self.assertAlmostEqual(row["K"], 100.0, places=10)
            np.testing.assert_allclose(
                [row["param1_value"], row["param2_value"]],
                params,
                rtol=0.0,
                atol=2e-5,
            )
            for metric, expected in metrics.items():
                self.assertAlmostEqual(row[metric], expected, places=4)

    def test_key_predictions_match_independent_recalculation(self):
        predictions = pd.read_csv(OUTPUT_DIR / "q1_predictions.csv")
        np.testing.assert_array_equal(predictions["year"], FUTURE_YEARS.astype(int))
        for model, column in (("Logistic", "logistic"), ("Gompertz", "gompertz")):
            params, func, _ = expected_metrics(model)
            expected = func(params, FUTURE_YEARS)
            np.testing.assert_allclose(predictions[column], expected, atol=2e-4)
        expected_lower = predictions[["logistic", "gompertz"]].min(axis=1)
        expected_upper = predictions[["logistic", "gompertz"]].max(axis=1)
        np.testing.assert_allclose(predictions["model_lower"], expected_lower)
        np.testing.assert_allclose(predictions["model_upper"], expected_upper)

    def test_sensitivity_refits_each_model_for_every_capacity(self):
        sensitivity = pd.read_csv(OUTPUT_DIR / "q1_sensitivity_results.csv")
        self.assertEqual(set(sensitivity["K"]), {75, 80, 85, 90, 95, 100})
        self.assertEqual(len(sensitivity), 12)
        for _, row in sensitivity.iterrows():
            params, func, _ = expected_metrics(row["model"], row["K"])
            np.testing.assert_allclose(
                [row["param1_value"], row["param2_value"]], params, atol=2e-5
            )
            self.assertAlmostEqual(
                row["prediction_2030"], float(func(params, 2030.0)), places=4
            )
            self.assertAlmostEqual(
                row["prediction_2050"], float(func(params, 2050.0)), places=4
            )

    def test_rolling_origin_validation_uses_only_earlier_observations(self):
        rolling = pd.read_csv(OUTPUT_DIR / "q1_rolling_validation.csv")
        self.assertEqual(len(rolling), 4)
        expected_rows = []
        for model in ("Logistic", "Gompertz"):
            for held_out in (3, 4):
                params, func = fit_model(
                    model, YEARS[:held_out], RATES[:held_out], 100.0
                )
                expected_rows.append(
                    (
                        model,
                        int(YEARS[held_out]),
                        float(func(params, YEARS[held_out])),
                    )
                )
        for model, year, expected_prediction in expected_rows:
            row = rolling[
                (rolling["model"] == model) & (rolling["target_year"] == year)
            ].iloc[0]
            self.assertEqual(row["training_end_year"], YEARS[list(YEARS).index(year) - 1])
            self.assertAlmostEqual(row["predicted"], expected_prediction, places=4)

    def test_all_matlab_self_checks_pass(self):
        checks = pd.read_csv(OUTPUT_DIR / "q1_model_checks.csv")
        self.assertGreaterEqual(len(checks), 8)
        self.assertTrue((checks["status"] == "PASS").all(), checks.to_string())


if __name__ == "__main__":
    unittest.main()

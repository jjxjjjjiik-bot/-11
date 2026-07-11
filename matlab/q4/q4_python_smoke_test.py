"""Independent numerical verification for the question-four MATLAB package."""

from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import least_squares


ROOT = Path(__file__).resolve().parents[2]
Q4 = ROOT / "matlab" / "q4"
OUTPUT = Q4 / "output"
DATA = ROOT / "数据来源" / "q4"
FIGURES = ROOT / "figures" / "q4"


def triangular_inverse(u, lower, mode, upper):
    split = (mode - lower) / (upper - lower)
    result = np.empty_like(u)
    left = u <= split
    result[left] = lower + np.sqrt(u[left] * (upper - lower) * (mode - lower))
    result[~left] = upper - np.sqrt(
        (1 - u[~left]) * (upper - lower) * (upper - mode)
    )
    return result


def fit_grid(years):
    observed_years = np.array([1992, 2002, 2012, 2020, 2023], dtype=float)
    observed_rates = np.array([20.0, 29.9, 42.0, 50.7, 57.0], dtype=float)
    rows = []
    for K in range(75, 101, 5):
        def logistic_residual(params):
            r, t0 = params
            return K / (1 + np.exp(-r * (observed_years - t0))) - observed_rates

        logistic = least_squares(
            logistic_residual,
            x0=[0.05, 2018],
            bounds=([0.001, 1950], [0.5, 2100]),
            xtol=1e-14,
            ftol=1e-14,
            gtol=1e-14,
            max_nfev=10000,
        ).x
        rates = K / (1 + np.exp(-logistic[0] * (years - logistic[1])))
        rows.extend(("Logistic", K, int(year), rate) for year, rate in zip(years, rates))

        def gompertz_residual(params):
            a, b = params
            return K * np.exp(-a * np.exp(-b * (observed_years - 1992))) - observed_rates

        gompertz = least_squares(
            gompertz_residual,
            x0=[1.5, 0.03],
            bounds=([0.001, 0.001], [10, 0.5]),
            xtol=1e-14,
            ftol=1e-14,
            gtol=1e-14,
            max_nfev=10000,
        ).x
        rates = K * np.exp(-gompertz[0] * np.exp(-gompertz[1] * (years - 1992)))
        rows.extend(("Gompertz", K, int(year), rate) for year, rate in zip(years, rates))
    return pd.DataFrame(rows, columns=["model", "K", "year", "rate_percent"])


def main():
    population = pd.read_csv(DATA / "q4_population_projection.csv")
    params = pd.read_csv(DATA / "q4_scenario_parameters.csv")
    matlab_grid = pd.read_csv(OUTPUT / "q4_baseline_grid.csv")
    matlab_baseline = pd.read_csv(OUTPUT / "q4_baseline_burden.csv")
    matlab_scenarios = pd.read_csv(OUTPUT / "q4_scenario_results.csv")
    matlab_summary = pd.read_csv(OUTPUT / "q4_uncertainty_summary.csv")
    mc = pd.read_csv(OUTPUT / "q4_mc_inputs.csv")

    assert population["year"].tolist() == list(range(2024, 2051))
    anchors = population.set_index("year")["population_18plus_persons"]
    assert abs(anchors.loc[2024] - 1_141_115_304) <= 1
    assert abs(anchors.loc[2030] - 1_173_939_515) <= 1
    assert abs(anchors.loc[2050] - 1_110_232_041) <= 1

    years = population["year"].to_numpy(dtype=float)
    python_grid = fit_grid(years)
    comparison = matlab_grid.merge(
        python_grid, on=["model", "K", "year"], suffixes=("_matlab", "_python")
    )
    grid_error = np.max(
        np.abs(comparison["rate_percent_matlab"] - comparison["rate_percent_python"])
    )
    assert grid_error <= 2e-4, grid_error

    primary_rate = matlab_baseline["primary_rate_percent"].to_numpy()
    primary_burden = (
        population["population_18plus_persons"].to_numpy() * primary_rate / 100
    )
    scenario_error = 0.0
    for scenario in ("low", "medium", "high"):
        group = params[params["scenario"] == scenario].set_index("parameter")
        reduction = (
            np.clip((years - 2024) / 6, 0, 1)
            * group.loc["coverage", "mode"]
            * group.loc["adherence", "mode"]
            * group.loc["effect", "mode"]
        )
        expected_avoided = primary_burden * reduction
        actual = matlab_scenarios[matlab_scenarios["scenario"] == scenario]
        scenario_error = max(
            scenario_error,
            np.max(np.abs(expected_avoided - actual["avoidable_burden_persons"])),
        )
    assert scenario_error <= 1.0, scenario_error

    K_values = np.arange(75, 101, 5)
    joint_rates = np.empty((len(mc), len(years)))
    model_code = mc["model_code"].to_numpy()
    K_draw = mc["K"].to_numpy()
    for j, year in enumerate(years.astype(int)):
        logistic = matlab_grid[
            (matlab_grid["model"] == "Logistic") & (matlab_grid["year"] == year)
        ].sort_values("K")
        gompertz = matlab_grid[
            (matlab_grid["model"] == "Gompertz") & (matlab_grid["year"] == year)
        ].sort_values("K")
        joint_rates[:, j] = np.where(
            model_code == 1,
            np.interp(K_draw, K_values, logistic["rate_percent"]),
            np.interp(K_draw, K_values, gompertz["rate_percent"]),
        )

    u_columns = {
        "coverage": mc["u_coverage"].to_numpy(),
        "adherence": mc["u_adherence"].to_numpy(),
        "effect": mc["u_effect"].to_numpy(),
    }
    max_quantile_error = 0.0
    for scope in ("policy_only_primary", "joint_structure_policy"):
        rates = (
            np.broadcast_to(primary_rate, joint_rates.shape)
            if scope == "policy_only_primary"
            else joint_rates
        )
        b0 = rates / 100 * population["population_18plus_persons"].to_numpy()
        for scenario in ("low", "medium", "high"):
            group = params[params["scenario"] == scenario].set_index("parameter")
            draws = {
                name: triangular_inverse(
                    u_columns[name],
                    group.loc[name, "lower"],
                    group.loc[name, "mode"],
                    group.loc[name, "upper"],
                )
                for name in u_columns
            }
            for j, year in enumerate(years.astype(int)):
                ramp = np.clip((year - 2024) / 6, 0, 1)
                avoided = b0[:, j] * ramp * draws["coverage"] * draws["adherence"] * draws["effect"]
                scenario_burden = b0[:, j] - avoided
                expected = np.concatenate(
                    [
                        np.percentile(b0[:, j], [5, 50, 95]),
                        np.percentile(scenario_burden, [5, 50, 95]),
                        np.percentile(avoided, [5, 50, 95]),
                    ]
                )
                actual = matlab_summary[
                    (matlab_summary["scope"] == scope)
                    & (matlab_summary["scenario"] == scenario)
                    & (matlab_summary["year"] == year)
                ]
                columns = [
                    "baseline_p05", "baseline_p50", "baseline_p95",
                    "scenario_p05", "scenario_p50", "scenario_p95",
                    "avoidable_p05", "avoidable_p50", "avoidable_p95",
                ]
                max_quantile_error = max(
                    max_quantile_error,
                    np.max(np.abs(expected - actual.iloc[0][columns].to_numpy(dtype=float))),
                )
    assert max_quantile_error <= 20_000, max_quantile_error

    checks = pd.read_csv(OUTPUT / "q4_model_checks.csv")
    assert (checks["status"] == "PASS").all()
    for path in FIGURES.glob("*.png"):
        assert path.stat().st_size > 20_000
    assert len(list(FIGURES.glob("*.png"))) == 4

    print("Q4 independent verification: PASS")
    print(f"Baseline grid max error: {grid_error:.9g} percentage points")
    print(f"Point-scenario max error: {scenario_error:.6f} persons")
    print(f"Monte Carlo quantile max error: {max_quantile_error:.6f} persons")
    print("Population years: 27; baseline grid rows: 324; uncertainty rows: 162")


if __name__ == "__main__":
    main()


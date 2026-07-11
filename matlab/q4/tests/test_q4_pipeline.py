import csv
import math
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / "数据来源" / "q4"
Q4 = ROOT / "matlab" / "q4"
OUTPUT = Q4 / "output"
FIGURES = ROOT / "figures" / "q4"


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


class Q4PipelineTests(unittest.TestCase):
    def test_input_files_exist(self):
        required = [
            DATA / "q4_population_projection.csv",
            DATA / "q4_scenario_parameters.csv",
            DATA / "q4_source_manifest.csv",
            DATA / "q4_evidence_notes.md",
        ]
        self.assertEqual([], [str(path) for path in required if not path.is_file()])

    def test_population_projection_is_complete_and_consistent(self):
        rows = read_csv(DATA / "q4_population_projection.csv")
        years = [int(row["year"]) for row in rows]
        self.assertEqual(list(range(2024, 2051)), years)
        for row in rows:
            population = float(row["population_18plus_persons"])
            total = float(row["total_population_persons"])
            self.assertGreater(population, 0)
            self.assertLessEqual(population, total)
            self.assertEqual("sum_single_ages_18plus", row["adult_estimation_method"])
        lookup = {int(row["year"]): float(row["population_18plus_persons"]) for row in rows}
        self.assertAlmostEqual(1_141_115_304, lookup[2024], delta=1.0)
        self.assertAlmostEqual(1_173_939_515, lookup[2030], delta=1.0)
        self.assertAlmostEqual(1_110_232_041, lookup[2050], delta=1.0)

    def test_scenario_parameters_are_ordered_probabilities(self):
        rows = read_csv(DATA / "q4_scenario_parameters.csv")
        self.assertEqual(9, len(rows))
        by_parameter = {}
        for row in rows:
            values = [float(row[key]) for key in ("lower", "mode", "upper")]
            self.assertTrue(0 <= values[0] <= values[1] <= values[2] <= 1)
            self.assertEqual("scenario_assumption", row["parameter_type"])
            by_parameter.setdefault(row["parameter"], []).append(float(row["mode"]))
        self.assertEqual({"coverage", "adherence", "effect"}, set(by_parameter))
        for values in by_parameter.values():
            self.assertEqual(sorted(values), values)

    def test_baseline_grid_has_q1_anchors(self):
        rows = read_csv(OUTPUT / "q4_baseline_grid.csv")
        self.assertEqual(2 * 6 * 27, len(rows))
        lookup = {
            (row["model"], int(float(row["K"])), int(row["year"])): float(row["rate_percent"])
            for row in rows
        }
        self.assertAlmostEqual(64.7076528512985, lookup[("Logistic", 100, 2030)], places=6)
        self.assertAlmostEqual(83.9216798604218, lookup[("Logistic", 100, 2050)], places=6)
        self.assertAlmostEqual(62.4224469407754, lookup[("Gompertz", 100, 2030)], places=6)
        self.assertAlmostEqual(78.3855422400629, lookup[("Gompertz", 100, 2050)], places=6)

    def test_baseline_burden_is_physical(self):
        rows = read_csv(OUTPUT / "q4_baseline_burden.csv")
        self.assertEqual(27, len(rows))
        for row in rows:
            population = float(row["population_18plus_persons"])
            rate = float(row["primary_rate_percent"])
            burden = float(row["primary_burden_persons"])
            self.assertTrue(0 < rate < 100)
            self.assertAlmostEqual(population * rate / 100, burden, delta=1.0)
            self.assertLessEqual(float(row["structure_lower_burden_persons"]), burden)
            self.assertLessEqual(burden, float(row["structure_upper_burden_persons"]))

    def test_point_scenarios_satisfy_identities_and_order(self):
        rows = read_csv(OUTPUT / "q4_scenario_results.csv")
        self.assertEqual(3 * 27, len(rows))
        order = {"low": 0, "medium": 1, "high": 2}
        grouped = {}
        for row in rows:
            baseline = float(row["baseline_burden_persons"])
            scenario = float(row["scenario_burden_persons"])
            avoided = float(row["avoidable_burden_persons"])
            self.assertAlmostEqual(baseline - scenario, avoided, delta=1.0)
            self.assertTrue(0 <= avoided <= baseline)
            grouped.setdefault(int(row["year"]), []).append(row)
        for year, year_rows in grouped.items():
            year_rows.sort(key=lambda row: order[row["scenario"]])
            avoided = [float(row["avoidable_burden_persons"]) for row in year_rows]
            scenario = [float(row["scenario_burden_persons"]) for row in year_rows]
            if year == 2024:
                self.assertTrue(all(abs(value) <= 1.0 for value in avoided))
            self.assertEqual(sorted(avoided), avoided)
            self.assertEqual(sorted(scenario, reverse=True), scenario)

    def test_uncertainty_intervals_are_ordered(self):
        rows = read_csv(OUTPUT / "q4_uncertainty_summary.csv")
        self.assertEqual(2 * 3 * 27, len(rows))
        for row in rows:
            for prefix in ("baseline", "scenario", "avoidable"):
                values = [float(row[f"{prefix}_{q}"]) for q in ("p05", "p50", "p95")]
                self.assertTrue(all(math.isfinite(value) for value in values))
                self.assertTrue(values[0] <= values[1] <= values[2])
            self.assertGreaterEqual(float(row["avoidable_p05"]), -1.0)

    def test_sensitivity_contains_five_inputs_per_target(self):
        rows = read_csv(OUTPUT / "q4_sensitivity_ranking.csv")
        expected = {"model_code", "K", "coverage", "adherence", "effect"}
        groups = {}
        for row in rows:
            key = (row["scenario"], int(row["year"]), row["outcome"])
            groups.setdefault(key, set()).add(row["parameter"])
            rho = float(row["spearman_rho"])
            self.assertTrue(math.isfinite(rho))
            self.assertLessEqual(abs(rho), 1.0 + 1e-12)
        self.assertTrue(groups)
        self.assertTrue(all(parameters == expected for parameters in groups.values()))

    def test_model_checks_all_pass(self):
        rows = read_csv(OUTPUT / "q4_model_checks.csv")
        self.assertGreaterEqual(len(rows), 15)
        failed = [row for row in rows if row["status"] != "PASS"]
        self.assertEqual([], failed)

    def test_supporting_outputs_and_figures_exist(self):
        required_outputs = [OUTPUT / "q4_results.mat", OUTPUT / "q4_run_log.txt"]
        required_figures = [
            FIGURES / "DPSIR危险机会传导框架.png",
            FIGURES / "成人超重肥胖基准负担.png",
            FIGURES / "不同干预情景负担比较.png",
            FIGURES / "不确定性与参数敏感性.png",
        ]
        missing = [str(path) for path in required_outputs + required_figures if not path.is_file()]
        self.assertEqual([], missing)
        for path in required_figures:
            self.assertGreater(path.stat().st_size, 20_000)


if __name__ == "__main__":
    unittest.main(verbosity=2)

import csv
import math
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import verify_q2_python as q2


class TestQ2CoreFunctions(unittest.TestCase):
    def test_rank_with_ties_uses_competition_ranking(self):
        self.assertEqual(q2.rank_with_ties([0.9, 0.8, 0.8, 0.7]), [1, 2, 2, 4])

    def test_critic_weights_match_verified_baseline(self):
        matrix = q2.baseline_matrix()
        weights = q2.critic_weights(matrix)
        expected = [0.23819447, 0.41956168, 0.34224385]
        self.assertAlmostEqual(sum(weights), 1.0, places=12)
        for actual, target in zip(weights, expected):
            self.assertAlmostEqual(actual, target, places=8)

    def test_topsis_scores_are_bounded_and_complete(self):
        matrix = q2.baseline_matrix()
        weights = q2.critic_weights(matrix)
        scores = q2.topsis_scores(matrix, weights)
        self.assertEqual(len(scores), 15)
        self.assertTrue(all(0.0 <= value <= 1.0 for value in scores))

    def test_wilson_lower_bound(self):
        actual = q2.wilson_lower_bound(7, 8)
        self.assertAlmostEqual(actual, 0.52911182, places=8)


class TestQ2DataContract(unittest.TestCase):
    def test_factor_csv_has_15_traceable_unique_rows(self):
        rows = q2.load_factor_rows(ROOT / "q2_factor_evidence.csv")
        self.assertEqual(len(rows), 15)
        self.assertEqual(len({row["factor_id"] for row in rows}), 15)
        required = {
            "factor_id",
            "factor_cn",
            "factor_en",
            "category",
            "n_studies",
            "positive_pct",
            "null_pct",
            "negative_pct",
            "measurement_count",
            "support_count",
            "consistency",
            "evidence_level",
            "evidence_code",
            "source_table",
            "original_row_name",
            "notes",
        }
        self.assertTrue(required.issubset(rows[0].keys()))
        for row in rows:
            self.assertTrue(all(row[key] != "" for key in required))
            self.assertAlmostEqual(
                float(row["consistency"]),
                int(row["support_count"]) / int(row["measurement_count"]),
                places=12,
            )

    def test_m4_separates_studies_from_directional_measurements(self):
        rows = q2.load_factor_rows(ROOT / "q2_factor_evidence.csv")
        m4 = next(row for row in rows if row["factor_id"] == "M4")
        self.assertEqual(int(m4["n_studies"]), 7)
        self.assertEqual(int(m4["measurement_count"]), 8)
        self.assertEqual(int(m4["support_count"]), 7)
        self.assertAlmostEqual(float(m4["consistency"]), 0.875, places=12)

    def test_all_sensitivity_scenarios_meet_declared_acceptance_if_data_supports_it(self):
        results = q2.calculate_all()
        self.assertEqual(len(results["sensitivity"]), 6)
        for scenario in results["sensitivity"]:
            self.assertEqual(scenario["top5_overlap"], 5)
            self.assertGreaterEqual(scenario["spearman_rho"], 0.8)


class TestMatlabDeliveryContract(unittest.TestCase):
    def test_required_matlab_files_exist(self):
        required = [
            "run_q2_all.m",
            "load_q2_data.m",
            "critic_weights.m",
            "topsis_rank.m",
            "rank_with_ties.m",
            "spearman_rank.m",
            "wilson_lower_bound.m",
            "sensitivity_analysis_q2.m",
            "plot_q2_mechanism.m",
            "plot_q2_ranking.m",
            "plot_q2_sensitivity.m",
            "self_check_q2.m",
        ]
        for filename in required:
            self.assertTrue((ROOT / filename).is_file(), filename)

    def test_matlab_entry_is_self_locating_and_uses_required_outputs(self):
        text = (ROOT / "run_q2_all.m").read_text(encoding="utf-8")
        self.assertIn("mfilename('fullpath')", text)
        self.assertNotIn("D:\\\\数学建模", text)
        for filename in [
            "q2_critic_weights.csv",
            "q2_topsis_ranking.csv",
            "q2_sensitivity_results.csv",
            "q2_model_checks.csv",
            "q2_results.mat",
            "q2_run_log.txt",
        ]:
            self.assertIn(filename, text)

    def test_matlab_plotting_is_r2018b_compatible(self):
        matlab_text = "\n".join(
            path.read_text(encoding="utf-8") for path in ROOT.glob("*.m")
        )
        self.assertNotIn("exportgraphics", matlab_text)
        self.assertNotIn("tiledlayout", matlab_text)
        self.assertIn("imagesc", matlab_text)

    def test_matlab_plots_open_editable_windows_without_image_exports(self):
        entry = (ROOT / "run_q2_all.m").read_text(encoding="utf-8")
        self.assertNotIn("figureDir", entry)
        for filename in [
            "plot_q2_mechanism.m",
            "plot_q2_ranking.m",
            "plot_q2_sensitivity.m",
        ]:
            plot_text = (ROOT / filename).read_text(encoding="utf-8")
            self.assertIn("'Visible', 'on'", plot_text)
            self.assertIn("drawnow;", plot_text)
            self.assertNotIn("savefig(", plot_text)
            self.assertNotIn("print(", plot_text)

    def test_matlab_plot_annotations_are_chinese_first(self):
        ranking = (ROOT / "plot_q2_ranking.m").read_text(encoding="utf-8")
        sensitivity = (ROOT / "sensitivity_analysis_q2.m").read_text(
            encoding="utf-8"
        )
        self.assertIn("TOPSIS贴近度（逼近理想解得分）", ranking)
        self.assertIn("CRITIC客观赋权", ranking)
        self.assertIn("威尔逊（Wilson）", sensitivity)
        self.assertIn("拉普拉斯（Laplace）", sensitivity)

    def test_matlab_plots_require_a_chinese_capable_font(self):
        helper = ROOT / "choose_q2_chinese_font.m"
        self.assertTrue(helper.is_file())
        helper_text = helper.read_text(encoding="utf-8")
        self.assertIn("Microsoft YaHei UI", helper_text)
        self.assertIn("Noto Sans CJK SC", helper_text)
        self.assertIn("PingFang SC", helper_text)
        self.assertNotIn("fontName = 'Arial'", helper_text)
        for filename in [
            "plot_q2_mechanism.m",
            "plot_q2_ranking.m",
            "plot_q2_sensitivity.m",
        ]:
            plot_text = (ROOT / filename).read_text(encoding="utf-8")
            self.assertIn("choose_q2_chinese_font()", plot_text)


if __name__ == "__main__":
    unittest.main()

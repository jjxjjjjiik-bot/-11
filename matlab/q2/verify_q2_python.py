"""Independent Python verification for the Q2 CRITIC-TOPSIS pipeline."""

from __future__ import annotations

import csv
import math
from datetime import datetime
from pathlib import Path

import numpy as np
from scipy.io import savemat


ROOT = Path(__file__).resolve().parent
OUTPUT_DIR = ROOT / "output"
FACTOR_FILE = ROOT / "q2_factor_evidence.csv"
TOL = 1e-12


def load_factor_rows(path=FACTOR_FILE):
    with Path(path).open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _numeric_factor_id(factor_id):
    return int(str(factor_id).lstrip("Mm"))


def baseline_matrix(path=FACTOR_FILE):
    rows = load_factor_rows(path)
    return np.array(
        [
            [
                float(row["n_studies"]),
                float(row["consistency"]),
                float(row["evidence_code"]),
            ]
            for row in rows
        ],
        dtype=float,
    )


def critic_weights(matrix):
    matrix = np.asarray(matrix, dtype=float)
    spans = np.ptp(matrix, axis=0)
    if np.any(spans <= TOL):
        raise ValueError("CRITIC requires non-constant criteria.")
    normalized = (matrix - np.min(matrix, axis=0)) / spans
    sigma = np.std(normalized, axis=0, ddof=0)
    correlation = np.corrcoef(normalized, rowvar=False)
    information = sigma * np.sum(1.0 - correlation, axis=1)
    total = float(np.sum(information))
    if total <= TOL:
        raise ValueError("CRITIC information content is zero.")
    return information / total


def topsis_scores(matrix, weights):
    matrix = np.asarray(matrix, dtype=float)
    weights = np.asarray(weights, dtype=float)
    denominators = np.sqrt(np.sum(matrix * matrix, axis=0))
    if np.any(denominators <= TOL):
        raise ValueError("TOPSIS vector normalization encountered a zero column.")
    weighted = matrix / denominators * weights
    positive = np.max(weighted, axis=0)
    negative = np.min(weighted, axis=0)
    distance_positive = np.sqrt(np.sum((weighted - positive) ** 2, axis=1))
    distance_negative = np.sqrt(np.sum((weighted - negative) ** 2, axis=1))
    total_distance = distance_positive + distance_negative
    return np.divide(
        distance_negative,
        total_distance,
        out=np.zeros_like(distance_negative),
        where=total_distance > TOL,
    )


def rank_with_ties(scores):
    scores = [float(value) for value in scores]
    order = sorted(range(len(scores)), key=lambda index: (-scores[index], index))
    ranks = [0] * len(scores)
    previous = None
    current_rank = 0
    for position, index in enumerate(order, start=1):
        if previous is None or abs(scores[index] - previous) > TOL:
            current_rank = position
        ranks[index] = current_rank
        previous = scores[index]
    return ranks


def _average_tie_ranks(values):
    values = [float(value) for value in values]
    order = sorted(range(len(values)), key=lambda index: (-values[index], index))
    ranks = [0.0] * len(values)
    start = 0
    while start < len(order):
        stop = start + 1
        while stop < len(order) and abs(
            values[order[stop]] - values[order[start]]
        ) <= TOL:
            stop += 1
        average_rank = ((start + 1) + stop) / 2.0
        for position in range(start, stop):
            ranks[order[position]] = average_rank
        start = stop
    return np.asarray(ranks, dtype=float)


def spearman_rank(values_a, values_b):
    rank_a = _average_tie_ranks(values_a)
    rank_b = _average_tie_ranks(values_b)
    if np.std(rank_a) <= TOL or np.std(rank_b) <= TOL:
        return 0.0
    return float(np.corrcoef(rank_a, rank_b)[0, 1])


def wilson_lower_bound(successes, total, z=1.959963984540054):
    successes = float(successes)
    total = float(total)
    if total <= 0:
        raise ValueError("Wilson interval requires total > 0.")
    proportion = successes / total
    denominator = 1.0 + z * z / total
    center = proportion + z * z / (2.0 * total)
    adjustment = z * math.sqrt(
        proportion * (1.0 - proportion) / total + z * z / (4.0 * total * total)
    )
    return (center - adjustment) / denominator


def _scenario_definitions(rows):
    studies = np.array([float(row["n_studies"]) for row in rows], dtype=float)
    consistency = np.array([float(row["consistency"]) for row in rows], dtype=float)
    evidence = np.array([float(row["evidence_code"]) for row in rows], dtype=float)
    support = np.array([float(row["support_count"]) for row in rows], dtype=float)
    measurements = np.array(
        [float(row["measurement_count"]) for row in rows], dtype=float
    )
    wilson = np.array(
        [wilson_lower_bound(s, n) for s, n in zip(support, measurements)],
        dtype=float,
    )
    laplace = (support + 1.0) / (measurements + 2.0)
    return [
        {
            "scenario_id": "S1",
            "scenario_cn": "原始一致率+CRITIC权重",
            "matrix": np.column_stack([studies, consistency, evidence]),
            "weights": None,
        },
        {
            "scenario_id": "S2",
            "scenario_cn": "威尔逊（Wilson）95%下限一致率",
            "matrix": np.column_stack([studies, wilson, evidence]),
            "weights": None,
        },
        {
            "scenario_id": "S3",
            "scenario_cn": "拉普拉斯（Laplace）修正一致率",
            "matrix": np.column_stack([studies, laplace, evidence]),
            "weights": None,
        },
        {
            "scenario_id": "S4",
            "scenario_cn": "研究数量使用对数变换log(1+n)",
            "matrix": np.column_stack([np.log1p(studies), consistency, evidence]),
            "weights": None,
        },
        {
            "scenario_id": "S5",
            "scenario_cn": "TOPSIS等权重",
            "matrix": np.column_stack([studies, consistency, evidence]),
            "weights": np.array([1.0 / 3.0] * 3, dtype=float),
        },
        {
            "scenario_id": "S6",
            "scenario_cn": "删除证据等级",
            "matrix": np.column_stack([studies, consistency]),
            "weights": None,
        },
    ]


def _top_five_factor_ids(rows, scores):
    order = sorted(
        range(len(rows)),
        key=lambda index: (
            -float(scores[index]),
            -int(rows[index]["n_studies"]),
            _numeric_factor_id(rows[index]["factor_id"]),
        ),
    )
    return {rows[index]["factor_id"] for index in order[:5]}


def calculate_all(path=FACTOR_FILE):
    rows = load_factor_rows(path)
    scenarios = _scenario_definitions(rows)
    calculated = []
    for scenario in scenarios:
        weights = (
            critic_weights(scenario["matrix"])
            if scenario["weights"] is None
            else scenario["weights"]
        )
        scores = topsis_scores(scenario["matrix"], weights)
        ranks = rank_with_ties(scores)
        calculated.append(
            {
                **scenario,
                "weights": weights,
                "scores": scores,
                "ranks": ranks,
            }
        )

    baseline = calculated[0]
    baseline_top_five = _top_five_factor_ids(rows, baseline["scores"])
    for scenario in calculated:
        scenario_top_five = _top_five_factor_ids(rows, scenario["scores"])
        scenario["spearman_rho"] = spearman_rank(
            baseline["scores"], scenario["scores"]
        )
        scenario["top5_overlap"] = len(baseline_top_five & scenario_top_five)
        scenario["max_rank_change"] = max(
            abs(int(a) - int(b))
            for a, b in zip(baseline["ranks"], scenario["ranks"])
        )
    return {"rows": rows, "baseline": baseline, "sensitivity": calculated}


def _write_csv(path, fieldnames, rows):
    with Path(path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_outputs(results=None):
    results = calculate_all() if results is None else results
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = results["rows"]
    baseline = results["baseline"]

    weight_rows = [
        {
            "criterion_id": criterion_id,
            "criterion_cn": criterion_cn,
            "weight": f"{weight:.12f}",
        }
        for criterion_id, criterion_cn, weight in zip(
            ["C1", "C2", "C3"],
            ["研究数量", "方向一致率", "证据等级"],
            baseline["weights"],
        )
    ]
    _write_csv(
        OUTPUT_DIR / "q2_critic_weights.csv",
        ["criterion_id", "criterion_cn", "weight"],
        weight_rows,
    )

    ranking_rows = []
    for row, score, rank in zip(rows, baseline["scores"], baseline["ranks"]):
        ranking_rows.append(
            {
                "factor_id": row["factor_id"],
                "factor_cn": row["factor_cn"],
                "category": row["category"],
                "n_studies": row["n_studies"],
                "consistency": row["consistency"],
                "evidence_code": row["evidence_code"],
                "topsis_score": f"{float(score):.12f}",
                "rank": int(rank),
            }
        )
    ranking_rows.sort(
        key=lambda row: (
            int(row["rank"]),
            -int(row["n_studies"]),
            _numeric_factor_id(row["factor_id"]),
        )
    )
    _write_csv(
        OUTPUT_DIR / "q2_topsis_ranking.csv",
        [
            "factor_id",
            "factor_cn",
            "category",
            "n_studies",
            "consistency",
            "evidence_code",
            "topsis_score",
            "rank",
        ],
        ranking_rows,
    )

    sensitivity_rows = []
    for scenario in results["sensitivity"]:
        padded_weights = list(scenario["weights"]) + [math.nan] * (
            3 - len(scenario["weights"])
        )
        for row, score, rank in zip(rows, scenario["scores"], scenario["ranks"]):
            sensitivity_rows.append(
                {
                    "scenario_id": scenario["scenario_id"],
                    "scenario_cn": scenario["scenario_cn"],
                    "factor_id": row["factor_id"],
                    "topsis_score": f"{float(score):.12f}",
                    "rank": int(rank),
                    "weight_studies": f"{padded_weights[0]:.12f}",
                    "weight_consistency": f"{padded_weights[1]:.12f}",
                    "weight_evidence": (
                        "" if math.isnan(padded_weights[2]) else f"{padded_weights[2]:.12f}"
                    ),
                    "spearman_rho": f"{scenario['spearman_rho']:.12f}",
                    "top5_overlap": scenario["top5_overlap"],
                    "max_rank_change": scenario["max_rank_change"],
                }
            )
    _write_csv(
        OUTPUT_DIR / "q2_sensitivity_results.csv",
        [
            "scenario_id",
            "scenario_cn",
            "factor_id",
            "topsis_score",
            "rank",
            "weight_studies",
            "weight_consistency",
            "weight_evidence",
            "spearman_rho",
            "top5_overlap",
            "max_rank_change",
        ],
        sensitivity_rows,
    )

    checks = [
        ("factor_count", len(rows) == 15, len(rows), "15"),
        (
            "factor_ids_unique",
            len({row["factor_id"] for row in rows}) == 15,
            len({row["factor_id"] for row in rows}),
            "15",
        ),
        (
            "no_missing_factor_fields",
            all(all(value != "" for value in row.values()) for row in rows),
            "complete",
            "complete",
        ),
        (
            "critic_weights_sum",
            abs(float(np.sum(baseline["weights"])) - 1.0) <= 1e-12,
            f"{float(np.sum(baseline['weights'])):.15f}",
            "1",
        ),
        (
            "topsis_score_range",
            bool(np.all((baseline["scores"] >= 0.0) & (baseline["scores"] <= 1.0))),
            f"{float(np.min(baseline['scores'])):.12f}..{float(np.max(baseline['scores'])):.12f}",
            "[0,1]",
        ),
        (
            "ranking_covers_all_factors",
            len(baseline["ranks"]) == 15,
            len(baseline["ranks"]),
            "15",
        ),
        (
            "tie_ranking_example",
            rank_with_ties([0.9, 0.8, 0.8, 0.7]) == [1, 2, 2, 4],
            str(rank_with_ties([0.9, 0.8, 0.8, 0.7])),
            "[1, 2, 2, 4]",
        ),
        (
            "all_scenarios_top5_overlap",
            all(item["top5_overlap"] == 5 for item in results["sensitivity"]),
            min(item["top5_overlap"] for item in results["sensitivity"]),
            "5",
        ),
        (
            "all_scenarios_spearman",
            all(item["spearman_rho"] >= 0.8 for item in results["sensitivity"]),
            f"{min(item['spearman_rho'] for item in results['sensitivity']):.12f}",
            ">=0.8",
        ),
    ]
    _write_csv(
        OUTPUT_DIR / "q2_model_checks.csv",
        ["check_name", "status", "value", "expected", "notes"],
        [
            {
                "check_name": name,
                "status": "PASS" if passed else "FAIL",
                "value": value,
                "expected": expected,
                "notes": "Python independent verification",
            }
            for name, passed, value, expected in checks
        ],
    )

    score_matrix = np.column_stack(
        [scenario["scores"] for scenario in results["sensitivity"]]
    )
    rank_matrix = np.column_stack(
        [scenario["ranks"] for scenario in results["sensitivity"]]
    )
    savemat(
        OUTPUT_DIR / "q2_results.mat",
        {
            "factor_ids": np.array([row["factor_id"] for row in rows], dtype=object),
            "baseline_matrix": baseline["matrix"],
            "critic_weights": baseline["weights"],
            "baseline_scores": baseline["scores"],
            "baseline_ranks": np.asarray(baseline["ranks"], dtype=float),
            "sensitivity_scores": score_matrix,
            "sensitivity_ranks": rank_matrix,
            "scenario_ids": np.array(
                [item["scenario_id"] for item in results["sensitivity"]], dtype=object
            ),
        },
    )

    log_lines = [
        "Q2 Python independent verification",
        f"Timestamp: {datetime.now().isoformat(timespec='seconds')}",
        f"Factor rows: {len(rows)}",
        "Baseline CRITIC weights: "
        + ", ".join(f"{value:.12f}" for value in baseline["weights"]),
        "Minimum sensitivity Spearman rho: "
        + f"{min(item['spearman_rho'] for item in results['sensitivity']):.12f}",
        "All top-five overlaps: "
        + ", ".join(str(item["top5_overlap"]) for item in results["sensitivity"]),
        "MATLAB/Octave execution: NOT RUN on this machine",
        "PNG figures: NOT GENERATED by Python",
    ]
    (OUTPUT_DIR / "q2_run_log.txt").write_text(
        "\n".join(log_lines) + "\n", encoding="utf-8"
    )
    return checks


if __name__ == "__main__":
    write_outputs()
    print(f"Q2 verification outputs written to: {OUTPUT_DIR}")

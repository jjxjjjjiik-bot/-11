import csv
import math
from pathlib import Path


ROOT = Path(r"D:\数学建模")
SOURCE_DIR = ROOT / "数据来源" / "q3"
OUTPUT_DIR = ROOT / "matlab" / "q3" / "output"

CRITERIA = [
    "effect_score",
    "feasibility_score",
    "persistence_score",
    "failure_coverage_score",
    "profile_match_score",
    "time_burden_min_day",
]
CRITERIA_TYPES = [1, 1, 1, 1, 1, -1]
WEIGHT_PARAMETERS = ["P28", "P30", "P31", "P32", "P36", "P33"]
EXPECTED_WINNERS = {
    1: ("久坐办公型", "能量控制与饮食记录型", 0.832630058891358),
    2: ("夜班熬夜型", "夜间加餐能量管理型", 0.834119937420290),
    3: ("高压应酬型", "应酬饮食与饮酒管理型", 0.866603475925043),
    4: ("时间受限型", "碎片运动与周末备餐型", 0.666671469746901),
    5: ("饮食失衡型", "总能量记录与份量控制型", 0.842998265783786),
}


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def number(row, field):
    return float(row[field])


def assert_close(actual, expected, tolerance=1e-9, label="value"):
    if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=tolerance):
        raise AssertionError(f"{label}: expected {expected}, got {actual}")


def read_parameters():
    rows = read_csv(SOURCE_DIR / "q3_parameter_table.csv")
    return {
        row["parameter_id"]: float(row["value"])
        for row in rows
        if row["value"]
    }


def topsis(group, weights):
    matrix = [[number(row, field) for field in CRITERIA] for row in group]
    norm_factors = [
        math.sqrt(sum(matrix[i][j] ** 2 for i in range(len(matrix)))) or 1.0
        for j in range(len(CRITERIA))
    ]
    weighted = [
        [
            matrix[i][j] / norm_factors[j] * weights[j]
            for j in range(len(CRITERIA))
        ]
        for i in range(len(matrix))
    ]

    ideal_best = []
    ideal_worst = []
    for j, criterion_type in enumerate(CRITERIA_TYPES):
        column = [row[j] for row in weighted]
        ideal_best.append(max(column) if criterion_type == 1 else min(column))
        ideal_worst.append(min(column) if criterion_type == 1 else max(column))

    results = {}
    for plan, row in zip(group, weighted):
        distance_best = math.sqrt(
            sum((row[j] - ideal_best[j]) ** 2 for j in range(len(CRITERIA)))
        )
        distance_worst = math.sqrt(
            sum((row[j] - ideal_worst[j]) ** 2 for j in range(len(CRITERIA)))
        )
        denominator = distance_best + distance_worst
        score = distance_worst / denominator if denominator else 0.5
        results[plan["plan_id"]] = {
            "score": score,
            "distance_best": distance_best,
            "distance_worst": distance_worst,
        }
    return results


def competition_ranks(scores, tolerance=1e-9):
    ordered = sorted(scores.items(), key=lambda item: -item[1])
    ranks = {}
    previous_score = None
    previous_rank = None
    for position, (plan_id, score) in enumerate(ordered, start=1):
        if previous_score is not None and abs(score - previous_score) <= tolerance:
            rank = previous_rank
        else:
            rank = position
        ranks[plan_id] = rank
        previous_score = score
        previous_rank = rank
    return ranks


def perturb_weight(weights, target_index, multiplier):
    target_weight = weights[target_index] * multiplier
    other_indices = [i for i in range(len(weights)) if i != target_index]
    other_total = sum(weights[i] for i in other_indices)
    adjusted = [0.0] * len(weights)
    adjusted[target_index] = target_weight
    for index in other_indices:
        adjusted[index] = (
            weights[index] / other_total * (1.0 - target_weight)
        )
    assert_close(sum(adjusted), 1.0, 1e-12, "perturbed weight sum")
    return adjusted


def verify_profile_scores(profiles, plans):
    profile_map = {int(row["profile_id"]): row for row in profiles}
    time_values = [number(row, "time_burden_min_day") for row in plans]
    time_min = min(time_values)
    time_max = max(time_values)

    for plan in plans:
        profile = profile_map[int(plan["profile_id"])]
        time_burden = number(plan, "time_burden_min_day")
        time_adaptation = 100.0 * (time_max - time_burden) / (time_max - time_min)
        assert_close(
            number(plan, "time_adaptation_score"),
            time_adaptation,
            label=f"{plan['plan_id']} time adaptation",
        )

        coverage = [
            number(plan, "cover_activity"),
            number(plan, "cover_energy"),
            number(plan, "cover_monitoring"),
            number(plan, "cover_unhealthy_food"),
            number(plan, "cover_fruit_veg"),
        ]
        failure_coverage = sum(coverage) / len(coverage) * 100.0
        assert_close(
            number(plan, "failure_coverage_score"),
            failure_coverage,
            label=f"{plan['plan_id']} failure coverage",
        )

        diet_action = (
            number(plan, "cover_energy")
            + number(plan, "cover_unhealthy_food")
            + number(plan, "cover_fruit_veg")
        ) / 3.0
        numerator = (
            number(profile, "sedentary_risk") * number(plan, "cover_activity")
            + number(profile, "diet_risk") * diet_action
            + number(profile, "monitoring_gap") * number(plan, "cover_monitoring")
            + number(profile, "sleep_risk")
            * number(plan, "sleep_action_score")
            / 100.0
            + number(profile, "time_constraint") * time_adaptation / 100.0
        )
        denominator = (
            number(profile, "sedentary_risk")
            + number(profile, "diet_risk")
            + number(profile, "monitoring_gap")
            + number(profile, "sleep_risk")
            + number(profile, "time_constraint")
        )
        profile_match = 100.0 * numerator / denominator
        assert_close(
            number(plan, "profile_match_score"),
            profile_match,
            label=f"{plan['plan_id']} profile match",
        )


def verify_core_scores(profiles, plans, parameters):
    profile_map = {int(row["profile_id"]): row for row in profiles}
    period_days = round(parameters["P05"] * 30.0)
    target_min_kg = parameters["P03"] * parameters["P06"] / 100.0
    target_max_kg = parameters["P03"] * parameters["P07"] / 100.0

    for plan in plans:
        profile = profile_map[int(plan["profile_id"])]
        energy_deficit = number(plan, "energy_deficit_kcal_day")
        aerobic_minutes = number(plan, "aerobic_min_week")
        strength_days = number(plan, "strength_days_week")
        sleep_hours = number(plan, "sleep_hours_target")

        is_safe = (
            parameters["P08"] <= energy_deficit <= parameters["P09"]
            and parameters["P14"] <= aerobic_minutes <= parameters["P15"]
            and parameters["P16"] <= strength_days <= parameters["P17"]
            and sleep_hours >= parameters["P20"]
        )
        if int(float(plan["is_safe"])) != int(is_safe):
            raise AssertionError(f"{plan['plan_id']}: safety gate mismatch")

        diet_loss = energy_deficit * period_days / parameters["P27"]
        exercise_loss = (
            aerobic_minutes
            * 6.0
            * 4.345
            * parameters["P05"]
            / parameters["P27"]
        )
        raw_loss = 0.35 * diet_loss + 0.45 * exercise_loss
        expected_loss = min(
            max(raw_loss, target_min_kg * 0.70),
            target_max_kg,
        )
        effect_score = min(100.0, 100.0 * expected_loss / target_max_kg)
        assert_close(
            number(plan, "expected_loss_kg_6m"),
            expected_loss,
            label=f"{plan['plan_id']} expected loss",
        )
        assert_close(
            number(plan, "effect_score"),
            effect_score,
            label=f"{plan['plan_id']} effect score",
        )

        time_risk = number(profile, "time_constraint") / 100.0
        sleep_risk = number(profile, "sleep_risk") / 100.0
        stress_risk = number(profile, "stress_risk") / 100.0
        time_burden = number(plan, "time_burden_min_day")
        monitoring_days = number(plan, "monitoring_days_week")
        sleep_action = number(plan, "sleep_action_score")
        diet_structure = number(plan, "diet_structure_score")

        burden_penalty = max(0.0, time_burden - 30.0) * (
            0.20 + 0.35 * time_risk
        )
        sleep_fit = sleep_action / 100.0 * (5.0 + 5.0 * sleep_risk)
        monitoring_fit = monitoring_days / 7.0 * 8.0
        feasibility = (
            84.0
            - burden_penalty
            - 7.0 * stress_risk
            + sleep_fit
            + monitoring_fit
        )
        feasibility = max(0.0, min(100.0, feasibility))
        assert_close(
            number(plan, "feasibility_score"),
            feasibility,
            label=f"{plan['plan_id']} feasibility",
        )

        monitoring_score = monitoring_days / 7.0 * 100.0
        persistence = (
            48.0
            + 0.18 * monitoring_score
            + 0.18 * sleep_action
            + 0.14 * diet_structure
            - max(0.0, time_burden - 45.0) * 0.35
            - 8.0 * stress_risk
        )
        persistence = max(0.0, min(100.0, persistence))
        assert_close(
            number(plan, "persistence_score"),
            persistence,
            label=f"{plan['plan_id']} persistence",
        )


def verify_topsis(plans, weights):
    winners = {}
    for profile_id in range(1, 6):
        group = [row for row in plans if int(row["profile_id"]) == profile_id]
        if len(group) != 3:
            raise AssertionError(f"profile {profile_id}: expected 3 plans")
        calculated = topsis(group, weights)
        ranks = competition_ranks(
            {plan_id: detail["score"] for plan_id, detail in calculated.items()}
        )

        for plan in group:
            detail = calculated[plan["plan_id"]]
            assert_close(
                number(plan, "topsis_score"),
                detail["score"],
                label=f"{plan['plan_id']} TOPSIS score",
            )
            assert_close(
                number(plan, "distance_to_best"),
                detail["distance_best"],
                label=f"{plan['plan_id']} distance to best",
            )
            assert_close(
                number(plan, "distance_to_worst"),
                detail["distance_worst"],
                label=f"{plan['plan_id']} distance to worst",
            )
            if int(float(plan["rank"])) != ranks[plan["plan_id"]]:
                raise AssertionError(f"{plan['plan_id']}: rank mismatch")

        best = max(group, key=lambda row: calculated[row["plan_id"]]["score"])
        winners[profile_id] = (
            best["profile_name"],
            best["plan_type"],
            calculated[best["plan_id"]]["score"],
        )

    for profile_id, expected in EXPECTED_WINNERS.items():
        actual = winners[profile_id]
        if actual[:2] != expected[:2]:
            raise AssertionError(
                f"profile {profile_id}: expected {expected[:2]}, got {actual[:2]}"
            )
        assert_close(actual[2], expected[2], label=f"profile {profile_id} winner")
    return winners


def verify_sensitivity(plans, weights, sensitivity_rows, summary_rows):
    if len(sensitivity_rows) != 60:
        raise AssertionError(f"expected 60 sensitivity rows, got {len(sensitivity_rows)}")

    sensitivity_map = {
        (
            int(row["profile_id"]),
            row["perturbed_criterion"],
            float(row["weight_multiplier"]),
        ): row
        for row in sensitivity_rows
    }
    stable_counts = {profile_id: 0 for profile_id in range(1, 6)}

    for profile_id in range(1, 6):
        group = [row for row in plans if int(row["profile_id"]) == profile_id]
        baseline = topsis(group, weights)
        baseline_best = max(
            group, key=lambda row: baseline[row["plan_id"]]["score"]
        )["plan_type"]

        for criterion_index, criterion in enumerate(CRITERIA):
            for multiplier in (0.8, 1.2):
                adjusted = perturb_weight(weights, criterion_index, multiplier)
                calculated = topsis(group, adjusted)
                best_plan = max(
                    group, key=lambda row: calculated[row["plan_id"]]["score"]
                )["plan_type"]
                key = (profile_id, criterion, multiplier)
                archived = sensitivity_map.get(key)
                if archived is None:
                    raise AssertionError(f"missing sensitivity scenario {key}")
                if archived["baseline_best_plan"] != baseline_best:
                    raise AssertionError(f"{key}: baseline winner mismatch")
                if archived["perturbed_best_plan"] != best_plan:
                    raise AssertionError(f"{key}: perturbed winner mismatch")
                unchanged = int(float(archived["best_plan_unchanged"]))
                if unchanged != int(best_plan == baseline_best):
                    raise AssertionError(f"{key}: unchanged flag mismatch")
                stable_counts[profile_id] += unchanged

    summaries = {int(row["profile_id"]): row for row in summary_rows}
    expected_counts = {1: 12, 2: 12, 3: 12, 4: 8, 5: 12}
    for profile_id, expected_count in expected_counts.items():
        if stable_counts[profile_id] != expected_count:
            raise AssertionError(f"profile {profile_id}: stability count mismatch")
        row = summaries[profile_id]
        if int(float(row["scenario_count"])) != 12:
            raise AssertionError(f"profile {profile_id}: scenario count mismatch")
        if int(float(row["unchanged_count"])) != expected_count:
            raise AssertionError(f"profile {profile_id}: summary count mismatch")
        assert_close(
            number(row, "stability_rate"),
            expected_count / 12.0,
            label=f"profile {profile_id} stability rate",
        )


def main():
    parameters = read_parameters()
    weights = [parameters[key] for key in WEIGHT_PARAMETERS]
    assert_close(sum(weights), 1.0, 1e-12, "baseline weight sum")

    profiles = read_csv(OUTPUT_DIR / "q3_profile_scores.csv")
    plans = read_csv(OUTPUT_DIR / "q3_plan_scores.csv")
    sensitivity_rows = read_csv(OUTPUT_DIR / "q3_weight_sensitivity.csv")
    summary_rows = read_csv(OUTPUT_DIR / "q3_weight_sensitivity_summary.csv")
    model_checks = read_csv(OUTPUT_DIR / "q3_model_checks.csv")

    if len(profiles) != 5 or len(plans) != 15:
        raise AssertionError("expected 5 profiles and 15 plans")
    if any("综合平衡型" in row["plan_type"] for row in plans):
        raise AssertionError("deprecated 综合平衡型 is present")
    if any(int(float(row["is_safe"])) != 1 for row in plans):
        raise AssertionError("not all plans pass the safety gate")
    if any(row["status"] != "PASS" for row in model_checks):
        raise AssertionError("q3_model_checks.csv contains a failed check")

    verify_core_scores(profiles, plans, parameters)
    verify_profile_scores(profiles, plans)
    winners = verify_topsis(plans, weights)
    verify_sensitivity(plans, weights, sensitivity_rows, summary_rows)

    print(
        "Python smoke test OK: "
        f"profiles={len(profiles)}, plans={len(plans)}, "
        f"sensitivity={len(sensitivity_rows)}, full_formulas=1"
    )
    for profile_id in range(1, 6):
        profile_name, plan_name, score = winners[profile_id]
        print(f"{profile_name}: {plan_name} score={score:.6f}")


if __name__ == "__main__":
    main()

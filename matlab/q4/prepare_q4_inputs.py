"""Extract exact China 18+ population totals from the archived UN WPP CSV."""

import csv
import gzip
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = (
    ROOT
    / "数据来源"
    / "q4"
    / "WPP2024_PopulationBySingleAgeSex_Medium_2024-2100.csv.gz"
)
OUTPUT = ROOT / "数据来源" / "q4" / "q4_population_projection.csv"


def extract_population_rows(source=SOURCE):
    totals = {year: {"all": 0.0, "adult": 0.0} for year in range(2024, 2051)}
    location = None
    with gzip.open(source, "rt", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for record in reader:
            if record["ISO3_code"] != "CHN":
                continue
            year = int(record["Time"])
            if year not in totals:
                continue
            location = record["Location"]
            population = float(record["PopTotal"]) * 1000.0
            totals[year]["all"] += population
            if float(record["AgeGrpStart"]) >= 18:
                totals[year]["adult"] += population

    extracted = []
    for year, values in totals.items():
        total = values["all"]
        population_18plus = values["adult"]
        extracted.append(
            {
                "year": year,
                "location": location,
                "location_code": 156,
                "iso3": "CHN",
                "variant": "Medium",
                "total_population_persons": total,
                "population_under18_persons": total - population_18plus,
                "population_18plus_persons": population_18plus,
                "adult_share_percent": 100.0 * population_18plus / total,
                "source_unit": "thousand_persons",
                "adult_estimation_method": "sum_single_ages_18plus",
            }
        )

    years = [row["year"] for row in extracted]
    if years != list(range(2024, 2051)):
        raise ValueError(f"Expected 2024-2050, got {years}")
    if any(row["population_18plus_persons"] <= 0 for row in extracted):
        raise ValueError("No adult population rows were extracted")
    return extracted


def write_population_csv(rows, output=OUTPUT):
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    population_rows = extract_population_rows()
    write_population_csv(population_rows)
    print(f"Wrote {len(population_rows)} rows to {OUTPUT}")

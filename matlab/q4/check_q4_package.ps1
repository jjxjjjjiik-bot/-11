$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $PSScriptRoot 'output'
$dataCandidates = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -Filter 'q4' | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'q4_population_projection.csv') -PathType Leaf
})
if ($dataCandidates.Count -ne 1) {
    throw "Could not uniquely locate the Q4 data directory. Count=$($dataCandidates.Count)"
}
$data = $dataCandidates[0].FullName

$figureCandidates = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -Filter 'q4' | Where-Object {
    @(Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.png' -ErrorAction SilentlyContinue).Count -eq 4
})
if ($figureCandidates.Count -ne 1) {
    throw "Could not uniquely locate the Q4 figure directory. Count=$($figureCandidates.Count)"
}
$figures = $figureCandidates[0].FullName
$figureFiles = @(Get-ChildItem -LiteralPath $figures -File -Filter '*.png')

$required = @(
    (Join-Path $data 'q4_population_projection.csv'),
    (Join-Path $data 'q4_scenario_parameters.csv'),
    (Join-Path $data 'q4_source_manifest.csv'),
    (Join-Path $data 'q4_evidence_notes.md'),
    (Join-Path $PSScriptRoot 'run_q4_all.m'),
    (Join-Path $PSScriptRoot 'load_q4_data.m'),
    (Join-Path $PSScriptRoot 'build_q4_baseline.m'),
    (Join-Path $PSScriptRoot 'run_q4_scenarios.m'),
    (Join-Path $PSScriptRoot 'q4_uncertainty_analysis.m'),
    (Join-Path $PSScriptRoot 'q4_model_checks.m'),
    (Join-Path $PSScriptRoot 'q4_python_smoke_test.py'),
    (Join-Path $output 'q4_baseline_grid.csv'),
    (Join-Path $output 'q4_baseline_burden.csv'),
    (Join-Path $output 'q4_scenario_results.csv'),
    (Join-Path $output 'q4_uncertainty_summary.csv'),
    (Join-Path $output 'q4_sensitivity_ranking.csv'),
    (Join-Path $output 'q4_model_checks.csv'),
    (Join-Path $output 'q4_results.mat'),
    (Join-Path $output 'q4_run_log.txt')
)
$required += $figureFiles.FullName

$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Q4 package is incomplete:`n$($missing -join "`n")"
}

$checks = Import-Csv (Join-Path $output 'q4_model_checks.csv')
$failed = @($checks | Where-Object { $_.status -ne 'PASS' })
if ($failed.Count -gt 0) {
    throw "Q4 model checks contain FAIL rows: $($failed.check_name -join ', ')"
}

$population = Import-Csv (Join-Path $data 'q4_population_projection.csv')
if ($population.Count -ne 27 -or $population[0].year -ne '2024' -or $population[-1].year -ne '2050') {
    throw 'Population input must contain 27 rows covering 2024-2050.'
}

Write-Output "Q4 package static check: PASS"
Write-Output "Required files: $($required.Count)"
Write-Output "Model checks: $($checks.Count) PASS"
Write-Output "Population rows: $($population.Count)"

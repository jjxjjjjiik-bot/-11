$ErrorActionPreference = "Stop"

$matlabDir = $PSScriptRoot
$matlabParent = Split-Path -Parent $matlabDir
$root = Split-Path -Parent $matlabParent
$sourceParent = Get-ChildItem -LiteralPath $root -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName "q3\q3_source_manifest.csv")
} | Select-Object -First 1 -ExpandProperty FullName
$sourceDir = if ($sourceParent) { Join-Path $sourceParent "q3" } else { $null }

if (-not $sourceDir) {
    throw "Cannot locate the q3 source directory from project root: $root"
}

$requiredSourceFiles = @(
    "q3_source_manifest.csv",
    "q3_parameter_table.csv",
    "q3_evidence_notes.md",
    "q3_extraction_notes.csv",
    "q3_scoring_rules.csv"
)

$requiredMatlabFiles = @(
    "run_q3_all.m",
    "load_q3_data.m",
    "build_q3_profiles.m",
    "build_q3_plans.m",
    "q3_apply_safety_constraints.m",
    "q3_topsis_rank.m",
    "q3_rank_with_ties.m",
    "q3_model_checks.m",
    "q3_sensitivity_analysis.m",
    "plot_q3_profiles.m",
    "plot_q3_ranking.m",
    "plot_q3_coverage.m"
)

$requiredOutputs = @(
    "q3_profile_scores.csv",
    "q3_plan_scores.csv",
    "q3_plan_ranking.csv",
    "q3_parameter_table_used.csv",
    "q3_scoring_rules_used.csv",
    "q3_model_checks.csv",
    "q3_weight_sensitivity.csv",
    "q3_weight_sensitivity_summary.csv",
    "q3_run_log.txt",
    "q3_results.mat"
)

$failures = New-Object System.Collections.Generic.List[string]

foreach ($name in $requiredSourceFiles) {
    $path = Join-Path $sourceDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing source file: $path")
    }
}

foreach ($name in $requiredMatlabFiles) {
    $path = Join-Path $matlabDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing MATLAB file: $path")
    }
}

if (-not (Get-ChildItem -LiteralPath $matlabDir -Filter "README_*.md" -File -ErrorAction SilentlyContinue)) {
    $failures.Add("Missing MATLAB README file in: $matlabDir")
}

$manifestPath = Join-Path $sourceDir "q3_source_manifest.csv"
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Import-Csv -LiteralPath $manifestPath
    foreach ($row in $manifest) {
        if ($row.local_archive_file -and $row.local_archive_file.Trim().Length -gt 0) {
            $localPath = $row.local_archive_file
            if (-not [System.IO.Path]::IsPathRooted($localPath)) {
                $localPath = Join-Path $sourceDir $localPath
            }
            if (-not (Test-Path -LiteralPath $localPath)) {
                $failures.Add("Manifest archive is missing: source_id=$($row.source_id), path=$localPath")
            }
        }
    }
}

$matlabFiles = Get-ChildItem -LiteralPath $matlabDir -Filter "*.m" -File -ErrorAction SilentlyContinue
$forbidden = @("saveas\s*\(", "exportgraphics\s*\(", "print\s*\(", "savefig\s*\(", "imwrite\s*\(")
foreach ($file in $matlabFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $forbidden) {
        if ($text -match $pattern) {
            $failures.Add("Forbidden image export command: $($file.FullName) pattern=$pattern")
        }
    }
}

$runPath = Join-Path $matlabDir "run_q3_all.m"
if (Test-Path -LiteralPath $runPath) {
    $runText = Get-Content -LiteralPath $runPath -Raw
    foreach ($outputName in $requiredOutputs) {
        if ($runText -notmatch [regex]::Escape($outputName)) {
            $failures.Add("Missing output contract in run_q3_all.m: $outputName")
        }
    }

    if ($runText -notmatch "profile_match_score") {
        $failures.Add("run_q3_all.m does not include profile_match_score")
    }
    if ($runText -notmatch "'P36'") {
        $failures.Add("run_q3_all.m does not load P36")
    }

    $figureFiles = @(
        (Join-Path $matlabDir "plot_q3_profiles.m"),
        (Join-Path $matlabDir "plot_q3_ranking.m"),
        (Join-Path $matlabDir "plot_q3_coverage.m")
    )
    foreach ($figureFile in $figureFiles) {
        if ((Test-Path -LiteralPath $figureFile) -and
            ((Get-Content -LiteralPath $figureFile -Raw) -notmatch "figure\(")) {
            $failures.Add("Missing figure creation in: $figureFile")
        }
        if ((Test-Path -LiteralPath $figureFile) -and
            ((Get-Content -LiteralPath $figureFile -Raw) -notmatch "title\(")) {
            $failures.Add("Missing chart title in: $figureFile")
        }
    }
}

$planPath = Join-Path $matlabDir "build_q3_plans.m"
if (Test-Path -LiteralPath $planPath) {
    $planText = Get-Content -LiteralPath $planPath -Raw
    if ($planText -notmatch "profile_match_score") {
        $failures.Add("Plan table does not include profile_match_score")
    }
}

$checkPath = Join-Path $matlabDir "q3_model_checks.m"
if (Test-Path -LiteralPath $checkPath) {
    $checkText = Get-Content -LiteralPath $checkPath -Raw
    if ($checkText -notmatch "scenario_count == 12") {
        $failures.Add("Model checks do not require 12 scenarios per profile")
    }
    if ($checkText -notmatch "height\(sensitivity\) == 60") {
        $failures.Add("Model checks do not require 60 total scenarios")
    }
}

$q3PaperPath = Join-Path $root "sections\q3.tex"
if (Test-Path -LiteralPath $q3PaperPath) {
    $q3PaperText = Get-Content -LiteralPath $q3PaperPath -Raw -Encoding UTF8
    $guidelineScreening = -join @(
        [char]0x6307, [char]0x5357, [char]0x8303,
        [char]0x56F4, [char]0x521D, [char]0x7B5B
    )
    $safetyHardConstraint = -join @(
        [char]0x5B89, [char]0x5168, [char]0x786C,
        [char]0x7EA6, [char]0x675F
    )
    if ($q3PaperText -notmatch [regex]::Escape($guidelineScreening)) {
        $failures.Add("q3.tex does not describe the four-condition gate as a guideline-range screening")
    }
    if ($q3PaperText -match [regex]::Escape($safetyHardConstraint)) {
        $failures.Add("q3.tex overstates the four-condition gate as a safety hard constraint")
    }
}

if (Test-Path -LiteralPath (Join-Path $sourceDir "q3_parameter_table.csv")) {
    $parameterRows = Import-Csv -LiteralPath (Join-Path $sourceDir "q3_parameter_table.csv") -Encoding UTF8
    $unenforcedIntakeRows = $parameterRows | Where-Object {
        $_.parameter_id -in @("P10", "P11", "P12", "P13") -and
        $_.is_hard_constraint -eq "yes"
    }
    if ($unenforcedIntakeRows) {
        $failures.Add("P10-P13 are reference intake values but are marked as enforced hard constraints")
    }
}

foreach ($file in $matlabFiles) {
    $firstFunction = Get-Content -LiteralPath $file.FullName | Where-Object {
        $_ -match "^\s*function\s+"
    } | Select-Object -First 1
    if (-not $firstFunction) {
        $failures.Add("Missing leading function definition: $($file.FullName)")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "q3 package static check passed."

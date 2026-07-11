function scenarioResults = run_q4_scenarios(data, baselineBurden)
% RUN_Q4_SCENARIOS  计算低、中、高三种点情景。

scenarioNames = ["low"; "medium"; "high"];
nYears = height(baselineBurden);
nRows = numel(scenarioNames) * nYears;

scenario = strings(nRows, 1);
year = zeros(nRows, 1);
coverage = zeros(nRows, 1);
adherence = zeros(nRows, 1);
effect = zeros(nRows, 1);
ramp = zeros(nRows, 1);
achievedReduction = zeros(nRows, 1);
baseline = zeros(nRows, 1);
scenarioBurden = zeros(nRows, 1);
avoidableBurden = zeros(nRows, 1);

row = 0;
for s = 1:numel(scenarioNames)
    name = scenarioNames(s);
    group = data.scenarios(data.scenarios.scenario == name, :);
    c = group.mode(group.parameter == "coverage");
    a = group.mode(group.parameter == "adherence");
    e = group.mode(group.parameter == "effect");
    for j = 1:nYears
        row = row + 1;
        t = baselineBurden.year(j);
        growth = min(max((t - 2024) / 6, 0), 1);
        reduction = growth * c * a * e;
        b0 = baselineBurden.primary_burden_persons(j);
        bs = b0 * (1 - reduction);

        scenario(row) = name;
        year(row) = t;
        coverage(row) = c;
        adherence(row) = a;
        effect(row) = e;
        ramp(row) = growth;
        achievedReduction(row) = reduction;
        baseline(row) = b0;
        scenarioBurden(row) = bs;
        avoidableBurden(row) = b0 - bs;
    end
end

scenarioResults = table(scenario, year, coverage, adherence, effect, ramp, ...
    achievedReduction, baseline, scenarioBurden, avoidableBurden, ...
    'VariableNames', {'scenario','year','coverage_mode','adherence_mode','effect_mode', ...
    'implementation_ramp','achieved_reduction_fraction','baseline_burden_persons', ...
    'scenario_burden_persons','avoidable_burden_persons'});
end


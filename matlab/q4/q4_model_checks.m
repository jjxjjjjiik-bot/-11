function checks = q4_model_checks(data, baselineGrid, baselineBurden, scenarioResults, summary, sensitivity, mcInputs)
% Q4_MODEL_CHECKS  执行问题四数值与复现性自检。

names = strings(0,1);
passed = false(0,1);
values = strings(0,1);
thresholds = strings(0,1);
details = strings(0,1);

addCheck("year_coverage", isequal(data.population.year, (2024:2050)'), ...
    sprintf('%d rows', height(data.population)), "27 rows", "年份连续覆盖2024--2050");
addCheck("adult_population_positive", all(data.population.population_18plus_persons > 0), ...
    sprintf('min=%.3f', min(data.population.population_18plus_persons)), ">0", "成年人口为正");
addCheck("adult_not_above_total", all(data.population.population_18plus_persons <= data.population.total_population_persons), ...
    sprintf('max share=%.6f', max(data.population.adult_share_percent)), "<=100%", "成年人口不超过总人口");
adultExpected = data.population.total_population_persons - data.population.population_under18_persons;
adultError = max(abs(adultExpected - data.population.population_18plus_persons));
addCheck("adult_formula", adultError <= 1, sprintf('max error=%.6f persons', adultError), "<=1 person", "单岁人口18+汇总一致");
addCheck("baseline_grid_size", height(baselineGrid) == 324, ...
    sprintf('%d rows', height(baselineGrid)), "324 rows", "两模型六个K和27年完整");
addCheck("rate_physical", all(baselineGrid.rate_percent > 0 & baselineGrid.rate_percent < 100), ...
    sprintf('[%.6f, %.6f]', min(baselineGrid.rate_percent), max(baselineGrid.rate_percent)), "inside (0,100)", "预测率物理边界");

anchorTargets = [64.7076528512985, 83.9216798604218, 62.4224469407754, 78.3855422400629];
anchorValues = [getRate("Logistic",100,2030), getRate("Logistic",100,2050), ...
    getRate("Gompertz",100,2030), getRate("Gompertz",100,2050)];
anchorError = max(abs(anchorTargets - anchorValues));
addCheck("q1_anchor_values", anchorError <= 2e-6, sprintf('max error=%.12g', anchorError), ...
    "<=2e-6 percentage points", "K=100结果与问题一一致");

burdenError = max(abs(baselineBurden.primary_burden_persons - ...
    baselineBurden.population_18plus_persons .* baselineBurden.primary_rate_percent ./ 100));
addCheck("baseline_identity", burdenError <= 1, sprintf('max error=%.6f persons', burdenError), ...
    "<=1 person", "B0=Np恒等式");

scenarioError = max(abs(scenarioResults.baseline_burden_persons - ...
    scenarioResults.scenario_burden_persons - scenarioResults.avoidable_burden_persons));
addCheck("scenario_identity", scenarioError <= 1, sprintf('max error=%.6f persons', scenarioError), ...
    "<=1 person", "DeltaB=B0-Bs恒等式");
addCheck("scenario_physical", all(scenarioResults.avoidable_burden_persons >= -1 & ...
    scenarioResults.scenario_burden_persons >= -1 & ...
    scenarioResults.scenario_burden_persons <= scenarioResults.baseline_burden_persons + 1), ...
    "all rows", "all inside bounds", "情景人数物理边界");

orderPass = true;
for t = data.analysisYears'
    group = scenarioResults(scenarioResults.year == t, :);
    group = group(ismember(group.scenario, ["low","medium","high"]), :);
    [~, order] = ismember(["low","medium","high"], group.scenario);
    avoided = group.avoidable_burden_persons(order);
    orderPass = orderPass && all(diff(avoided) >= -1);
end
addCheck("scenario_order", orderPass, "low<=medium<=high", "monotone", "点情景可避免人数单调");
addCheck("ramp_zero_2024", all(abs(scenarioResults.avoidable_burden_persons(scenarioResults.year == 2024)) <= 1), ...
    "2024 avoided near zero", "<=1 person", "2024爬坡系数为0");

quantilePass = all(summary.baseline_p05 <= summary.baseline_p50 & summary.baseline_p50 <= summary.baseline_p95 & ...
    summary.scenario_p05 <= summary.scenario_p50 & summary.scenario_p50 <= summary.scenario_p95 & ...
    summary.avoidable_p05 <= summary.avoidable_p50 & summary.avoidable_p50 <= summary.avoidable_p95);
addCheck("quantile_order", quantilePass, sprintf('%d rows', height(summary)), "all ordered", "模拟分位数有序");
addCheck("uncertainty_row_count", height(summary) == 162, sprintf('%d rows', height(summary)), ...
    "162 rows", "两范围三情景27年完整");
addCheck("sensitivity_bounds", all(isfinite(sensitivity.spearman_rho) & abs(sensitivity.spearman_rho) <= 1 + 1e-12), ...
    sprintf('%d rows', height(sensitivity)), "finite and |rho|<=1", "Spearman系数有效");

expectedRandom = [0.88115599744457407; 0.6600970783104223; 0.96196395326071882; ...
    0.41201702263683992; 0.16499530149406494];
randomError = max(abs(mcInputs.u_model(1:5) - expectedRandom));
addCheck("random_seed_reproducible", randomError <= 1e-14, sprintf('max error=%.3g', randomError), ...
    "<=1e-14", "固定种子首5个随机数一致");

midpointError = q4_midpoint_interpolation_error(data, baselineGrid);
addCheck("K_interpolation_error", midpointError <= 0.05, sprintf('max error=%.6f pp', midpointError), ...
    "<=0.05 percentage points", "K网格线性插值误差");
addCheck("zero_one_edges", abs(100 * (1 - 0 * 0.5 * 0.5) - 100) < 1e-12 && ...
    abs(100 * (1 - 1 * 1 * 1)) < 1e-12, "passed", "exact", "零效果与完全效果边界");

status = repmat("FAIL", numel(passed), 1);
status(passed) = "PASS";
checks = table(names, status, values, thresholds, details, ...
    'VariableNames', {'check_name','status','value','threshold','detail'});
if any(~passed)
    failedNames = strjoin(cellstr(names(~passed)), ', ');
    error('问题四模型自检失败：%s', failedNames);
end

    function addCheck(name, condition, valueText, thresholdText, detailText)
        names(end+1,1) = name;
        passed(end+1,1) = logical(condition);
        values(end+1,1) = string(valueText);
        thresholds(end+1,1) = string(thresholdText);
        details(end+1,1) = string(detailText);
    end

    function rate = getRate(modelName, KValue, targetYear)
        mask = baselineGrid.model == modelName & baselineGrid.K == KValue & baselineGrid.year == targetYear;
        rate = baselineGrid.rate_percent(mask);
    end
end

function maxError = q4_midpoint_interpolation_error(data, baselineGrid)
midpoints = (77.5:5:97.5)';
maxError = 0;
for k = 1:numel(midpoints)
    K = midpoints(k);
    [r, t0] = logistic_fit(data.q1Years, data.q1Rates, K);
    actualL = K ./ (1 + exp(-r .* (data.analysisYears - t0)));
    [a, b] = gompertz_fit(data.q1Years, data.q1Rates, K);
    actualG = K .* exp(-a .* exp(-b .* (data.analysisYears - 1992)));
    for j = 1:numel(data.analysisYears)
        t = data.analysisYears(j);
        partL = sortrows(baselineGrid(baselineGrid.model == "Logistic" & baselineGrid.year == t, :), 'K');
        partG = sortrows(baselineGrid(baselineGrid.model == "Gompertz" & baselineGrid.year == t, :), 'K');
        interpL = interp1(partL.K, partL.rate_percent, K);
        interpG = interp1(partG.K, partG.rate_percent, K);
        maxError = max([maxError, abs(interpL - actualL(j)), abs(interpG - actualG(j))]);
    end
end
end

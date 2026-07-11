function [detailTable, summaryTable] = q3_sensitivity_analysis( ...
    plans, criteriaNames, baselineWeights, criteriaType)
% Q3_SENSITIVITY_ANALYSIS  对每个 TOPSIS 权重做 +/-20% 单项扰动。
% 安全性已作为硬约束，故这里只分析保留的 6 个评价指标。

safePlans = plans(plans.is_safe, :);
profileIds = unique(safePlans.profile_id, 'stable');
multipliers = [0.8, 1.2];
rows = {};

for i = 1:numel(profileIds)
    profileRows = safePlans.profile_id == profileIds(i);
    profilePlans = safePlans(profileRows, :);

    [baselineScores, ~] = q3_topsis_rank( ...
        profilePlans{:, criteriaNames}, baselineWeights, criteriaType);
    baselineRanks = q3_rank_with_ties(-baselineScores, 1e-9);
    baselineBest = profilePlans.plan_type(baselineRanks == 1);
    baselineBest = baselineBest(1);

    for j = 1:numel(criteriaNames)
        for k = 1:numel(multipliers)
            adjustedWeights = perturb_weight( ...
                baselineWeights, j, multipliers(k));

            [scores, ~] = q3_topsis_rank( ...
                profilePlans{:, criteriaNames}, adjustedWeights, criteriaType);
            ranks = q3_rank_with_ties(-scores, 1e-9);
            adjustedBest = profilePlans.plan_type(ranks == 1);
            adjustedBest = adjustedBest(1);

            rows(end+1, :) = { ...
                profilePlans.profile_id(1), profilePlans.profile_name(1), ...
                string(criteriaNames{j}), multipliers(k), ...
                string(baselineBest), string(adjustedBest), ...
                baselineBest == adjustedBest};
        end
    end
end

detailTable = cell2table(rows, 'VariableNames', { ...
    'profile_id','profile_name','perturbed_criterion','weight_multiplier', ...
    'baseline_best_plan','perturbed_best_plan','best_plan_unchanged'});

summaryRows = {};
for i = 1:numel(profileIds)
    rowsForProfile = detailTable.profile_id == profileIds(i);
    scenarioCount = sum(rowsForProfile);
    stableCount = sum(detailTable.best_plan_unchanged(rowsForProfile));
    summaryRows(end+1, :) = { ...
        profileIds(i), detailTable.profile_name(find(rowsForProfile, 1)), ...
        scenarioCount, stableCount, stableCount / scenarioCount, ...
        stableCount == scenarioCount};
end

summaryTable = cell2table(summaryRows, 'VariableNames', { ...
    'profile_id','profile_name','scenario_count','unchanged_count', ...
    'stability_rate','is_fully_stable'});
end

function adjustedWeights = perturb_weight(baselineWeights, targetIndex, multiplier)
% 固定被扰动权重为基准值的 80% 或 120%，
% 再把剩余权重按原比例分配给其余指标，确保权重和仍为 1。

baselineWeights = baselineWeights(:)';
if any(baselineWeights < 0) || sum(baselineWeights) <= 0
    error('基准权重必须非负，且权重和大于 0。');
end
baselineWeights = baselineWeights ./ sum(baselineWeights);

targetWeight = baselineWeights(targetIndex) * multiplier;
if targetWeight <= 0 || targetWeight >= 1
    error('扰动后的目标权重必须位于 0 和 1 之间。');
end

otherIndices = setdiff(1:numel(baselineWeights), targetIndex);
otherBaseTotal = sum(baselineWeights(otherIndices));
adjustedWeights = zeros(size(baselineWeights));
adjustedWeights(targetIndex) = targetWeight;
adjustedWeights(otherIndices) = baselineWeights(otherIndices) ./ otherBaseTotal .* ...
    (1 - targetWeight);
end

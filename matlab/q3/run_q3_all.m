function run_q3_all()
% RUN_Q3_ALL  问题三一键运行入口。
% 本脚本不自动导出 PNG/JPG，只打开 figure 图形窗口，便于手动导出。

clc;
close all;

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
q3Dir = fullfile(rootDir, 'matlab', 'q3');
outputDir = fullfile(q3Dir, 'output');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

logPath = fullfile(outputDir, 'q3_run_log.txt');
diary(logPath);
diary on;
cleanupObj = onCleanup(@() diary('off'));

fprintf('问题三模型运行开始：%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('工作目录：%s\n', q3Dir);
fprintf('输出目录：%s\n\n', outputDir);

fprintf('[1/8] 读取参数表...\n');
data = load_q3_data(rootDir);
fprintf('  已读取参数 %d 条。\n', height(data.parameters));

fprintf('[2/8] 构建 5 类典型生活方式画像...\n');
profiles = build_q3_profiles();
writetable(profiles, fullfile(outputDir, 'q3_profile_scores.csv'), 'Encoding', 'UTF-8');
fprintf('  已输出 q3_profile_scores.csv。\n');

fprintf('[3/8] 构建 15 套候选减重方案...\n');
plans = build_q3_plans(profiles, data.paramMap);
plans = q3_apply_safety_constraints(plans, data.paramMap);
fprintf('  通过四项指南范围初筛方案 %d/%d 套。\n', sum(plans.is_safe), height(plans));

fprintf('[4/8] 进行 TOPSIS 综合评价...\n');
weights = [ ...
    get_param(data.paramMap, 'P28'), ...
    get_param(data.paramMap, 'P30'), ...
    get_param(data.paramMap, 'P31'), ...
    get_param(data.paramMap, 'P32'), ...
    get_param(data.paramMap, 'P36'), ...
    get_param(data.paramMap, 'P33')];
if abs(sum(weights) - 1) > 1e-12
    error('TOPSIS 权重和必须为 1，当前为 %.12f。', sum(weights));
end
criteriaNames = {'effect_score','feasibility_score','persistence_score', ...
    'failure_coverage_score','profile_match_score','time_burden_min_day'};
criteriaType = [1, 1, 1, 1, 1, -1]; % 1=收益型，-1=成本型
plans.topsis_score = nan(height(plans), 1);
plans.rank = nan(height(plans), 1);
plans.distance_to_best = nan(height(plans), 1);
plans.distance_to_worst = nan(height(plans), 1);
profileIds = unique(plans.profile_id, 'stable');
for i = 1:numel(profileIds)
    profileRows = plans.profile_id == profileIds(i) & plans.is_safe;
    if sum(profileRows) < 2
        error('画像 %d 通过四项指南范围初筛的候选方案少于 2 套，无法进行 TOPSIS 比较。', profileIds(i));
    end
    [profileScores, detail] = q3_topsis_rank( ...
        plans{profileRows, criteriaNames}, weights, criteriaType);
    plans.topsis_score(profileRows) = profileScores;
    plans.rank(profileRows) = q3_rank_with_ties(-profileScores, 1e-9);
    plans.distance_to_best(profileRows) = detail.distanceToBest;
    plans.distance_to_worst(profileRows) = detail.distanceToWorst;
end

ranking = sortrows(plans(plans.is_safe, :), {'profile_id','rank','plan_type'}, {'ascend','ascend','ascend'});
writetable(plans, fullfile(outputDir, 'q3_plan_scores.csv'), 'Encoding', 'UTF-8');
writetable(ranking, fullfile(outputDir, 'q3_plan_ranking.csv'), 'Encoding', 'UTF-8');
fprintf('  已输出 q3_plan_scores.csv 和 q3_plan_ranking.csv。\n');

fprintf('[5/8] 进行权重敏感性分析...\n');
[sensitivity, sensitivitySummary] = q3_sensitivity_analysis( ...
    plans, criteriaNames, weights, criteriaType);
writetable(sensitivity, fullfile(outputDir, 'q3_weight_sensitivity.csv'), 'Encoding', 'UTF-8');
writetable(sensitivitySummary, fullfile(outputDir, 'q3_weight_sensitivity_summary.csv'), 'Encoding', 'UTF-8');
fprintf('  已输出 q3_weight_sensitivity.csv 和 q3_weight_sensitivity_summary.csv。\n');

fprintf('[6/8] 执行模型自检...\n');
checks = q3_model_checks( ...
    data, profiles, plans, ranking, sensitivity, sensitivitySummary, weights);
writetable(checks, fullfile(outputDir, 'q3_model_checks.csv'), 'Encoding', 'UTF-8');
fprintf('  已输出 q3_model_checks.csv。\n');

fprintf('[7/8] 写出参数、评分规则和 MAT 结果文件...\n');
writetable(data.parameters, fullfile(outputDir, 'q3_parameter_table_used.csv'), 'Encoding', 'UTF-8');
writetable(data.scoringRules, fullfile(outputDir, 'q3_scoring_rules_used.csv'), 'Encoding', 'UTF-8');
q3_results = struct();
q3_results.parameters = data.parameters;
q3_results.profiles = profiles;
q3_results.plans = plans;
q3_results.ranking = ranking;
q3_results.checks = checks;
q3_results.sensitivity = sensitivity;
q3_results.sensitivitySummary = sensitivitySummary;
save(fullfile(outputDir, 'q3_results.mat'), 'q3_results');
fprintf('  已输出 q3_parameter_table_used.csv、q3_scoring_rules_used.csv 和 q3_results.mat。\n');

fprintf('[8/8] 打开图形窗口，请在 MATLAB 中手动导出 PNG...\n');
plot_q3_profiles(profiles);
plot_q3_ranking(ranking);
plot_q3_coverage(ranking);

fprintf('\n运行结束：%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('请发回 output 目录中的 CSV，以及手动导出的 3 张 PNG 图片。\n');
end

function value = get_param(paramMap, parameterId)
if ~isKey(paramMap, parameterId)
    error('缺少参数：%s。请检查 q3_parameter_table.csv。', parameterId);
end
value = paramMap(parameterId);
end

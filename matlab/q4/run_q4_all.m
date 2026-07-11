function run_q4_all()
% RUN_Q4_ALL  问题四数据、模型、模拟、自检和中文制图一键入口。

clc;
close all;

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
q4Dir = fullfile(rootDir, 'matlab', 'q4');
outputDir = fullfile(q4Dir, 'output');
figureDir = fullfile(rootDir, 'figures', 'q4');
if ~exist(outputDir, 'dir'); mkdir(outputDir); end
if ~exist(figureDir, 'dir'); mkdir(figureDir); end
addpath(fullfile(rootDir, 'matlab', 'q1'));
addpath(q4Dir);

logPath = fullfile(outputDir, 'q4_run_log.txt');
diary(logPath);
diary on;
cleanupObj = onCleanup(@() diary('off')); %#ok<NASGU>

fprintf('问题四模型运行开始：%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('蒙特卡洛次数：50000；随机种子：20260711\n\n');

fprintf('[1/7] 读取并校验输入数据...\n');
data = load_q4_data(rootDir);

fprintf('[2/7] 重新拟合问题一模型并构造年度基准负担...\n');
[baselineGrid, baselineBurden] = build_q4_baseline(data);
writetable(baselineGrid, fullfile(outputDir, 'q4_baseline_grid.csv'), 'Encoding', 'UTF-8');
writetable(baselineBurden, fullfile(outputDir, 'q4_baseline_burden.csv'), 'Encoding', 'UTF-8');

fprintf('[3/7] 计算低、中、高点情景...\n');
scenarioResults = run_q4_scenarios(data, baselineBurden);
writetable(scenarioResults, fullfile(outputDir, 'q4_scenario_results.csv'), 'Encoding', 'UTF-8');

fprintf('[4/7] 执行政策参数与联合结构情景抽样...\n');
[uncertaintySummary, sensitivity, mcInputs] = q4_uncertainty_analysis(data, baselineGrid, baselineBurden);
writetable(uncertaintySummary, fullfile(outputDir, 'q4_uncertainty_summary.csv'), 'Encoding', 'UTF-8');
writetable(sensitivity, fullfile(outputDir, 'q4_sensitivity_ranking.csv'), 'Encoding', 'UTF-8');
writetable(mcInputs, fullfile(outputDir, 'q4_mc_inputs.csv'), 'Encoding', 'UTF-8');

keyResults = build_key_results(baselineBurden, scenarioResults, uncertaintySummary);
writetable(keyResults, fullfile(outputDir, 'q4_key_results.csv'), 'Encoding', 'UTF-8');

fprintf('[5/7] 执行模型自检...\n');
checks = q4_model_checks(data, baselineGrid, baselineBurden, scenarioResults, ...
    uncertaintySummary, sensitivity, mcInputs);
writetable(checks, fullfile(outputDir, 'q4_model_checks.csv'), 'Encoding', 'UTF-8');

fprintf('[6/7] 保存MAT结果并导出4张300dpi中文PNG...\n');
q4_results = struct('data', data, 'baselineGrid', baselineGrid, ...
    'baselineBurden', baselineBurden, 'scenarioResults', scenarioResults, ...
    'uncertaintySummary', uncertaintySummary, 'sensitivity', sensitivity, ...
    'keyResults', keyResults, 'checks', checks);
save(fullfile(outputDir, 'q4_results.mat'), 'q4_results');
plot_q4_dpsir(fullfile(figureDir, 'DPSIR危险机会传导框架.png'));
plot_q4_burden(baselineBurden, fullfile(figureDir, '成人超重肥胖基准负担.png'));
plot_q4_scenarios(scenarioResults, fullfile(figureDir, '不同干预情景负担比较.png'));
plot_q4_sensitivity(uncertaintySummary, sensitivity, fullfile(figureDir, '不确定性与参数敏感性.png'));

fprintf('[7/7] 输出关键结果...\n');
disp(keyResults);
fprintf('\n问题四模型运行结束：%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
end

function keyResults = build_key_results(baselineBurden, scenarioResults, uncertaintySummary)
targetYears = [2030; 2050];
scenarioNames = ["low"; "medium"; "high"];
rows = cell(0, 14);
for y = 1:numel(targetYears)
    t = targetYears(y);
    b = baselineBurden(baselineBurden.year == t, :);
    for s = 1:numel(scenarioNames)
        name = scenarioNames(s);
        point = scenarioResults(scenarioResults.year == t & scenarioResults.scenario == name, :);
        policy = uncertaintySummary(uncertaintySummary.scope == "policy_only_primary" & ...
            uncertaintySummary.year == t & uncertaintySummary.scenario == name, :);
        joint = uncertaintySummary(uncertaintySummary.scope == "joint_structure_policy" & ...
            uncertaintySummary.year == t & uncertaintySummary.scenario == name, :);
        rows(end+1,:) = {char(name), t, b.population_18plus_persons, b.primary_rate_percent, ...
            b.primary_burden_persons, point.scenario_burden_persons, point.avoidable_burden_persons, ...
            policy.avoidable_p05, policy.avoidable_p50, policy.avoidable_p95, ...
            joint.avoidable_p05, joint.avoidable_p50, joint.avoidable_p95, ...
            point.achieved_reduction_fraction}; %#ok<AGROW>
    end
end
keyResults = cell2table(rows, 'VariableNames', {'scenario','year','population_18plus_persons', ...
    'primary_rate_percent','baseline_burden_persons','scenario_burden_persons', ...
    'avoidable_burden_persons','policy_avoidable_p05','policy_avoidable_p50', ...
    'policy_avoidable_p95','joint_avoidable_p05','joint_avoidable_p50', ...
    'joint_avoidable_p95','achieved_reduction_fraction'});
keyResults.scenario = string(keyResults.scenario);
end

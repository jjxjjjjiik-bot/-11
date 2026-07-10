function run_q2_all()
%RUN_Q2_ALL Public entry point for all Q2 calculations and figures.

rootDir = fileparts(mfilename('fullpath'));
outputDir = fullfile(rootDir, 'output');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
addpath(rootDir);

logFile = fullfile(outputDir, 'q2_run_log.txt');
try
    fontName = choose_q2_chinese_font();
    fprintf('Q2 Chinese font: %s\n', fontName);

    data = load_q2_data(rootDir);
    results = sensitivity_analysis_q2(data);
    checks = self_check_q2(data, results);

    write_weights_csv(fullfile(outputDir, 'q2_critic_weights.csv'), ...
        results.scenarios(1).weights);
    write_ranking_csv(fullfile(outputDir, 'q2_topsis_ranking.csv'), ...
        data, results.scenarios(1));
    write_sensitivity_csv(fullfile(outputDir, 'q2_sensitivity_results.csv'), ...
        data, results);
    write_checks_csv(fullfile(outputDir, 'q2_model_checks.csv'), checks);

    save(fullfile(outputDir, 'q2_results.mat'), 'data', 'results', 'checks');

    plot_q2_mechanism();
    plot_q2_ranking(data, results.scenarios(1));
    plot_q2_sensitivity(data, results);

    write_run_log(logFile, data, results, checks, 'SUCCESS', '');
    fprintf('Q2 completed. Output: %s\n', outputDir);
    fprintf('Q2 figure windows are open for manual editing and export.\n');
catch ME
    write_run_log(logFile, [], [], [], 'FAILED', ME.message);
    rethrow(ME);
end
end


function write_weights_csv(pathName, weights)
criterion_id = {'C1'; 'C2'; 'C3'};
criterion_cn = {'研究数量'; '方向一致率'; '证据等级'};
weight = weights(:);
T = table(criterion_id, criterion_cn, weight);
writetable(T, pathName);
end


function write_ranking_csv(pathName, data, scenario)
order = q2_display_order(data, scenario.scores);
factor_id = data.factor_id(order);
factor_cn = data.factor_cn(order);
category = data.category(order);
n_studies = data.n_studies(order);
consistency = data.consistency(order);
evidence_code = data.evidence_code(order);
topsis_score = scenario.scores(order);
rank = scenario.ranks(order);
T = table(factor_id, factor_cn, category, n_studies, consistency, ...
    evidence_code, topsis_score, rank);
writetable(T, pathName);
end


function write_sensitivity_csv(pathName, data, results)
scenario_id = {};
scenario_cn = {};
factor_id = {};
topsis_score = [];
rank = [];
weight_studies = [];
weight_consistency = [];
weight_evidence = [];
spearman_rho = [];
top5_overlap = [];
max_rank_change = [];

for s = 1:numel(results.scenarios)
    item = results.scenarios(s);
    weights = item.weights(:)';
    if numel(weights) < 3
        weights(3) = NaN;
    end
    for i = 1:data.count
        scenario_id{end + 1, 1} = item.id; %#ok<AGROW>
        scenario_cn{end + 1, 1} = item.name; %#ok<AGROW>
        factor_id{end + 1, 1} = data.factor_id{i}; %#ok<AGROW>
        topsis_score(end + 1, 1) = item.scores(i); %#ok<AGROW>
        rank(end + 1, 1) = item.ranks(i); %#ok<AGROW>
        weight_studies(end + 1, 1) = weights(1); %#ok<AGROW>
        weight_consistency(end + 1, 1) = weights(2); %#ok<AGROW>
        weight_evidence(end + 1, 1) = weights(3); %#ok<AGROW>
        spearman_rho(end + 1, 1) = item.spearman_rho; %#ok<AGROW>
        top5_overlap(end + 1, 1) = item.top5_overlap; %#ok<AGROW>
        max_rank_change(end + 1, 1) = item.max_rank_change; %#ok<AGROW>
    end
end

T = table(scenario_id, scenario_cn, factor_id, topsis_score, rank, ...
    weight_studies, weight_consistency, weight_evidence, spearman_rho, ...
    top5_overlap, max_rank_change);
writetable(T, pathName);
end


function write_checks_csv(pathName, checks)
n = numel(checks);
check_name = cell(n, 1);
status = cell(n, 1);
value = cell(n, 1);
expected = cell(n, 1);
notes = cell(n, 1);
for i = 1:n
    check_name{i} = checks(i).name;
    if checks(i).passed
        status{i} = 'PASS';
    else
        status{i} = 'FAIL';
    end
    value{i} = checks(i).value;
    expected{i} = checks(i).expected;
    notes{i} = checks(i).notes;
end
T = table(check_name, status, value, expected, notes);
writetable(T, pathName);
end


function write_run_log(pathName, data, results, checks, state, errorMessage)
fid = fopen(pathName, 'w');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Q2 MATLAB run log\n');
fprintf(fid, 'Timestamp: %s\n', datestr(now, 31));
fprintf(fid, 'State: %s\n', state);
fprintf(fid, 'MATLAB version: %s\n', version);
if strcmp(state, 'SUCCESS')
    fprintf(fid, 'Factor rows: %d\n', data.count);
    fprintf(fid, 'Baseline CRITIC weights: %.12f, %.12f, %.12f\n', ...
        results.scenarios(1).weights);
    fprintf(fid, 'Minimum Spearman rho: %.12f\n', ...
        min([results.scenarios.spearman_rho]));
    fprintf(fid, 'Failed checks: %d\n', sum(~[checks.passed]));
else
    fprintf(fid, 'Error: %s\n', errorMessage);
end
clear cleanup;
end


function order = q2_display_order(data, scores)
idNumber = zeros(data.count, 1);
for i = 1:data.count
    idNumber(i) = str2double(regexprep(data.factor_id{i}, '[^0-9]', ''));
end
sortMatrix = [-scores(:), -data.n_studies(:), idNumber(:)];
[~, order] = sortrows(sortMatrix, [1, 2, 3]);
end

function results = sensitivity_analysis_q2(data)
%SENSITIVITY_ANALYSIS_Q2 Run the six fixed Q2 scenarios.

n = data.n_studies;
c = data.consistency;
e = data.evidence_code;
wilson = wilson_lower_bound(data.support_count, data.measurement_count);
laplace = (data.support_count + 1) ./ (data.measurement_count + 2);

definitions = struct('id', {}, 'name', {}, 'matrix', {}, 'fixed_weights', {});
definitions(1) = make_definition('S1', '原始一致率+CRITIC权重', [n, c, e], []);
definitions(2) = make_definition('S2', '威尔逊（Wilson）95%下限一致率', [n, wilson, e], []);
definitions(3) = make_definition('S3', '拉普拉斯（Laplace）修正一致率', [n, laplace, e], []);
definitions(4) = make_definition('S4', '研究数量使用对数变换log(1+n)', [log1p(n), c, e], []);
definitions(5) = make_definition('S5', 'TOPSIS等权重', [n, c, e], [1/3, 1/3, 1/3]);
definitions(6) = make_definition('S6', '删除证据等级', [n, c], []);

scenarios = struct('id', {}, 'name', {}, 'matrix', {}, 'weights', {}, ...
    'critic_details', {}, 'scores', {}, 'ranks', {}, 'topsis_details', {}, ...
    'spearman_rho', {}, 'top5_overlap', {}, 'max_rank_change', {});

for i = 1:numel(definitions)
    if isempty(definitions(i).fixed_weights)
        [weights, criticDetails] = critic_weights(definitions(i).matrix);
    else
        weights = definitions(i).fixed_weights;
        criticDetails = struct();
    end
    [scores, ranks, topsisDetails] = ...
        topsis_rank(definitions(i).matrix, weights);
    scenarios(i).id = definitions(i).id;
    scenarios(i).name = definitions(i).name;
    scenarios(i).matrix = definitions(i).matrix;
    scenarios(i).weights = weights;
    scenarios(i).critic_details = criticDetails;
    scenarios(i).scores = scores;
    scenarios(i).ranks = ranks;
    scenarios(i).topsis_details = topsisDetails;
end

baselineScores = scenarios(1).scores;
baselineRanks = scenarios(1).ranks;
baselineTopFive = top_five_indices(data, baselineScores);
for i = 1:numel(scenarios)
    currentTopFive = top_five_indices(data, scenarios(i).scores);
    scenarios(i).spearman_rho = spearman_rank( ...
        baselineScores, scenarios(i).scores);
    scenarios(i).top5_overlap = numel(intersect(baselineTopFive, currentTopFive));
    scenarios(i).max_rank_change = max(abs(baselineRanks - scenarios(i).ranks));
end

results.scenarios = scenarios;
results.baseline_index = 1;
results.wilson_consistency = wilson;
results.laplace_consistency = laplace;
end


function item = make_definition(id, name, matrix, fixedWeights)
item.id = id;
item.name = name;
item.matrix = matrix;
item.fixed_weights = fixedWeights;
end


function indices = top_five_indices(data, scores)
idNumber = zeros(data.count, 1);
for i = 1:data.count
    idNumber(i) = str2double(regexprep(data.factor_id{i}, '[^0-9]', ''));
end
sortMatrix = [-scores(:), -data.n_studies(:), idNumber(:)];
[~, order] = sortrows(sortMatrix, [1, 2, 3]);
indices = order(1:5);
end

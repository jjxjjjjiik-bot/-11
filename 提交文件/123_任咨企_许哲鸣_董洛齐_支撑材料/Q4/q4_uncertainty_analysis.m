function [summary, sensitivity, mcInputs] = q4_uncertainty_analysis(data, baselineGrid, baselineBurden)
% Q4_UNCERTAINTY_ANALYSIS  执行政策参数和联合结构情景抽样。

rng(data.seed, 'twister');
U = rand(data.nMonteCarlo, 5);
modelCode = double(U(:, 1) >= 0.5); % 0=Gompertz, 1=Logistic
KDraw = 75 + 25 .* sqrt(U(:, 2));  % Triangular(75,100,100)
mcInputs = table((1:data.nMonteCarlo)', U(:,1), U(:,2), U(:,3), U(:,4), U(:,5), ...
    modelCode, KDraw, 'VariableNames', {'draw_id','u_model','u_K','u_coverage', ...
    'u_adherence','u_effect','model_code','K'});

years = data.analysisYears;
nYears = numel(years);
population = data.population.population_18plus_persons(:)';
primaryRate = baselineBurden.primary_rate_percent(:)';
primaryRates = repmat(primaryRate, data.nMonteCarlo, 1);

jointRates = zeros(data.nMonteCarlo, nYears);
for j = 1:nYears
    logicalRows = baselineGrid.model == "Logistic" & baselineGrid.year == years(j);
    gompertzRows = baselineGrid.model == "Gompertz" & baselineGrid.year == years(j);
    logisticPart = sortrows(baselineGrid(logicalRows, :), 'K');
    gompertzPart = sortrows(baselineGrid(gompertzRows, :), 'K');
    logisticRate = interp1(logisticPart.K, logisticPart.rate_percent, KDraw, 'linear');
    gompertzRate = interp1(gompertzPart.K, gompertzPart.rate_percent, KDraw, 'linear');
    jointRates(:, j) = gompertzRate;
    jointRates(modelCode == 1, j) = logisticRate(modelCode == 1);
end

scopeNames = ["policy_only_primary"; "joint_structure_policy"];
scenarioNames = ["low"; "medium"; "high"];
nSummary = numel(scopeNames) * numel(scenarioNames) * nYears;
scope = strings(nSummary, 1);
scenario = strings(nSummary, 1);
year = zeros(nSummary, 1);
values = zeros(nSummary, 9);
row = 0;

sensitivityRows = cell(0, 8);
for sc = 1:numel(scopeNames)
    if sc == 1
        rateMatrix = primaryRates;
    else
        rateMatrix = jointRates;
    end
    baselineMatrix = rateMatrix ./ 100 .* population;

    for s = 1:numel(scenarioNames)
        name = scenarioNames(s);
        params = data.scenarios(data.scenarios.scenario == name, :);
        cRow = params(params.parameter == "coverage", :);
        aRow = params(params.parameter == "adherence", :);
        eRow = params(params.parameter == "effect", :);
        cDraw = q4_triangular_inverse(U(:,3), cRow.lower, cRow.mode, cRow.upper);
        aDraw = q4_triangular_inverse(U(:,4), aRow.lower, aRow.mode, aRow.upper);
        eDraw = q4_triangular_inverse(U(:,5), eRow.lower, eRow.mode, eRow.upper);

        for j = 1:nYears
            growth = min(max((years(j) - 2024) / 6, 0), 1);
            reduction = growth .* cDraw .* aDraw .* eDraw;
            b0 = baselineMatrix(:, j);
            bs = b0 .* (1 - reduction);
            avoided = b0 - bs;
            q0 = prctile(b0, [5 50 95]);
            qs = prctile(bs, [5 50 95]);
            qa = prctile(avoided, [5 50 95]);

            row = row + 1;
            scope(row) = scopeNames(sc);
            scenario(row) = name;
            year(row) = years(j);
            values(row, :) = [q0, qs, qa];

            if sc == 2 && any(years(j) == [2030 2050])
                X = [modelCode, KDraw, cDraw, aDraw, eDraw];
                parameterNames = ["model_code","K","coverage","adherence","effect"];
                outcomeNames = ["scenario_burden","avoidable_burden"];
                outcomeValues = {bs, avoided};
                for o = 1:2
                    rho = zeros(5, 1);
                    for p = 1:5
                        rho(p) = q4_spearman(X(:,p), outcomeValues{o});
                    end
                    [~, order] = sort(abs(rho), 'descend');
                    ranks = zeros(5,1);
                    ranks(order) = (1:5)';
                    for p = 1:5
                        sensitivityRows(end+1, :) = {char(name), years(j), ...
                            char(outcomeNames(o)), char(parameterNames(p)), rho(p), ...
                            abs(rho(p)), ranks(p), 'joint_structure_policy'}; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

summary = table(scope, scenario, year, values(:,1), values(:,2), values(:,3), ...
    values(:,4), values(:,5), values(:,6), values(:,7), values(:,8), values(:,9), ...
    'VariableNames', {'scope','scenario','year','baseline_p05','baseline_p50','baseline_p95', ...
    'scenario_p05','scenario_p50','scenario_p95','avoidable_p05','avoidable_p50','avoidable_p95'});
sensitivity = cell2table(sensitivityRows, 'VariableNames', ...
    {'scenario','year','outcome','parameter','spearman_rho','abs_spearman_rho','rank','scope'});
sensitivity.scenario = string(sensitivity.scenario);
sensitivity.outcome = string(sensitivity.outcome);
sensitivity.parameter = string(sensitivity.parameter);
sensitivity.scope = string(sensitivity.scope);
end

function x = q4_triangular_inverse(u, lower, modeValue, upper)
if lower == upper
    x = repmat(lower, size(u));
    return;
end
split = (modeValue - lower) / (upper - lower);
x = zeros(size(u));
left = u <= split;
x(left) = lower + sqrt(u(left) .* (upper - lower) .* (modeValue - lower));
x(~left) = upper - sqrt((1 - u(~left)) .* (upper - lower) .* (upper - modeValue));
end

function rho = q4_spearman(x, y)
rx = q4_average_ranks(x);
ry = q4_average_ranks(y);
matrix = corrcoef(rx, ry);
rho = matrix(1, 2);
end

function ranks = q4_average_ranks(values)
[sortedValues, order] = sort(values(:));
n = numel(values);
sortedRanks = zeros(n, 1);
i = 1;
while i <= n
    j = i;
    while j < n && sortedValues(j + 1) == sortedValues(i)
        j = j + 1;
    end
    sortedRanks(i:j) = (i + j) / 2;
    i = j + 1;
end
ranks = zeros(n, 1);
ranks(order) = sortedRanks;
end


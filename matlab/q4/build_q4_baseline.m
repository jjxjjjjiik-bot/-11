function [baselineGrid, baselineBurden] = build_q4_baseline(data)
% BUILD_Q4_BASELINE  重新拟合Q1模型并构造年度人口负担。

years = data.analysisYears;
KValues = data.KValues;
nRows = 2 * numel(KValues) * numel(years);

model = strings(nRows, 1);
KColumn = zeros(nRows, 1);
yearColumn = zeros(nRows, 1);
param1 = zeros(nRows, 1);
param2 = zeros(nRows, 1);
ratePercent = zeros(nRows, 1);

row = 0;
for k = 1:numel(KValues)
    K = KValues(k);
    [r, t0] = logistic_fit(data.q1Years, data.q1Rates, K);
    logisticRate = K ./ (1 + exp(-r .* (years - t0)));
    for j = 1:numel(years)
        row = row + 1;
        model(row) = "Logistic";
        KColumn(row) = K;
        yearColumn(row) = years(j);
        param1(row) = r;
        param2(row) = t0;
        ratePercent(row) = logisticRate(j);
    end

    [a, b] = gompertz_fit(data.q1Years, data.q1Rates, K);
    gompertzRate = K .* exp(-a .* exp(-b .* (years - 1992)));
    for j = 1:numel(years)
        row = row + 1;
        model(row) = "Gompertz";
        KColumn(row) = K;
        yearColumn(row) = years(j);
        param1(row) = a;
        param2(row) = b;
        ratePercent(row) = gompertzRate(j);
    end
end

baselineGrid = table(model, KColumn, yearColumn, param1, param2, ratePercent, ...
    'VariableNames', {'model','K','year','param1','param2','rate_percent'});
baselineGrid = sortrows(baselineGrid, {'model','K','year'});

population = data.population.population_18plus_persons;
primaryRate = zeros(numel(years), 1);
robustRate = zeros(numel(years), 1);
structureLowerRate = zeros(numel(years), 1);
structureUpperRate = zeros(numel(years), 1);
for j = 1:numel(years)
    yearRows = baselineGrid.year == years(j);
    rates = baselineGrid.rate_percent(yearRows);
    primaryRate(j) = baselineGrid.rate_percent( ...
        baselineGrid.model == "Logistic" & baselineGrid.K == 100 & baselineGrid.year == years(j));
    robustRate(j) = baselineGrid.rate_percent( ...
        baselineGrid.model == "Gompertz" & baselineGrid.K == 100 & baselineGrid.year == years(j));
    structureLowerRate(j) = min(rates);
    structureUpperRate(j) = max(rates);
end

primaryBurden = population .* primaryRate ./ 100;
robustBurden = population .* robustRate ./ 100;
structureLowerBurden = population .* structureLowerRate ./ 100;
structureUpperBurden = population .* structureUpperRate ./ 100;

baselineBurden = table(years, population, primaryRate, robustRate, ...
    structureLowerRate, structureUpperRate, primaryBurden, robustBurden, ...
    structureLowerBurden, structureUpperBurden, ...
    'VariableNames', {'year','population_18plus_persons','primary_rate_percent', ...
    'robust_rate_percent','structure_lower_rate_percent','structure_upper_rate_percent', ...
    'primary_burden_persons','robust_burden_persons', ...
    'structure_lower_burden_persons','structure_upper_burden_persons'});
end


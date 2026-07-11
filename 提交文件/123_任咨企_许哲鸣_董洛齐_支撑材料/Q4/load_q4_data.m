function data = load_q4_data(rootDir)
% LOAD_Q4_DATA  读取并校验问题四输入数据。

dataDir = fileparts(mfilename('fullpath'));
populationPath = fullfile(dataDir, 'q4_population_projection.csv');
scenarioPath = fullfile(dataDir, 'q4_scenario_parameters.csv');

if ~isfile(populationPath)
    error('缺少人口输入：%s', populationPath);
end
if ~isfile(scenarioPath)
    error('缺少情景参数：%s', scenarioPath);
end

population = readtable(populationPath, 'TextType', 'string');
scenarios = readtable(scenarioPath, 'TextType', 'string');

expectedYears = (2024:2050)';
if ~isequal(population.year, expectedYears)
    error('人口年份必须连续覆盖2024--2050年。');
end
if any(~isfinite(population.population_18plus_persons)) || ...
        any(population.population_18plus_persons <= 0)
    error('18岁及以上人口必须为有限正数。');
end
if any(population.population_18plus_persons > population.total_population_persons)
    error('18岁及以上人口不能超过总人口。');
end

expectedScenarios = ["low"; "medium"; "high"];
expectedParameters = ["coverage"; "adherence"; "effect"];
for i = 1:numel(expectedScenarios)
    group = scenarios(scenarios.scenario == expectedScenarios(i), :);
    if height(group) ~= 3 || ~all(ismember(expectedParameters, group.parameter))
        error('情景 %s 必须包含coverage、adherence和effect。', expectedScenarios(i));
    end
end
if any(scenarios.lower < 0 | scenarios.lower > scenarios.mode | ...
        scenarios.mode > scenarios.upper | scenarios.upper > 1)
    error('三角分布参数必须满足0<=lower<=mode<=upper<=1。');
end

data = struct();
data.rootDir = rootDir;
data.population = population;
data.scenarios = scenarios;
data.q1Years = [1992; 2002; 2012; 2020; 2023];
data.q1Rates = [20.0; 29.9; 42.0; 50.7; 57.0];
data.analysisYears = expectedYears;
data.KValues = (75:5:100)';
data.seed = 20260711;
data.nMonteCarlo = 50000;
end


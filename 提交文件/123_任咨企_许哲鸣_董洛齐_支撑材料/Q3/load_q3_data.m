function data = load_q3_data(rootDir)
% LOAD_Q3_DATA  读取问题三参数表和来源表。

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

sourceDir = fileparts(mfilename('fullpath'));
parameterPath = fullfile(sourceDir, 'q3_parameter_table.csv');
manifestPath = fullfile(sourceDir, 'q3_source_manifest.csv');
scoringRulePath = fullfile(sourceDir, 'q3_scoring_rules.csv');

if ~exist(parameterPath, 'file')
    error('找不到参数表：%s', parameterPath);
end
if ~exist(manifestPath, 'file')
    error('找不到来源清单：%s', manifestPath);
end
if ~exist(scoringRulePath, 'file')
    error('找不到评分规则表：%s', scoringRulePath);
end

parameters = readtable(parameterPath, 'TextType', 'string', 'Encoding', 'UTF-8');
manifest = readtable(manifestPath, 'TextType', 'string', 'Encoding', 'UTF-8');
scoringOptions = delimitedTextImportOptions( ...
    'NumVariables', 6, 'Encoding', 'UTF-8');
scoringOptions.DataLines = [2, Inf];
scoringOptions.Delimiter = ',';
scoringOptions.VariableNames = { ...
    'rule_group','indicator','level_or_case', ...
    'score_or_value','model_application','notes'};
scoringOptions.VariableTypes = repmat({'string'}, 1, 6);
scoringOptions.ExtraColumnsRule = 'ignore';
scoringOptions.EmptyLineRule = 'read';
scoringRules = readtable(scoringRulePath, scoringOptions);

requiredParamCols = ["parameter_id","value","unit","source_id","model_field"];
for i = 1:numel(requiredParamCols)
    if ~ismember(requiredParamCols(i), string(parameters.Properties.VariableNames))
        error('参数表缺少列：%s', requiredParamCols(i));
    end
end

paramMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:height(parameters)
    pid = char(parameters.parameter_id(i));
    rawValue = parameters.value(i);
    if isnumeric(rawValue)
        numericValue = double(rawValue);
    else
        numericValue = str2double(string(rawValue));
    end
    if ~isnan(numericValue)
        paramMap(pid) = numericValue;
    end
end

data = struct();
data.sourceDir = sourceDir;
data.parameters = parameters;
data.manifest = manifest;
data.scoringRules = scoringRules;
data.paramMap = paramMap;
end

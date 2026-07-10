function data = load_q2_data(rootDir)
%LOAD_Q2_DATA Read and validate the Q2 input CSV files.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
end

factorFile = fullfile(rootDir, 'q2_factor_evidence.csv');
supportFile = fullfile(rootDir, 'q2_supporting_evidence.csv');
sourceFile = fullfile(rootDir, 'q2_source_manifest.csv');
exclusionFile = fullfile(rootDir, 'q2_exclusion_log.csv');

requiredFiles = {factorFile, supportFile, sourceFile, exclusionFile};
for i = 1:numel(requiredFiles)
    if ~exist(requiredFiles{i}, 'file')
        error('Q2:MissingFile', 'Missing required input: %s', requiredFiles{i});
    end
end

factor = readtable(factorFile);
requiredColumns = {'factor_id', 'factor_cn', 'factor_en', 'category', ...
    'n_studies', 'positive_pct', 'null_pct', 'negative_pct', ...
    'measurement_count', 'support_count', 'consistency', ...
    'evidence_level', 'evidence_code', 'source_table', ...
    'original_row_name', 'notes'};
for i = 1:numel(requiredColumns)
    if ~ismember(requiredColumns{i}, factor.Properties.VariableNames)
        error('Q2:MissingColumn', 'Missing factor column: %s', requiredColumns{i});
    end
end

data.factor_table = factor;
data.supporting_table = readtable(supportFile);
data.source_table = readtable(sourceFile);
data.exclusion_table = readtable(exclusionFile);
data.factor_id = as_cellstr(factor.factor_id);
data.factor_cn = as_cellstr(factor.factor_cn);
data.factor_en = as_cellstr(factor.factor_en);
data.category = as_cellstr(factor.category);
data.evidence_level = as_cellstr(factor.evidence_level);
data.source_location = as_cellstr(factor.source_table);
data.original_row_name = as_cellstr(factor.original_row_name);
data.notes = as_cellstr(factor.notes);
data.n_studies = double(factor.n_studies);
data.positive_pct = double(factor.positive_pct);
data.null_pct = double(factor.null_pct);
data.negative_pct = double(factor.negative_pct);
data.measurement_count = double(factor.measurement_count);
data.support_count = double(factor.support_count);
data.consistency = double(factor.consistency);
data.evidence_code = double(factor.evidence_code);
data.count = height(factor);
data.baseline_matrix = [data.n_studies, data.consistency, data.evidence_code];
data.root_dir = rootDir;
end


function values = as_cellstr(column)
if iscell(column)
    values = column;
elseif isstring(column)
    values = cellstr(column);
elseif iscategorical(column)
    values = cellstr(column);
else
    values = cellstr(num2str(column));
end
values = values(:);
end

function results = sensitivity_analysis(T, Y)
% SENSITIVITY_ANALYSIS  改变饱和上限K时重新拟合其余参数。

K_values = (75:5:100)';
nK = numel(K_values);
model_name = cell(2 * nK, 1);
K_column = zeros(2 * nK, 1);
param1_value = zeros(2 * nK, 1);
param2_value = zeros(2 * nK, 1);
prediction_2030 = zeros(2 * nK, 1);
prediction_2050 = zeros(2 * nK, 1);
rmse = zeros(2 * nK, 1);
loo_rmse = zeros(2 * nK, 1);

row = 0;
for k = 1:nK
    K = K_values(k);
    for model_idx = 1:2
        row = row + 1;
        K_column(row) = K;
        if model_idx == 1
            [p1, p2, fitted] = logistic_fit(T, Y, K);
            prediction_2030(row) = K / (1 + exp(-p1 * (2030 - p2)));
            prediction_2050(row) = K / (1 + exp(-p1 * (2050 - p2)));
            model_name{row} = 'Logistic';
        else
            [p1, p2, fitted] = gompertz_fit(T, Y, K);
            prediction_2030(row) = K * exp(-p1 * exp(-p2 * (2030 - 1992)));
            prediction_2050(row) = K * exp(-p1 * exp(-p2 * (2050 - 1992)));
            model_name{row} = 'Gompertz';
        end
        param1_value(row) = p1;
        param2_value(row) = p2;
        rmse(row) = sqrt(mean((Y - fitted) .^ 2));
        [~, loo_summary] = leave_one_out_cv(T, Y, K);
        summary_row = strcmp(loo_summary.model, model_name{row});
        loo_rmse(row) = loo_summary.loo_rmse(summary_row);
    end
end

results = table(K_column, model_name, param1_value, param2_value, ...
    prediction_2030, prediction_2050, rmse, loo_rmse, ...
    'VariableNames', {'K', 'model', 'param1_value', 'param2_value', ...
    'prediction_2030', 'prediction_2050', 'rmse', 'loo_rmse'});
end

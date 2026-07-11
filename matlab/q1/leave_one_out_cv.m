function [details, summary] = leave_one_out_cv(T, Y, K)
% LEAVE_ONE_OUT_CV  每次用4个观测点重新拟合并预测被留出的点。

n = numel(Y);
model_name = cell(2 * n, 1);
held_out_year = zeros(2 * n, 1);
observed = zeros(2 * n, 1);
predicted = zeros(2 * n, 1);
error_value = zeros(2 * n, 1);

row = 0;
for model_idx = 1:2
    for i = 1:n
        train = true(1, n);
        train(i) = false;
        if model_idx == 1
            [r, t0] = logistic_fit(T(train), Y(train), K);
            prediction = K / (1 + exp(-r * (T(i) - t0)));
            name = 'Logistic';
        else
            [a, b] = gompertz_fit(T(train), Y(train), K);
            prediction = K * exp(-a * exp(-b * (T(i) - 1992)));
            name = 'Gompertz';
        end
        row = row + 1;
        model_name{row} = name;
        held_out_year(row) = T(i);
        observed(row) = Y(i);
        predicted(row) = prediction;
        error_value(row) = Y(i) - prediction;
    end
end

details = table(model_name, held_out_year, observed, predicted, error_value, ...
    'VariableNames', {'model', 'held_out_year', 'observed', 'predicted', 'error'});

summary_model = {'Logistic'; 'Gompertz'};
loo_rmse = zeros(2, 1);
loo_mape = zeros(2, 1);
for model_idx = 1:2
    rows = strcmp(details.model, summary_model{model_idx});
    errors = details.error(rows);
    values = details.observed(rows);
    loo_rmse(model_idx) = sqrt(mean(errors .^ 2));
    loo_mape(model_idx) = mean(abs(errors ./ values)) * 100;
end
summary = table(summary_model, loo_rmse, loo_mape, ...
    'VariableNames', {'model', 'loo_rmse', 'loo_mape'});
end

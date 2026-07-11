function results = rolling_origin_validation(T, Y, K)
% ROLLING_ORIGIN_VALIDATION  只用目标年份之前的观测拟合并向前预测。

model_name = cell(4, 1);
target_year = zeros(4, 1);
training_end_year = zeros(4, 1);
observed = zeros(4, 1);
predicted = zeros(4, 1);
error_value = zeros(4, 1);

row = 0;
for model_idx = 1:2
    for target_idx = 4:5
        row = row + 1;
        train = 1:(target_idx - 1);
        if model_idx == 1
            [r, t0] = logistic_fit(T(train), Y(train), K);
            prediction = K / (1 + exp(-r * (T(target_idx) - t0)));
            name = 'Logistic';
        else
            [a, b] = gompertz_fit(T(train), Y(train), K);
            prediction = K * exp(-a * exp(-b * (T(target_idx) - 1992)));
            name = 'Gompertz';
        end
        model_name{row} = name;
        target_year(row) = T(target_idx);
        training_end_year(row) = T(target_idx - 1);
        observed(row) = Y(target_idx);
        predicted(row) = prediction;
        error_value(row) = Y(target_idx) - prediction;
    end
end

results = table(model_name, target_year, training_end_year, observed, ...
    predicted, error_value, 'VariableNames', {'model', 'target_year', ...
    'training_end_year', 'observed', 'predicted', 'error'});
end

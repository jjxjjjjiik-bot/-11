function [r, t0, y_fit] = logistic_fit(T, Y, K)
% LOGISTIC_FIT  拟合固定物理上限K的两参数Logistic模型。

model = @(p, t) K ./ (1 + exp(-p(1) .* (t - p(2))));
params0 = [0.05, 2018];
lb = [0.001, 1950];
ub = [0.5, 2100];

options = optimoptions('lsqcurvefit', ...
    'Display', 'off', ...
    'MaxFunctionEvaluations', 10000, ...
    'MaxIterations', 5000, ...
    'FunctionTolerance', 1e-12, ...
    'StepTolerance', 1e-12, ...
    'OptimalityTolerance', 1e-12);

params = lsqcurvefit(model, params0, T, Y, lb, ub, options);
r = params(1);
t0 = params(2);
y_fit = model(params, T);
end

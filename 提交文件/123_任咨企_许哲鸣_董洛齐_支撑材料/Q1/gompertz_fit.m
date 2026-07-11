function [a, b, y_fit] = gompertz_fit(T, Y, K)
% GOMPERTZ_FIT  拟合固定物理上限K的两参数Gompertz模型。

t_ref = 1992;
model = @(p, t) K .* exp(-p(1) .* exp(-p(2) .* (t - t_ref)));
params0 = [1.5, 0.03];
lb = [0.001, 0.001];
ub = [10, 0.5];

options = optimoptions('lsqcurvefit', ...
    'Display', 'off', ...
    'MaxFunctionEvaluations', 10000, ...
    'MaxIterations', 5000, ...
    'FunctionTolerance', 1e-12, ...
    'StepTolerance', 1e-12, ...
    'OptimalityTolerance', 1e-12);

params = lsqcurvefit(model, params0, T, Y, lb, ub, options);
a = params(1);
b = params(2);
y_fit = model(params, T);
end

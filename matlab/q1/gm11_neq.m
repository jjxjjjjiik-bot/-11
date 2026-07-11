function [a, u, y_fit, T_full, y_pred_full] = gm11_neq(T, Y)
% GM11_NEQ  非等间距灰色预测 GM(1,1) 模型
% 输入: T - 年份向量(1xn), Y - 原始数据向量(1xn)
% 输出: a - 发展系数, u - 灰作用量
%        y_fit - 历史拟合值(1xn), T_full - 完整时间轴(含外推)
%        y_pred_full - 完整预测值(拟合+外推)

n   = length(Y);
dt  = diff(T);

%% Step 1: 变步长一次累加生成（AGO）
x1 = zeros(1, n);
x1(1) = Y(1) * dt(1);
for k = 2:n
    x1(k) = x1(k-1) + Y(k) * dt(k-1);
end

%% Step 2: 背景值（邻均值生成）
z1 = 0.5 * x1(1:end-1) + 0.5 * x1(2:end);

%% Step 3: 构造数据矩阵 B 和向量 Y_n
B   = [-z1(:), ones(n-1, 1)];
Y_n = Y(2:end)';

%% Step 4: 最小二乘估计
params = (B' * B) \ (B' * Y_n);
a = params(1);
u = params(2);

%% Step 5: 时间响应函数
c = x1(1) - u / a;

x1_hat = zeros(1, n);
for k = 1:n
    x1_hat(k) = c * exp(-a * (T(k) - T(1))) + u / a;
end

%% Step 6: 还原拟合值
y_fit = zeros(1, n);
y_fit(1) = Y(1);
for k = 2:n
    y_fit(k) = (x1_hat(k) - x1_hat(k-1)) / dt(k-1);
end

%% Step 7: 外推预测（2024-2055）
T_ext     = T(end)+1 : 1 : 2055;
n_ext     = length(T_ext);
x1_ext    = zeros(1, n_ext);
dt_last   = dt(end);

for k = 1:n_ext
    x1_ext(k) = c * exp(-a * (T_ext(k) - T(1))) + u / a;
end

y_ext = zeros(1, n_ext);
y_ext(1) = (x1_ext(1) - x1_hat(end)) / dt_last;
for k = 2:n_ext
    y_ext(k) = (x1_ext(k) - x1_ext(k-1)) / dt_last;
end

%% 合并
T_full      = [T, T_ext];
y_pred_full = [y_fit, y_ext];

%% 打印关键预测值
fprintf('GM(1,1) 外推预测:\n');
for yr = [2025, 2030, 2040, 2050]
    idx = find(T_full == yr);
    if ~isempty(idx)
        fprintf('  %d年: %.2f%%\n', yr, y_pred_full(idx));
    end
end

end
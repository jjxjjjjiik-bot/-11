%% 问题一：五点稀疏数据下的成人超重肥胖率预测
clc; clear; close all;

if ~exist('lsqcurvefit', 'file')
    error('问题一需要 Optimization Toolbox 中的 lsqcurvefit。');
end

script_dir = fileparts(mfilename('fullpath'));
output_dir = fullfile(script_dir, 'output');
figure_dir = fullfile(script_dir, '..', '..', 'figures', 'q1');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
if ~exist(figure_dir, 'dir'), mkdir(figure_dir); end

T = [1992, 2002, 2012, 2020, 2023];
Y = [20.0, 29.9, 42.0, 50.7, 57.0];
K = 100.0;
future_years = [2025, 2030, 2035, 2040, 2045, 2050];

[r_log, t0_log, fit_log] = logistic_fit(T, Y, K);
[a_gom, b_gom, fit_gom] = gompertz_fit(T, Y, K);

pred_log = K ./ (1 + exp(-r_log .* (future_years - t0_log)));
pred_gom = K .* exp(-a_gom .* exp(-b_gom .* (future_years - 1992)));

[rmse_log, mape_log, r2_log] = fit_metrics(Y, fit_log);
[rmse_gom, mape_gom, r2_gom] = fit_metrics(Y, fit_gom);
[loo_details, loo_summary] = leave_one_out_cv(T, Y, K);
[rolling_validation] = rolling_origin_validation(T, Y, K);

log_row = strcmp(loo_summary.model, 'Logistic');
gom_row = strcmp(loo_summary.model, 'Gompertz');
model = {'Logistic'; 'Gompertz'};
K_col = [K; K];
param1_name = {'r'; 'a'};
param1_value = [r_log; a_gom];
param2_name = {'t0'; 'b'};
param2_value = [t0_log; b_gom];
rmse = [rmse_log; rmse_gom];
mape = [mape_log; mape_gom];
r2 = [r2_log; r2_gom];
loo_rmse = [loo_summary.loo_rmse(log_row); loo_summary.loo_rmse(gom_row)];
loo_mape = [loo_summary.loo_mape(log_row); loo_summary.loo_mape(gom_row)];
rolling_rmse = zeros(2, 1);
rolling_mape = zeros(2, 1);
for model_idx = 1:2
    rolling_rows = strcmp(rolling_validation.model, model{model_idx});
    rolling_errors = rolling_validation.error(rolling_rows);
    rolling_observed = rolling_validation.observed(rolling_rows);
    rolling_rmse(model_idx) = sqrt(mean(rolling_errors .^ 2));
    rolling_mape(model_idx) = mean(abs(rolling_errors ./ rolling_observed)) * 100;
end
model_results = table(model, K_col, param1_name, param1_value, ...
    param2_name, param2_value, rmse, mape, r2, loo_rmse, loo_mape, ...
    rolling_rmse, rolling_mape, ...
    'VariableNames', {'model', 'K', 'param1_name', 'param1_value', ...
    'param2_name', 'param2_value', 'rmse', 'mape', 'r2', 'loo_rmse', ...
    'loo_mape', 'rolling_rmse', 'rolling_mape'});

year = future_years';
logistic = pred_log';
gompertz = pred_gom';
model_lower = min([logistic, gompertz], [], 2);
model_upper = max([logistic, gompertz], [], 2);
predictions = table(year, logistic, gompertz, model_lower, model_upper);
sensitivity = sensitivity_analysis(T, Y);

check_id = {'Q1_DATA_COUNT'; 'Q1_YEAR_ORDER'; 'Q1_RATE_RANGE'; ...
    'Q1_FIXED_CAPACITY'; 'Q1_POSITIVE_GROWTH'; 'Q1_MONOTONIC_FORECAST'; ...
    'Q1_FORECAST_RANGE'; 'Q1_LOO_FINITE'; 'Q1_ROLLING_FINITE'; ...
    'Q1_SENSITIVITY_ROWS'};
passed = [numel(Y) == 5; all(diff(T) > 0); all(Y > 0 & Y < 100); ...
    K == 100; all([r_log, a_gom, b_gom] > 0); ...
    all(diff(pred_log) > 0) && all(diff(pred_gom) > 0); ...
    all([pred_log, pred_gom] > 0 & [pred_log, pred_gom] < 100); ...
    all(isfinite([loo_rmse; loo_mape])); ...
    all(isfinite([rolling_rmse; rolling_mape])); height(sensitivity) == 12];
status = repmat({'FAIL'}, numel(check_id), 1);
status(passed) = {'PASS'};
detail = {'固定使用5个已核实观测点'; '年份严格递增'; '观测率位于0到100之间'; ...
    '主分析的物理上限固定为100%'; '增长参数均为正'; '2025至2050预测单调递增'; ...
    '全部预测位于0到100之间'; 'LOO指标均为有限值'; ...
    '滚动起点验证指标均为有限值'; '6个K场景乘2个模型'};
model_checks = table(check_id, status, detail);

writetable(model_results, fullfile(output_dir, 'q1_model_results.csv'));
writetable(predictions, fullfile(output_dir, 'q1_predictions.csv'));
writetable(loo_details, fullfile(output_dir, 'q1_loo_details.csv'));
writetable(rolling_validation, fullfile(output_dir, 'q1_rolling_validation.csv'));
writetable(sensitivity, fullfile(output_dir, 'q1_sensitivity_results.csv'));
writetable(model_checks, fullfile(output_dir, 'q1_model_checks.csv'));

font_name = 'Microsoft YaHei';
T_fine = linspace(T(1), 2050, 500);
curve_log = K ./ (1 + exp(-r_log .* (T_fine - t0_log)));
curve_gom = K .* exp(-a_gom .* exp(-b_gom .* (T_fine - 1992)));

fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 560]);
plot(T_fine, curve_log, 'r-', 'LineWidth', 2); hold on;
plot(T_fine, curve_gom, 'b--', 'LineWidth', 2);
plot(T, Y, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
xline(2023, ':', '预测起点');
xlabel('年份'); ylabel('成人超重肥胖率（%）');
title('两种S形增长模型的拟合与预测');
legend('Logistic', 'Gompertz', '观测数据', 'Location', 'northwest');
grid on; ylim([0, 100]); set(gca, 'FontName', font_name, 'FontSize', 11);
exportgraphics(fig, fullfile(figure_dir, '图1-拟合对比.png'), 'Resolution', 300); close(fig);

fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 560]);
band_x = [future_years, fliplr(future_years)];
band_y = [model_lower', fliplr(model_upper')];
fill(band_x, band_y, [0.85, 0.88, 0.93], 'EdgeColor', 'none', ...
    'DisplayName', '模型结构包络'); hold on;
plot(future_years, pred_log, 'r-o', 'LineWidth', 2, 'DisplayName', 'Logistic');
plot(future_years, pred_gom, 'b-s', 'LineWidth', 2, 'DisplayName', 'Gompertz');
xlabel('年份'); ylabel('成人超重肥胖率（%）');
title('2025--2050年预测及模型结构包络');
legend('Location', 'northwest'); grid on; ylim([50, 90]);
set(gca, 'FontName', font_name, 'FontSize', 11);
exportgraphics(fig, fullfile(figure_dir, '图2-预测曲线.png'), 'Resolution', 300); close(fig);

fig = figure('Visible', 'off', 'Position', [100, 100, 1050, 440]);
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile; bar(T, Y - fit_log, 0.55, 'FaceColor', [0.80, 0.25, 0.22]);
yline(0, 'k-'); title(sprintf('Logistic残差（RMSE=%.3f）', rmse_log));
xlabel('年份'); ylabel('残差（百分点）'); grid on;
xticks(T); xticklabels(string(T)); xtickangle(30);
nexttile; bar(T, Y - fit_gom, 0.55, 'FaceColor', [0.20, 0.42, 0.72]);
yline(0, 'k-'); title(sprintf('Gompertz残差（RMSE=%.3f）', rmse_gom));
xlabel('年份'); ylabel('残差（百分点）'); grid on;
xticks(T); xticklabels(string(T)); xtickangle(30);
set(findall(fig, '-property', 'FontName'), 'FontName', font_name);
set(findall(fig, '-property', 'FontSize'), 'FontSize', 11);
exportgraphics(fig, fullfile(figure_dir, '图3-残差分析.png'), 'Resolution', 300); close(fig);

fig = figure('Visible', 'off', 'Position', [100, 100, 1050, 440]);
tiledlayout(1, 2, 'TileSpacing', 'compact');
for panel = 1:2
    nexttile; hold on;
    target_model = model{panel};
    rows = strcmp(sensitivity.model, target_model);
    plot(sensitivity.K(rows), sensitivity.prediction_2030(rows), '-o', ...
        'LineWidth', 1.8, 'DisplayName', '2030年');
    plot(sensitivity.K(rows), sensitivity.prediction_2050(rows), '-s', ...
        'LineWidth', 1.8, 'DisplayName', '2050年');
    xlabel('设定饱和上限K（%）'); ylabel('预测率（%）');
    title([target_model, '上限敏感性']); legend('Location', 'northwest'); grid on;
end
set(findall(fig, '-property', 'FontName'), 'FontName', font_name);
set(findall(fig, '-property', 'FontSize'), 'FontSize', 11);
exportgraphics(fig, fullfile(figure_dir, '灵敏度分析.png'), 'Resolution', 300); close(fig);

fig = figure('Visible', 'off', 'Position', [100, 100, 900, 420]);
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile; bar(1:2, loo_rmse, 0.55); xticks(1:2); xticklabels(model);
ylabel('LOO-RMSE');
title('留一交叉验证均方根误差'); grid on;
nexttile; bar(1:2, loo_mape, 0.55); xticks(1:2); xticklabels(model);
ylabel('LOO-MAPE（%）');
title('留一交叉验证平均绝对百分比误差'); grid on;
set(findall(fig, '-property', 'FontName'), 'FontName', font_name);
set(findall(fig, '-property', 'FontSize'), 'FontSize', 11);
exportgraphics(fig, fullfile(figure_dir, '留一交叉验证结果对比.png'), 'Resolution', 300); close(fig);

fprintf('问题一正式结果已生成。\n');
disp(model_results);
disp(predictions);
fprintf('Logistic主模型：2030年 %.2f%%，2050年 %.2f%%。\n', pred_log(2), pred_log(6));
fprintf('Gompertz稳健性模型：2030年 %.2f%%，2050年 %.2f%%。\n', pred_gom(2), pred_gom(6));

function [rmse, mape, r2] = fit_metrics(observed, fitted)
residual = observed - fitted;
rmse = sqrt(mean(residual .^ 2));
mape = mean(abs(residual ./ observed)) * 100;
r2 = 1 - sum(residual .^ 2) / sum((observed - mean(observed)) .^ 2);
end

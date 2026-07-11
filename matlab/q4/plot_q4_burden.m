function plot_q4_burden(baselineBurden, figurePath)
% PLOT_Q4_BURDEN  绘制基准预测率与人口负担。

fontName = q4_choose_font();
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [80 60 1500 1050]);
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(layout, 1);
hold(ax1, 'on');
x = baselineBurden.year;
fill(ax1, [x; flipud(x)], [baselineBurden.structure_lower_rate_percent; ...
    flipud(baselineBurden.structure_upper_rate_percent)], [0.78 0.84 0.88], ...
    'FaceAlpha', 0.55, 'EdgeColor', 'none', 'DisplayName', '模型结构与上限范围');
plot(ax1, x, baselineBurden.primary_rate_percent, '-', 'Color', [0.13 0.42 0.62], ...
    'LineWidth', 2.5, 'DisplayName', 'Logistic主模型');
plot(ax1, x, baselineBurden.robust_rate_percent, '--', 'Color', [0.76 0.34 0.20], ...
    'LineWidth', 2.1, 'DisplayName', 'Gompertz稳健性模型');
ylabel(ax1, '成人超重肥胖率（%）', 'FontName', fontName);
title(ax1, '无新增干预基准下的成人超重肥胖率', 'FontName', fontName, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontName', fontName);
grid(ax1, 'on');

ax2 = nexttile(layout, 2);
hold(ax2, 'on');
fill(ax2, [x; flipud(x)], [baselineBurden.structure_lower_burden_persons; ...
    flipud(baselineBurden.structure_upper_burden_persons)] ./ 1e8, [0.78 0.84 0.88], ...
    'FaceAlpha', 0.55, 'EdgeColor', 'none', 'DisplayName', '模型结构与上限范围');
plot(ax2, x, baselineBurden.primary_burden_persons ./ 1e8, '-', ...
    'Color', [0.13 0.42 0.62], 'LineWidth', 2.5, 'DisplayName', '主模型基准人数');
plot(ax2, x, baselineBurden.robust_burden_persons ./ 1e8, '--', ...
    'Color', [0.76 0.34 0.20], 'LineWidth', 2.1, 'DisplayName', '稳健性模型人数');
xlabel(ax2, '年份', 'FontName', fontName);
ylabel(ax2, '成人超重肥胖人数（亿人）', 'FontName', fontName);
title(ax2, '人口变化与患病率共同作用下的基准人数负担', 'FontName', fontName, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontName', fontName);
grid(ax2, 'on');

set([ax1 ax2], 'FontName', fontName, 'FontSize', 12, 'LineWidth', 1);
title(layout, '问题四：2024--2050年成人超重肥胖基准负担', ...
    'FontName', fontName, 'FontSize', 18, 'FontWeight', 'bold');
exportgraphics(fig, figurePath, 'Resolution', 300);
close(fig);
end

function fontName = q4_choose_font()
preferred = {'Microsoft YaHei', 'SimHei', 'SimSun'};
available = listfonts;
fontName = get(groot, 'defaultAxesFontName');
for i = 1:numel(preferred)
    if any(strcmpi(available, preferred{i}))
        fontName = preferred{i}; return;
    end
end
end


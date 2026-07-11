function plot_q4_sensitivity(summary, sensitivity, figurePath)
% PLOT_Q4_SENSITIVITY  绘制中情景不确定性带和2050年敏感性。

fontName = q4_choose_font();
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [70 80 1650 780]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(layout, 1);
group = summary(summary.scope == "joint_structure_policy" & summary.scenario == "medium", :);
hold(ax1, 'on');
fill(ax1, [group.year; flipud(group.year)], ...
    [group.avoidable_p05; flipud(group.avoidable_p95)] ./ 1e7, [0.72 0.82 0.76], ...
    'FaceAlpha', 0.65, 'EdgeColor', 'none', 'DisplayName', '5%--95%模拟分位区间');
plot(ax1, group.year, group.avoidable_p50 ./ 1e7, '-', 'Color', [0.20 0.52 0.35], ...
    'LineWidth', 2.5, 'DisplayName', '模拟中位数');
xlabel(ax1, '年份'); ylabel(ax1, '相对基准可避免人数（千万人）');
title(ax1, '中情景联合模拟区间'); legend(ax1, 'Location', 'northwest'); grid(ax1, 'on');

ax2 = nexttile(layout, 2);
sens = sensitivity(sensitivity.scenario == "medium" & sensitivity.year == 2050 & ...
    sensitivity.outcome == "avoidable_burden", :);
sens = sortrows(sens, 'abs_spearman_rho', 'ascend');
nameMap = containers.Map({'model_code','K','coverage','adherence','effect'}, ...
    {'模型结构','饱和上限K','覆盖率','条件依从率','干预效果'});
labels = cell(height(sens), 1);
for i = 1:height(sens)
    labels{i} = nameMap(char(sens.parameter(i)));
end
barh(ax2, sens.abs_spearman_rho, 0.62, 'FaceColor', [0.76 0.42 0.25]);
ax2.YTick = 1:height(sens); ax2.YTickLabel = labels;
xlabel(ax2, '|Spearman相关系数|'); title(ax2, '2050年中情景可避免人数敏感性');
grid(ax2, 'on');

set([ax1 ax2], 'FontName', fontName, 'FontSize', 12, 'LineWidth', 1);
title(layout, '问题四：联合情景不确定性与参数敏感性', ...
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


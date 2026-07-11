function plot_q4_scenarios(scenarioResults, figurePath)
% PLOT_Q4_SCENARIOS  绘制低、中、高执行强度情景结果。

fontName = q4_choose_font();
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [70 80 1600 780]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
names = ["low","medium","high"];
labels = {'低情景','中情景','高情景'};
colors = [0.35 0.58 0.70; 0.30 0.60 0.43; 0.78 0.38 0.24];

ax1 = nexttile(layout, 1);
hold(ax1, 'on');
base = scenarioResults(scenarioResults.scenario == "low", :);
plot(ax1, base.year, base.baseline_burden_persons ./ 1e8, 'k-', ...
    'LineWidth', 2.5, 'DisplayName', '无新增干预基准');
for i = 1:3
    group = scenarioResults(scenarioResults.scenario == names(i), :);
    plot(ax1, group.year, group.scenario_burden_persons ./ 1e8, '-', ...
        'Color', colors(i,:), 'LineWidth', 2.2, 'DisplayName', labels{i});
end
xlabel(ax1, '年份'); ylabel(ax1, '成人超重肥胖人数（亿人）');
title(ax1, '不同执行强度下的人数负担');
legend(ax1, 'Location', 'northwest'); grid(ax1, 'on');

ax2 = nexttile(layout, 2);
hold(ax2, 'on');
for i = 1:3
    group = scenarioResults(scenarioResults.scenario == names(i), :);
    plot(ax2, group.year, group.avoidable_burden_persons ./ 1e7, '-', ...
        'Color', colors(i,:), 'LineWidth', 2.4, 'DisplayName', labels{i});
end
xlabel(ax2, '年份'); ylabel(ax2, '相对基准可避免人数（千万人）');
title(ax2, '不同执行强度下的相对可避免负担');
legend(ax2, 'Location', 'northwest'); grid(ax2, 'on');

set([ax1 ax2], 'FontName', fontName, 'FontSize', 12, 'LineWidth', 1);
title(layout, '问题四：低、中、高干预执行情景比较（情景假设）', ...
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


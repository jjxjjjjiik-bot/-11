function plot_q2_ranking(data, baseline)
%PLOT_Q2_RANKING Horizontal bar chart of baseline TOPSIS scores.

fontName = choose_q2_chinese_font();
order = display_order(data, baseline.scores);
scores = baseline.scores(order);
labels = data.factor_cn(order);
categories = data.category(order);

palette = containers.Map( ...
    {'饮食因素', '运动因素', '自我监测', '心理因素'}, ...
    {[0.90, 0.47, 0.20], [0.12, 0.55, 0.52], ...
     [0.23, 0.45, 0.75], [0.70, 0.32, 0.55]});
barColors = zeros(data.count, 3);
for i = 1:data.count
    barColors(i, :) = palette(categories{i});
end

fig = figure('Color', 'w', 'Position', [100, 100, 1600, 1000], ...
    'Visible', 'on');
ax = axes('Parent', fig);
b = barh(ax, scores, 0.72, 'FaceColor', 'flat', 'EdgeColor', 'none');
b.CData = barColors;
set(ax, 'YDir', 'reverse', 'YTick', 1:data.count, ...
    'YTickLabel', labels, 'FontName', fontName, 'FontSize', 13, ...
    'Box', 'off', 'TickDir', 'out', 'Color', 'w');
xlabel(ax, 'TOPSIS贴近度（逼近理想解得分）', ...
    'FontName', fontName, 'FontSize', 15);
title(ax, '15项减重维持因素的CRITIC客观赋权-TOPSIS逼近理想解排序', ...
    'FontName', fontName, 'FontSize', 20, 'FontWeight', 'bold');
grid(ax, 'on');
ax.XGrid = 'on';
ax.YGrid = 'off';
xlim(ax, [0, max(scores) * 1.22]);

for i = 1:data.count
    text(ax, scores(i) + max(scores) * 0.012, i, ...
        sprintf('%.3f  (第%d名)', scores(i), baseline.ranks(order(i))), ...
        'FontName', fontName, 'FontSize', 11, 'VerticalAlignment', 'middle');
end

hold(ax, 'on');
h1 = plot(ax, NaN, NaN, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', palette('饮食因素'), 'MarkerEdgeColor', 'none');
h2 = plot(ax, NaN, NaN, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', palette('运动因素'), 'MarkerEdgeColor', 'none');
h3 = plot(ax, NaN, NaN, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', palette('自我监测'), 'MarkerEdgeColor', 'none');
h4 = plot(ax, NaN, NaN, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', palette('心理因素'), 'MarkerEdgeColor', 'none');
legend(ax, [h1, h2, h3, h4], ...
    {'饮食因素', '运动因素', '自我监测', '心理因素'}, ...
    'Location', 'southeast', 'FontName', fontName, 'Box', 'off');

drawnow;
end


function order = display_order(data, scores)
idNumber = zeros(data.count, 1);
for i = 1:data.count
    idNumber(i) = str2double(regexprep(data.factor_id{i}, '[^0-9]', ''));
end
sortMatrix = [-scores(:), -data.n_studies(:), idNumber(:)];
[~, order] = sortrows(sortMatrix, [1, 2, 3]);
end

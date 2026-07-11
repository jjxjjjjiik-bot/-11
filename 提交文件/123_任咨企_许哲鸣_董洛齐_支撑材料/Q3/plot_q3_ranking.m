function plot_q3_ranking(ranking)
% PLOT_Q3_RANKING  分画像展示各自 3 套方案的 TOPSIS 组内得分。

fontName = q3_choose_font();
profileIds = unique(ranking.profile_id, 'stable');

fig = figure('Name', '问题三-各画像候选方案组内得分', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [35 35 1540 900]);
layout = tiledlayout(fig, 3, 2, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

normalColors = [ ...
    0.27 0.49 0.68;
    0.86 0.58 0.24;
    0.48 0.57 0.64];
bestColor = [0.20 0.62 0.38];

for i = 1:numel(profileIds)
    ax = nexttile(layout, i);
    group = ranking(ranking.profile_id == profileIds(i), :);
    group = sortrows(group, 'plan_id', 'ascend');
    scores = group.topsis_score;

    b = barh(ax, 1:height(group), scores, 0.58, 'FaceColor', 'flat');
    b.CData = normalColors;
    [~, bestIndex] = max(scores);
    b.CData(bestIndex, :) = bestColor;

    ax.FontName = fontName;
    ax.FontSize = 10.5;
    ax.YDir = 'reverse';
    ax.YTick = 1:height(group);
    ax.YTickLabel = group.plan_type;
    ax.TickLabelInterpreter = 'none';
    ax.XLim = [0, 1.05];
    ax.XTick = 0:0.2:1;
    ax.GridAlpha = 0.18;
    ax.XGrid = 'on';
    ax.LineWidth = 0.9;
    title(ax, group.profile_name(1), 'FontName', fontName, ...
        'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'none');

    for j = 1:height(group)
        if j == bestIndex
            labelText = sprintf('%.3f  推荐', scores(j));
            labelWeight = 'bold';
        else
            labelText = sprintf('%.3f', scores(j));
            labelWeight = 'normal';
        end

        if scores(j) >= 0.88
            xPosition = scores(j) - 0.018;
            alignment = 'right';
        else
            xPosition = scores(j) + 0.018;
            alignment = 'left';
        end
        text(ax, xPosition, j, labelText, ...
            'HorizontalAlignment', alignment, ...
            'VerticalAlignment', 'middle', ...
            'FontName', fontName, 'FontSize', 10.5, ...
            'FontWeight', labelWeight, 'Interpreter', 'none');
    end
end

ax = nexttile(layout, 6);
axis(ax, 'off');
text(ax, 0.03, 0.68, '图中得分仅用于同一画像内的三方案比较', ...
    'FontName', fontName, 'FontSize', 13, 'FontWeight', 'bold');
text(ax, 0.03, 0.48, '绿色条为该画像的推荐方案', ...
    'FontName', fontName, 'FontSize', 12, 'Color', bestColor);
text(ax, 0.03, 0.28, 'TOPSIS 得分不是减重成功率', ...
    'FontName', fontName, 'FontSize', 12, 'Color', [0.35 0.35 0.35]);

title(layout, '问题三-各画像三套候选方案 TOPSIS 组内得分', ...
    'FontName', fontName, 'FontSize', 18, 'FontWeight', 'bold');
xlabel(layout, 'TOPSIS 相对得分（同一画像内越高越优）', ...
    'FontName', fontName, 'FontSize', 13);
end

function fontName = q3_choose_font()
preferred = {'Microsoft YaHei', 'SimHei', 'SimSun'};
available = listfonts;
fontName = get(groot, 'defaultAxesFontName');
for i = 1:numel(preferred)
    if any(strcmpi(available, preferred{i}))
        fontName = preferred{i};
        return;
    end
end
end

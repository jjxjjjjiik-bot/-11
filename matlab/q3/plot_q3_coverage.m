function plot_q3_coverage(ranking)
% PLOT_Q3_COVERAGE  展示 15 套方案对问题二五项失败因素的覆盖差异。

fontName = q3_choose_font();
coverageCols = {'cover_activity','cover_energy','cover_monitoring', ...
    'cover_unhealthy_food','cover_fruit_veg'};
coverageLabels = {'活动增加', '能量控制', '体重监测', '少甜炸快餐', '增加果蔬'};

ordered = sortrows(ranking, {'profile_id','plan_id'}, {'ascend','ascend'});
matrix = ordered{:, coverageCols};
planLabels = ordered.profile_name + "｜" + ordered.plan_type;

fig = figure('Name', '问题三-15套候选方案失败因素覆盖热图', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [45 35 1480 920]);
ax = axes('Parent', fig, 'Position', [0.31 0.12 0.61 0.80]);
imagesc(ax, matrix);
colormap(ax, [ ...
    0.91 0.92 0.93;
    0.96 0.75 0.30;
    0.12 0.47 0.70]);
caxis(ax, [-0.25, 1.25]);

cb = colorbar(ax);
cb.Ticks = [0, 0.5, 1];
cb.TickLabels = {'未覆盖', '间接覆盖', '直接覆盖'};
cb.FontName = fontName;
cb.FontSize = 11;

ax.FontName = fontName;
ax.FontSize = 10.5;
ax.XTick = 1:numel(coverageLabels);
ax.XTickLabel = coverageLabels;
ax.XTickLabelRotation = 15;
ax.YTick = 1:height(ordered);
ax.YTickLabel = planLabels;
ax.TickLabelInterpreter = 'none';
ax.TickLength = [0 0];
axis(ax, 'tight');

for row = 1:size(matrix, 1)
    for col = 1:size(matrix, 2)
        value = matrix(row, col);
        if value >= 1
            txtColor = 'w';
        else
            txtColor = [0.12 0.12 0.12];
        end
        text(ax, col, row, sprintf('%.1f', value), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontName', fontName, 'FontSize', 10.5, ...
            'FontWeight', 'bold', 'Color', txtColor);
    end
end

yline(ax, [3.5, 6.5, 9.5, 12.5], 'w-', 'LineWidth', 2.2);
title(ax, '问题三-15套候选方案对问题二失败因素的覆盖差异', ...
    'FontName', fontName, 'FontSize', 18, 'FontWeight', 'bold');
xlabel(ax, '问题二前五项失败因素的修正维度', ...
    'FontName', fontName, 'FontSize', 13);
ylabel(ax, '画像及其候选方案', ...
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

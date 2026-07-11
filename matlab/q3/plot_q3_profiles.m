function plot_q3_profiles(profiles)
% PLOT_Q3_PROFILES  生成典型生活方式画像雷达图窗口。

fontName = q3_choose_font();
fig = figure('Name', '问题三-典型生活方式画像雷达图', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [80 80 1120 780]);

labels = {'久坐风险', '睡眠风险', '饮食风险', '压力风险', '时间受限', '监测缺口'};
values = [profiles.sedentary_risk, profiles.sleep_risk, profiles.diet_risk, ...
    profiles.stress_risk, profiles.time_constraint, profiles.monitoring_gap];

angles = linspace(0, 2*pi, numel(labels) + 1);
colors = lines(height(profiles));
polaraxes('Parent', fig);
hold on;

for i = 1:height(profiles)
    r = [values(i, :), values(i, 1)];
    polarplot(angles, r, 'LineWidth', 2.2, 'Color', colors(i, :));
end

ax = gca;
ax.FontName = fontName;
ax.FontSize = 14;
ax.ThetaTick = rad2deg(angles(1:end-1));
ax.ThetaTickLabel = labels;
ax.RLim = [0 100];
ax.RTick = 0:20:100;
ax.LineWidth = 1.1;
title('问题三-典型生活方式画像雷达图', 'FontName', fontName, ...
    'FontSize', 18, 'FontWeight', 'bold');
legend(profiles.profile_name, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
    'FontName', fontName, 'FontSize', 13, 'NumColumns', 3, 'Box', 'off');
hold off;
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

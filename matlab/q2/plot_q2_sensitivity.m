function plot_q2_sensitivity(data, results)
%PLOT_Q2_SENSITIVITY Factor-by-scenario rank heatmap.

fontName = choose_q2_chinese_font();
baseline = results.scenarios(1);
order = display_order(data, baseline.scores);
nScenarios = numel(results.scenarios);
rankMatrix = zeros(data.count, nScenarios);
scenarioNames = cell(1, nScenarios);
for s = 1:nScenarios
    rankMatrix(:, s) = results.scenarios(s).ranks(order);
    scenarioNames{s} = results.scenarios(s).name;
end

fig = figure('Color', 'w', 'Position', [100, 100, 1700, 1050], ...
    'Visible', 'on');
ax = axes('Parent', fig);
imagesc(ax, rankMatrix);
colormap(ax, flipud(parula(15)));
caxis(ax, [1, 15]);
colorbarHandle = colorbar(ax);
ylabel(colorbarHandle, '名次', 'FontName', fontName, 'FontSize', 12);

set(ax, 'XTick', 1:nScenarios, 'XTickLabel', scenarioNames, ...
    'YTick', 1:data.count, 'YTickLabel', data.factor_cn(order), ...
    'FontName', fontName, 'FontSize', 12, 'TickLength', [0, 0], ...
    'Color', 'w');
xtickangle(ax, 22);
xlabel(ax, '灵敏度场景', 'FontName', fontName, 'FontSize', 14);
ylabel(ax, '减重维持因素', 'FontName', fontName, 'FontSize', 14);
title(ax, '六种场景下的因素名次稳健性', ...
    'FontName', fontName, 'FontSize', 20, 'FontWeight', 'bold');

for row = 1:data.count
    for column = 1:nScenarios
        value = rankMatrix(row, column);
        if value >= 10
            textColor = [1, 1, 1];
        else
            textColor = [0.08, 0.08, 0.08];
        end
        text(ax, column, row, sprintf('%d', value), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontName', fontName, 'FontSize', 11, 'FontWeight', 'bold', ...
            'Color', textColor);
    end
end

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

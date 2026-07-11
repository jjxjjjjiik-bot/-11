function rho = spearman_rank(valuesA, valuesB)
%SPEARMAN_RANK Spearman correlation with average ranks for tied values.

rankA = average_tie_ranks(valuesA);
rankB = average_tie_ranks(valuesB);
if std(rankA, 1) <= eps || std(rankB, 1) <= eps
    rho = 0;
    return;
end
matrix = corrcoef(rankA, rankB);
rho = matrix(1, 2);
end


function ranks = average_tie_ranks(values)
values = double(values(:));
n = numel(values);
[sortedValues, order] = sort(values, 'descend');
ranks = zeros(n, 1);
tolerance = 1e-12;
startIndex = 1;

while startIndex <= n
    stopIndex = startIndex;
    while stopIndex < n && ...
            abs(sortedValues(stopIndex + 1) - sortedValues(startIndex)) <= tolerance
        stopIndex = stopIndex + 1;
    end
    averageRank = (startIndex + stopIndex) / 2;
    ranks(order(startIndex:stopIndex)) = averageRank;
    startIndex = stopIndex + 1;
end
end

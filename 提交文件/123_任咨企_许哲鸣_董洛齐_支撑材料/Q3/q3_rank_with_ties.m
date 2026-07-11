function ranks = q3_rank_with_ties(values, tolerance)
% Q3_RANK_WITH_TIES  并列排名。
% values 越小排名越靠前；若差值小于 tolerance，则视为并列。

if nargin < 2 || isempty(tolerance)
    tolerance = 1e-9;
end

n = numel(values);
[sortedValues, order] = sort(values(:), 'ascend');
ranksSorted = zeros(n, 1);

currentRank = 1;
ranksSorted(1) = currentRank;
for i = 2:n
    if abs(sortedValues(i) - sortedValues(i - 1)) > tolerance
        currentRank = i;
    end
    ranksSorted(i) = currentRank;
end

ranks = zeros(n, 1);
ranks(order) = ranksSorted;
end

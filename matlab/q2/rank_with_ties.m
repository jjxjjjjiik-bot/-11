function ranks = rank_with_ties(scores)
%RANK_WITH_TIES Competition ranking: 1, 2, 2, 4.

scores = double(scores(:));
n = numel(scores);
[sortedScores, order] = sort(scores, 'descend');
ranks = zeros(n, 1);
currentRank = 0;
previous = NaN;
tolerance = 1e-12;

for position = 1:n
    if position == 1 || abs(sortedScores(position) - previous) > tolerance
        currentRank = position;
    end
    ranks(order(position)) = currentRank;
    previous = sortedScores(position);
end
end

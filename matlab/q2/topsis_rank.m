function [scores, ranks, details] = topsis_rank(matrix, weights)
%TOPSIS_RANK Compute benefit-type TOPSIS scores and competition ranks.

matrix = double(matrix);
weights = double(weights(:)');
denominators = sqrt(sum(matrix .^ 2, 1));
if any(denominators <= eps)
    error('Q2:ZeroCriterion', 'TOPSIS encountered a zero criterion column.');
end

normalized = bsxfun(@rdivide, matrix, denominators);
weighted = bsxfun(@times, normalized, weights);
positiveIdeal = max(weighted, [], 1);
negativeIdeal = min(weighted, [], 1);
distancePositive = sqrt(sum(bsxfun(@minus, weighted, positiveIdeal) .^ 2, 2));
distanceNegative = sqrt(sum(bsxfun(@minus, weighted, negativeIdeal) .^ 2, 2));
distanceTotal = distancePositive + distanceNegative;

scores = zeros(size(distanceTotal));
valid = distanceTotal > eps;
scores(valid) = distanceNegative(valid) ./ distanceTotal(valid);
ranks = rank_with_ties(scores);

details.normalized = normalized;
details.weighted = weighted;
details.positive_ideal = positiveIdeal;
details.negative_ideal = negativeIdeal;
details.distance_positive = distancePositive;
details.distance_negative = distanceNegative;
end

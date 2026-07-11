function [score, detail] = q3_topsis_rank(X, weights, criteriaType)
% Q3_TOPSIS_RANK  TOPSIS 综合评价。
% X: 行为方案，列为指标。
% criteriaType: 1 表示收益型，-1 表示成本型。

if isempty(X)
    error('TOPSIS 输入矩阵为空。');
end
if size(X, 2) ~= numel(weights) || size(X, 2) ~= numel(criteriaType)
    error('TOPSIS 指标数量、权重数量和属性数量不一致。');
end

weights = weights(:)';
weights = weights ./ sum(weights);
criteriaType = criteriaType(:)';

normFactor = sqrt(sum(X .^ 2, 1));
normFactor(normFactor == 0) = 1;
Z = X ./ normFactor;
V = Z .* weights;

idealBest = zeros(1, size(X, 2));
idealWorst = zeros(1, size(X, 2));
for j = 1:size(X, 2)
    if criteriaType(j) == 1
        idealBest(j) = max(V(:, j));
        idealWorst(j) = min(V(:, j));
    elseif criteriaType(j) == -1
        idealBest(j) = min(V(:, j));
        idealWorst(j) = max(V(:, j));
    else
        error('criteriaType 只能取 1 或 -1。');
    end
end

distanceToBest = sqrt(sum((V - idealBest) .^ 2, 2));
distanceToWorst = sqrt(sum((V - idealWorst) .^ 2, 2));
denominator = distanceToBest + distanceToWorst;
score = distanceToWorst ./ denominator;
score(denominator == 0) = 0.5;

detail = struct();
detail.normalized = Z;
detail.weighted = V;
detail.weights = weights;
detail.idealBest = idealBest;
detail.idealWorst = idealWorst;
detail.distanceToBest = distanceToBest;
detail.distanceToWorst = distanceToWorst;
end

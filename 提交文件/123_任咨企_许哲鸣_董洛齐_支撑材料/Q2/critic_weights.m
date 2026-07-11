function [weights, details] = critic_weights(matrix)
%CRITIC_WEIGHTS Compute objective criterion weights with the CRITIC method.

matrix = double(matrix);
minimums = min(matrix, [], 1);
maximums = max(matrix, [], 1);
ranges = maximums - minimums;
if any(ranges <= eps)
    error('Q2:ConstantCriterion', 'CRITIC requires non-constant criteria.');
end

normalized = bsxfun(@rdivide, bsxfun(@minus, matrix, minimums), ranges);
sigma = std(normalized, 1, 1);
correlation = corrcoef(normalized);
if any(isnan(correlation(:)))
    error('Q2:InvalidCorrelation', 'CRITIC correlation matrix contains NaN.');
end

contrast = sum(1 - correlation, 2)';
information = sigma .* contrast;
if sum(information) <= eps
    error('Q2:ZeroInformation', 'CRITIC information content is zero.');
end
weights = information ./ sum(information);

details.normalized = normalized;
details.sigma = sigma;
details.correlation = correlation;
details.information = information;
end

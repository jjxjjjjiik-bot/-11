function lower = wilson_lower_bound(successes, totals)
%WILSON_LOWER_BOUND Wilson 95 percent lower confidence bound.

successes = double(successes);
totals = double(totals);
if any(totals(:) <= 0)
    error('Q2:InvalidWilsonTotal', 'Wilson totals must be positive.');
end
z = 1.959963984540054;
proportion = successes ./ totals;
denominator = 1 + z ^ 2 ./ totals;
center = proportion + z ^ 2 ./ (2 .* totals);
adjustment = z .* sqrt(proportion .* (1 - proportion) ./ totals + ...
    z ^ 2 ./ (4 .* totals .^ 2));
lower = (center - adjustment) ./ denominator;
end

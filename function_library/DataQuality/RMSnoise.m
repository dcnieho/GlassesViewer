function [RMSnoise] = RMSnoise(data)
% compute squared sample to sample difference

% get difference between consecutive data points and square
ssdiff              = (data(2:end) - data(1:end-1)).^2;
% determine number of non-nan differences
n                   = sum(~isnan(ssdiff));
% sum difference and divide by number of instance, and take square root
RMSnoise            = sqrt(sum(ssdiff,'omitnan')/n);
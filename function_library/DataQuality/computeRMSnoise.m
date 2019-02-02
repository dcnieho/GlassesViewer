function [medianRMS] = computeRMSnoise(data,windowLength)
% compute RMS noise for data with moving window technique (with nr. of
% samples specified in 'window')

% get number of sample in data
ns  = length(data);

if windowLength < ns % if number of samples in data exceeds window size
    RMS = nan(1,ns-windowLength); % pre-allocate
    for p=1:ns-windowLength
        RMS(p) = RMSnoise(data(p:p+windowLength));
    end
    medianRMS = nanmedian(RMS);
else % if too few samples in data
    medianRMS = NaN;
end
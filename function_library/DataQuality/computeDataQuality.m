function computeDataQuality(data, windowLengthMs)
% compute data quality measures for eye-tracking data from Tobii Pro
% Glasses 2
% data: data-struct as obtained from TobiiGlassesViewer
% window: length of moving window in which RMS-S2S is calculated (ms)

% convert windows length from duration in ms to number of samples
windowLengthSamp = round(windowLengthMs/1000*data.eye.fs);

% RMS noise
RMSeleL = computeRMSnoise(data.eye.left.ele,windowLengthSamp);
RMSaziL = computeRMSnoise(data.eye.left.azi,windowLengthSamp);
RMSeleR = computeRMSnoise(data.eye.right.ele,windowLengthSamp);
RMSaziR = computeRMSnoise(data.eye.right.azi,windowLengthSamp);

% data loss
DLeleL = sum(isnan(data.eye.left.ele))/length(data.eye.left.ele);
DLaziL = sum(isnan(data.eye.left.azi))/length(data.eye.left.azi);
DLeleR = sum(isnan(data.eye.right.ele))/length(data.eye.right.ele);
DLaziR = sum(isnan(data.eye.right.azi))/length(data.eye.right.azi);

% print DQ values
fprintf(' \n');
fprintf('<strong>Data quality:</strong>\n');
fprintf('-------------------------------------\n');
fprintf('Signal     RMS-S2S (deg)*   Data loss\n');
fprintf('-------------------------------------\n');
fprintf('Left ele       %.2f           %5.2f%%\n',RMSeleL,DLeleL*100);
fprintf('Left azi       %.2f           %5.2f%%\n',RMSaziL,DLaziL*100);
fprintf('Right ele      %.2f           %5.2f%%\n',RMSeleR,DLeleR*100);
fprintf('Right azi      %.2f           %5.2f%%\n',RMSaziR,DLaziR*100);
fprintf('-------------------------------------\n');

% print RMS-S2S details
fprintf('* Median RMS-S2S using %.0fms moving window\n', windowLengthMs);
fprintf(' \n');
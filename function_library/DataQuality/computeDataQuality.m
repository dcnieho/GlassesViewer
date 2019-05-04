function quality = computeDataQuality(recordingDir, data, windowLengthMs)
% compute data quality measures for eye-tracking data from Tobii Pro
% Glasses 2
% data: data-struct as obtained from TobiiGlassesViewer
% window: length of moving window in which RMS-S2S is calculated (ms)

% set file format version. cache files older than this are overwritten with
% a newly generated cache file
fileVersion = 1;

qGenCacheFile = ~exist(fullfile(recordingDir,'dataquality.mat'),'file');
if ~qGenCacheFile
    % we have a cache file, check its file version and windowLength
    cache = load(fullfile(recordingDir,'dataquality.mat'),'fileVersion','windowMs');
    qGenCacheFile = cache.fileVersion~=fileVersion || cache.windowMs~=windowLengthMs;
end

if qGenCacheFile
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
    
    % prep output
    quality.RMSS2S  .azi = [RMSaziL RMSaziR];
    quality.RMSS2S  .ele = [RMSeleL RMSeleR];
    quality.dataLoss.azi = [DLaziL DLaziR]*100;
    quality.dataLoss.ele = [DLeleL DLeleR]*100;
    quality.windowMs     = windowLengthMs;
    quality.fileVersion  = fileVersion;
    
    save(fullfile(recordingDir,'dataquality.mat'),'-struct','quality');
else
    quality = load(fullfile(recordingDir,'dataquality.mat'));
end


% print DQ values
fprintf(' \n');
fprintf('<strong>Data quality:</strong>\n');
fprintf('-------------------------------------\n');
fprintf('Signal     RMS-S2S (deg)*   Data loss\n');
fprintf('-------------------------------------\n');
fprintf('Left azi       %.2f           %5.2f%%\n',quality.RMSS2S.azi(1),quality.dataLoss.azi(1));
fprintf('Left ele       %.2f           %5.2f%%\n',quality.RMSS2S.ele(1),quality.dataLoss.ele(1));
fprintf('Right azi      %.2f           %5.2f%%\n',quality.RMSS2S.azi(2),quality.dataLoss.azi(2));
fprintf('Right ele      %.2f           %5.2f%%\n',quality.RMSS2S.ele(2),quality.dataLoss.ele(2));
fprintf('-------------------------------------\n');

% print RMS-S2S details
fprintf('* Median RMS-S2S using %.0fms moving window\n', quality.windowMs);
fprintf(' \n');
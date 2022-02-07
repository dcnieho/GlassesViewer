function quality = computeDataQuality(recordingDir, data, windowLengthMs, intervalTs)
% compute data quality measures for eye-tracking data from Tobii Pro
% Glasses 2
% data: data-struct as obtained from TobiiGlassesViewer
% window: length of moving window in which RMS-S2S is calculated (ms)

% set file format version. cache files older than this are overwritten with
% a newly generated cache file
fileVersion = 3;

if nargin<4 || isempty(intervalTs)
    intervalTs = [data.time.startTime data.time.endTime];
else
    assert(size(intervalTs,2)==2,'intervalTs, if provided, should be an Mx2 matrix')
end

qGenCacheFile = ~exist(fullfile(recordingDir,'dataquality.mat'),'file');
if ~qGenCacheFile
    % we have a cache file, check its file version and windowLength
    cache = load(fullfile(recordingDir,'dataquality.mat'),'fileVersion','windowMs','intervalTs');
    qGenCacheFile = cache.fileVersion~=fileVersion || cache.windowMs~=windowLengthMs || ~isequal(cache.intervalTs,intervalTs);
end

if qGenCacheFile
    quality.windowMs     = windowLengthMs;
    quality.fileVersion  = fileVersion;
    quality.intervalTs   = intervalTs;
    
    % convert windows length from duration in ms to number of samples
    windowLengthSamp = round(windowLengthMs/1000*data.eye.fs);
    
    for p=size(intervalTs,1):-1:1
        qDatL = data.eye.     left.ts >= intervalTs(p,1) & data.eye.     left.ts <= intervalTs(p,2);
        qDatR = data.eye.    right.ts >= intervalTs(p,1) & data.eye.    right.ts <= intervalTs(p,2);
        qDatB = data.eye.binocular.ts >= intervalTs(p,1) & data.eye.binocular.ts <= intervalTs(p,2);
        
        % RMS noise
        RMSeleL = computeRMSnoise(data.eye.     left.ele(qDatL)  , windowLengthSamp);
        RMSaziL = computeRMSnoise(data.eye.     left.azi(qDatL)  , windowLengthSamp);
        RMSeleR = computeRMSnoise(data.eye.    right.ele(qDatR)  , windowLengthSamp);
        RMSaziR = computeRMSnoise(data.eye.    right.azi(qDatR)  , windowLengthSamp);
        RMSbgpX = computeRMSnoise(data.eye.binocular.gp (qDatB,1), windowLengthSamp);
        RMSbgpY = computeRMSnoise(data.eye.binocular.gp (qDatB,2), windowLengthSamp);
        
        % data loss
        DLaziL = sum(isnan(data.eye.     left.azi(qDatL  )))/sum(qDatL);
        DLeleL = sum(isnan(data.eye.     left.ele(qDatL  )))/sum(qDatL);
        DLaziR = sum(isnan(data.eye.    right.azi(qDatR  )))/sum(qDatR);
        DLeleR = sum(isnan(data.eye.    right.ele(qDatR  )))/sum(qDatR);
        DLbgpX = sum(isnan(data.eye.binocular.gp (qDatB,1)))/sum(qDatB);
        DLbgpY = sum(isnan(data.eye.binocular.gp (qDatB,2)))/sum(qDatB);
        
        % prep output
        quality.interval(p).RMSS2S  .azi = [RMSaziL RMSaziR];
        quality.interval(p).RMSS2S  .ele = [RMSeleL RMSeleR];
        quality.interval(p).RMSS2S  .bgp = [RMSbgpX RMSbgpY];
        quality.interval(p).dataLoss.azi = [DLaziL DLaziR]*100;
        quality.interval(p).dataLoss.ele = [DLeleL DLeleR]*100;
        quality.interval(p).dataLoss.bgp = [DLbgpX DLbgpY]*100;
    end
    
    save(fullfile(recordingDir,'dataquality.mat'),'-struct','quality');
else
    quality = load(fullfile(recordingDir,'dataquality.mat'));
end


% print DQ values
fprintf(' \n');
fprintf('<strong>Data quality:</strong>\n');
fprintf('--------------------------------------\n');
fprintf('Signal            RMS-S2S*   Data loss\n');
fprintf('--------------------------------------\n');
fprintf('Left azi           %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.azi(1),quality.interval(1).dataLoss.azi(1));
fprintf('Left ele           %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.ele(1),quality.interval(1).dataLoss.ele(1));
fprintf('Right azi          %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.azi(2),quality.interval(1).dataLoss.azi(2));
fprintf('Right ele          %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.ele(2),quality.interval(1).dataLoss.ele(2));
fprintf('Gaze point video X %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.bgp(1),quality.interval(1).dataLoss.bgp(1));
fprintf('Gaze point video Y %6.2f      %5.2f%%\n',quality.interval(1).RMSS2S.bgp(2),quality.interval(1).dataLoss.bgp(2));
fprintf('--------------------------------------\n');

% print RMS-S2S details
fprintf('* Median RMS-S2S using %.0fms moving window\n', quality.windowMs);
fprintf('* Unit for azi/ele: deg, gaze point video: pix\n');
fprintf(' \n');

function saveDataQualityToTSV(data,directory,windowLength,fileSuffix,intervalTs)

% Cite as: Niehorster, D.C., Hessels, R.S., and Benjamins, J.S. (2020).
% GlassesViewer: Open-source software for viewing and analyzing data from
% the Tobii Pro Glasses 2 eye tracker. Behavior Research Methods. doi:
% 10.3758/s13428-019-01314-1

if nargin>=4 && ~isempty(fileSuffix)
    fileSuffix = ['_' fileSuffix];
else
    fileSuffix = '';
end

if nargin<5 || isempty(intervalTs)
    intervalTs = [];
end

% compute data quality (empty directory input argument ensures this doesn't
% get written to cache file)
dq = computeDataQuality('', data, windowLength, intervalTs);


% store to file
fname = fullfile(directory,sprintf('dataQuality%s.tsv',fileSuffix));
fid   = fopen(fname,'wt');
fprintf(fid,'interval_index\tRMS_left_azi\tRMS_left_ele\tRMS_right_azi\tRMS_right_ele\tRMS_gaze_point_video_X\tRMS_gaze_point_video_Y\t');
fprintf(fid,'data_loss_left\tdata_loss_right\tdata_loss_gaze_point_video\n');

for p=1:length(dq.interval)
    fprintf(fid,'%.0f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n',p,...
        dq.interval(p).RMSS2S.azi(1),dq.interval(p).RMSS2S.ele(1),...
        dq.interval(p).RMSS2S.azi(2),dq.interval(p).RMSS2S.ele(2),...
        dq.interval(p).RMSS2S.bgp(1),dq.interval(p).RMSS2S.bgp(2),...
        dq.interval(p).dataLoss.azi(1),dq.interval(p).dataLoss.azi(2),dq.interval(p).dataLoss.bgp(1));
end

fclose(fid);
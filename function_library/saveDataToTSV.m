function saveDataToTSV(data,directory,fileSuffix,which)

% Cite as: Niehorster, D.C., Hessels, R.S., and Benjamins, J.S. (2020).
% GlassesViewer: Open-source software for viewing and analyzing data from
% the Tobii Pro Glasses 2 eye tracker. Behavior Research Methods. doi:
% 10.3758/s13428-019-01314-1

allStreams   = {'eye','gyroscope','accelerometer','video','syncPort','syncAPI','time'};
if isfield(data,'user')
    allStreams   = [allStreams fieldnames(data.user).'];
end

if nargin<4 || isempty(which)
    which = allStreams;
else
    qExist = isfield(data,which);
    if isfield(data,'user')
        qExist = qExist | isfield(data.user,which);
    end
    assert(all(qExist),'The following are not known data streams:\n%s',sprintf('  %s\n',which{~qExist}));
end
if nargin>2 && ~isempty(fileSuffix)
    fileSuffix = ['_' fileSuffix];
end

for p=1:length(which)
    fname = fullfile(directory,sprintf('%s%s.tsv',which{p},fileSuffix));
    fid   = fopen(fname,'wt');
    switch which{p}
        case 'eye'
            fprintf(fid,'timestamp\tgaze sample index\tpupil_center_left_x\tpupil_center_left_y\tpupil_center_left_z\tpupil_diameter_left\tgaze_direction_left_x\tgaze_direction_left_y\tgaze_direction_left_z\tazimuth_left\televation_left\t');
            fprintf(fid,'pupil_center_right_x\tpupil_center_right_y\tpupil_center_right_z\tpupil_diameter_right\tgaze_direction_right_x\tgaze_direction_right_y\tgaze_direction_right_z\tazimuth_right\televation_right\t');
            fprintf(fid,'gaze_point_video_x\tgaze_point_video_y\tgaze_point_3D_x\tgaze_point_3D_y\tgaze_point_3D_z\n');
            % collect data based on gidx
            off   = min([data.eye.left.gidx(1) data.eye.right.gidx(1) data.eye.binocular.gidx(1)])-1;
            nSamp = max([length(data.eye.left.ts) length(data.eye.right.ts) length(data.eye.binocular.ts)]);
            
            writeDat  = nan(25,nSamp);
            writeDat(    1,:) = data.eye.left.ts.';
            writeDat(    2,:) = data.eye.left.gidx-off.';
            writeDat( 3: 5,:) = data.eye.left.pc.';
            writeDat(    6,:) = data.eye.left.pd.';
            writeDat( 7: 9,:) = data.eye.left.gd.';
            writeDat(   10,:) = data.eye.left.azi.';
            writeDat(   11,:) = data.eye.left.ele.';
            writeDat(12:14,:) = data.eye.right.pc.';
            writeDat(   15,:) = data.eye.right.pd.';
            writeDat(16:18,:) = data.eye.right.gd.';
            writeDat(   19,:) = data.eye.right.azi.';
            writeDat(   20,:) = data.eye.right.ele.';
            writeDat(21:22,:) = data.eye.binocular.gp.';
            writeDat(23:25,:) = data.eye.binocular.gp3.';
            
            fprintf(fid,'%.6d\t%.0f\t%.2f\t%.2f\t%.2f\t%.2f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.2f\t%.2f\t%.2f\t%.2f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.2f\t%.2f\t%.2f\n',writeDat);
        case 'gyroscope'
            fprintf(fid,'timestamp\tgyroscopy_x\tgyroscopy_y\tgyroscopy_z\n');
            fprintf(fid,'%.6d\t%.3d\t%.3d\t%.3d\n',[data.gyroscope.ts data.gyroscope.gy].');
        case 'accelerometer'
            fprintf(fid,'timestamp\taccelerometer_x\taccelerometer_y\taccelerometer_z\n');
            fprintf(fid,'%.6d\t%.3d\t%.3d\t%.3d\n',[data.accelerometer.ts data.accelerometer.ac].');
        case 'video'
            fprintf(fid,'video_type\tframe_index\ttimestamp\n');
            nFr = length(data.video.scene.fts);
            writeDat = [repmat({'scene'},1,nFr); num2cell([1:nFr; data.video.scene.fts])];
            fprintf(fid,'%s\t%d\t%.6f\n', writeDat{:});
            if isfield(data.video,'eye')
                nFr = length(data.video.eye.fts);
                writeDat = [repmat({'eye'},1,nFr); num2cell([1:nFr; data.video.eye.fts])];
                fprintf(fid,'%s\t%d\t%.6f\n', writeDat{:});
            end
        case 'syncPort'
            fprintf(fid,'direction\ttimestamp\tstate\n');
            writeDat = [repmat({'out'},1,length(data.syncPort.out.ts)); num2cell([data.syncPort.out.ts data.syncPort.out.state].')];
            fprintf(fid,'%s\t%.6f\t%d\n', writeDat{:});
            writeDat = [repmat({'in'} ,1,length(data.syncPort. in.ts)); num2cell([data.syncPort. in.ts data.syncPort. in.state].')];
            fprintf(fid,'%s\t%.6f\t%d\n', writeDat{:});
        case 'syncAPI'
            fprintf(fid,'timestamp\texternal_timestamp\ttype\ttag\n');
            writeDat = [num2cell([data.syncAPI.ts data.syncAPI.ets]) data.syncAPI.type data.syncAPI.tag].';
            fprintf(fid,'%.6f\t%.0f\t%s\t%s\n',writeDat{:});
        case 'time'
            fprintf(fid,'start_time\tend_time\n');
            fprintf(fid,'%.6d\t%.6d\n',[data.time.startTime data.time.endTime]);
        otherwise
            % user stream
            nCol = size(data.user.(which{p}).data,2);
            header = sprintf('channel_%d\t',1:nCol); header(end) = [];
            fprintf(fid,'timestamp\t%s\n',header);
            fmt    = repmat('%.6f\t',1,nCol); fmt(end-1:end) = [];
            fprintf(fid,['%.6d\t' fmt '\n'],[data.user.(which{p}).ts data.user.(which{p}).data].');
    end
    
    fclose(fid);
end
function saveDataToTSV(data,directory,fileSuffix,which,intervalTs)

% Cite as: Niehorster, D.C., Hessels, R.S., and Benjamins, J.S. (2020).
% GlassesViewer: Open-source software for viewing and analyzing data from
% the Tobii Pro Glasses 2 eye tracker. Behavior Research Methods. doi:
% 10.3758/s13428-019-01314-1

allStreams   = {'eye','gyroscope','accelerometer','video','syncPort','APIevent','time'};
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
if nargin>=3 && ~isempty(fileSuffix)
    fileSuffix = ['_' fileSuffix];
else
    fileSuffix = '';
end

qHaveIntervals = nargin>=5 && ~isempty(intervalTs);
extraHeader = '';
extraFmt = '';
if qHaveIntervals
    extraHeader = 'interval_index\t';
    extraFmt = '%.0f\t';
else
    intervalTs = [-inf inf];
end

for p=1:length(which)
    fname = fullfile(directory,sprintf('%s%s.tsv',which{p},fileSuffix));
    fid   = fopen(fname,'wt');
    switch which{p}
        case 'eye'
            fprintf(fid,[extraHeader 'timestamp\tgaze sample index\tpupil_center_left_x\tpupil_center_left_y\tpupil_center_left_z\tpupil_diameter_left\tgaze_direction_left_x\tgaze_direction_left_y\tgaze_direction_left_z\tazimuth_left\televation_left\t']);
            fprintf(fid,'pupil_center_right_x\tpupil_center_right_y\tpupil_center_right_z\tpupil_diameter_right\tgaze_direction_right_x\tgaze_direction_right_y\tgaze_direction_right_z\tazimuth_right\televation_right\t');
            fprintf(fid,'gaze_point_video_x\tgaze_point_video_y\tgaze_point_3D_x\tgaze_point_3D_y\tgaze_point_3D_z\n');
            % collect data based on gidx
            off   = min([data.eye.left.gidx(1) data.eye.right.gidx(1) data.eye.binocular.gidx(1)])-1;
            [qOutput,ival] = getIntervalSamples(data.eye.left.ts,intervalTs);
            
            writeDat  = nan(25+qHaveIntervals,sum(qOutput));
            if qHaveIntervals
                writeDat(1,:) = ival;
            end
            writeDat(     1 +qHaveIntervals,:) = data.eye.left.ts(qOutput).';
            writeDat(     2 +qHaveIntervals,:) = data.eye.left.gidx(qOutput)-off.';
            writeDat([ 3: 5]+qHaveIntervals,:) = data.eye.left.pc(qOutput,:).';
            writeDat(     6 +qHaveIntervals,:) = data.eye.left.pd(qOutput).';
            writeDat([ 7: 9]+qHaveIntervals,:) = data.eye.left.gd(qOutput,:).';
            writeDat(    10 +qHaveIntervals,:) = data.eye.left.azi(qOutput).';
            writeDat(    11 +qHaveIntervals,:) = data.eye.left.ele(qOutput).';
            writeDat([12:14]+qHaveIntervals,:) = data.eye.right.pc(qOutput,:).';
            writeDat(    15 +qHaveIntervals,:) = data.eye.right.pd(qOutput).';
            writeDat([16:18]+qHaveIntervals,:) = data.eye.right.gd(qOutput,:).';
            writeDat(    19 +qHaveIntervals,:) = data.eye.right.azi(qOutput).';
            writeDat(    20 +qHaveIntervals,:) = data.eye.right.ele(qOutput).';
            writeDat([21:22]+qHaveIntervals,:) = data.eye.binocular.gp(qOutput,:).';
            writeDat([23:25]+qHaveIntervals,:) = data.eye.binocular.gp3(qOutput,:).';
            
            fprintf(fid,[extraFmt '%.6d\t%.0f\t%.2f\t%.2f\t%.2f\t%.2f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.2f\t%.2f\t%.2f\t%.2f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.2f\t%.2f\t%.2f\n'],writeDat);
        case 'gyroscope'
            fprintf(fid,[extraHeader 'timestamp\tgyroscopy_x\tgyroscopy_y\tgyroscopy_z\n']);
            [qOutput,ival] = getIntervalSamples(data.gyroscope.ts,intervalTs);
            fprintf(fid,[extraFmt '%.6d\t%.3d\t%.3d\t%.3d\n'],[ival data.gyroscope.ts(qOutput) data.gyroscope.gy(qOutput,:)].');
        case 'accelerometer'
            fprintf(fid,[extraHeader 'timestamp\taccelerometer_x\taccelerometer_y\taccelerometer_z\n']);
            [qOutput,ival] = getIntervalSamples(data.accelerometer.ts,intervalTs);
            fprintf(fid,[extraFmt '%.6d\t%.3d\t%.3d\t%.3d\n'],[ival data.accelerometer.ts(qOutput) data.accelerometer.ac(qOutput,:)].');
        case 'video'
            fprintf(fid,[extraHeader 'video_type\tframe_index\ttimestamp\n']);
            nFr = length(data.video.scene.fts);
            writeDat = [repmat({'scene'},1,nFr); num2cell([1:nFr; data.video.scene.fts])];
            [qOutput,ival] = getIntervalSamples(data.video.scene.fts,intervalTs);
            if ~isempty(ival)
                writeDat = [num2cell(ival); writeDat(:,qOutput)];
            end
            fprintf(fid,[extraFmt '%s\t%d\t%.6f\n'], writeDat{:});
            
            if isfield(data.video,'eye')
                nFr = length(data.video.eye.fts);
                writeDat = [repmat({'eye'},1,nFr); num2cell([1:nFr; data.video.eye.fts])];
                [qOutput,ival] = getIntervalSamples(data.video.eye.fts,intervalTs);
                if ~isempty(ival)
                    writeDat = [num2cell(ival); writeDat(:,qOutput)];
                end
                fprintf(fid,[extraFmt '%s\t%d\t%.6f\n'], writeDat{:});
            end
        case 'syncPort'
            fprintf(fid,[extraHeader 'direction\ttimestamp\tstate\n']);
            
            [qOutput,ival] = getIntervalSamples(data.syncPort.out.ts,intervalTs);
            writeDat = [num2cell(ival).'; repmat({'out'},1,sum(qOutput)); num2cell([data.syncPort.out.ts(qOutput) data.syncPort.out.state(qOutput)].')];
            fprintf(fid,[extraFmt '%s\t%.6f\t%d\n'], writeDat{:});
            
            [qOutput,ival] = getIntervalSamples(data.syncPort.in.ts,intervalTs);
            writeDat = [num2cell(ival).'; repmat({'in'} ,1,sum(qOutput)); num2cell([data.syncPort. in.ts(qOutput) data.syncPort. in.state(qOutput)].')];
            fprintf(fid,[extraFmt '%s\t%.6f\t%d\n'], writeDat{:});
        case 'APIevent'
            fprintf(fid,[extraHeader 'timestamp\texternal_timestamp\ttype\ttag\n']);
            [qOutput,ival] = getIntervalSamples(data.APIevent.ts,intervalTs);
            writeDat = [num2cell([ival data.APIevent.ts(qOutput) data.APIevent.ets(qOutput)]) data.APIevent.type(qOutput) data.APIevent.tag(qOutput)].';
            fprintf(fid,[extraFmt '%.6f\t%.0f\t%s\t%s\n'],writeDat{:});
        case 'time'
            fprintf(fid,[extraHeader 'start_time\tend_time\n']);
            fprintf(fid,[extraFmt '%.6d\t%.6d\n'],[data.time.startTime data.time.endTime]);
        otherwise
            % user stream
            nCol = size(data.user.(which{p}).data,2);
            header = sprintf('channel_%d\t',1:nCol); header(end) = [];
            fprintf(fid,[extraHeader 'timestamp\t%s\n'],header);
            fmt    = repmat('%.6f\t',1,nCol); fmt(end-1:end) = [];
            [qOutput,ival] = getIntervalSamples(data.user.(which{p}).ts,intervalTs);
            fprintf(fid,[extraFmt '%.6d\t' fmt '\n'],[ival data.user.(which{p}).ts(qOutput) data.user.(which{p}).data(qOutput,:)].');
    end
    
    fclose(fid);
end


function [bool,ival] = getIntervalSamples(ts,intervalTs)
if numel(intervalTs)==2 && isequal(intervalTs,[-inf inf])
    bool = true(size(ts));
    ival = [];
    return
end

bool = false(size(ts));
ival = zeros(size(bool));

for p=1:size(intervalTs,1)
    qInterval = ts>=intervalTs(p,1) & ts<=intervalTs(p,2);
    bool = bool | qInterval;
    ival(qInterval) = p;
end

ival = ival(bool);
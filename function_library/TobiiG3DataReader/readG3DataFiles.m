function data = readG3DataFiles(recordingDir,userStreams,qDEBUG)

% Cite as: Niehorster, D.C., Hessels, R.S., and Benjamins, J.S. (2020).
% GlassesViewer: Open-source software for viewing and analyzing data from
% the Tobii Pro Glasses 2 eye tracker. Behavior Research Methods. doi:
% 10.3758/s13428-019-01314-1

% set file format version. cache files older than this are overwritten with
% a newly generated cache file
fileVersion = 7;

if ~isempty(which('matlab.internal.webservices.fromJSON'))
    jsondecoder = @matlab.internal.webservices.fromJSON;
elseif ~isempty(which('jsondecode'))
    jsondecoder = @jsondecode;
else
    error('Your MATLAB version does not provide a way to decode json (which means its really old), upgrade to something newer');
end

cacheFile = fullfile(recordingDir,'gazedata.mat');
qGenCacheFile = ~exist(cacheFile,'file');
if ~qGenCacheFile
    % we have a cache file, check its file version
    cache = load(cacheFile,'fileVersion');
    qGenCacheFile = cache.fileVersion~=fileVersion;
end

if qGenCacheFile || qDEBUG
    % 0 get info about participant and recording
    fid = fopen(fullfile(recordingDir,'recording.g3'),'rt');
    recording = jsondecoder(fread(fid,inf,'*char').');
    fclose(fid);
    expectedFs = round(recording.gaze.samples/recording.duration/50)*50;    % find nearest 50Hz
    if qDEBUG
        fprintf('determined fs: %d Hz\n',expectedFs);
    end
    pFile = fullfile(recordingDir,recording.meta_folder,'participant');
    if ~~exist(pFile,"file")
        fid = fopen(pFile,'rt');
        participant = jsondecoder(fread(fid,inf,'*char').');
        fclose(fid);
    else
        participant.name = 'unknown';
    end
    
    % 1 read in gaze data
    % 1.1 unpack gz file, if doesn't exist
    gzFile = fullfile(recordingDir,recording.gaze.file);
    [~,gazeFile,~] = fileparts(gzFile);
    gazeFile = fullfile(recordingDir,gazeFile);
    if ~exist(gazeFile,'file')
        gunzip(fullfile(recordingDir,recording.gaze.file));
    end
    % 1.2 read in gaze data
    fprintf('reading: %s\n',gazeFile);
    fid = fopen(gazeFile,'rt');
    gazeData = fread(fid,inf,'*char').';
    fclose(fid);
    delete(gazeFile);
    % turn into something we can read
    gazeData(gazeData==10) = ',';
    gazeData = jsondecoder(['[' gazeData ']']);
    % do quick checks
    types = unique({gazeData.type});
    assert(isscalar(types) && strcmp(types{1},'gaze'),'Data not as expected')
    
    % 2 turn into our data format
    % 2.1 prep storage
    data.device             = 'G3';
    data.eye.fs             = expectedFs;
    data.eye.left.ts        = cat(1,gazeData.timestamp);
    data.eye.right.ts       = data.eye.left.ts;
    data.eye.binocular.ts   = data.eye.left.ts;
    nSamp                   = length(gazeData);
    [data.eye.left.pc, data.eye.left.gd]    = deal(nan(nSamp,3));
    data.eye.left.pd                        =      nan(nSamp,1) ;
    [data.eye.right.pc, data.eye.right.gd]  = deal(nan(nSamp,3));
    data.eye.right.pd                       =      nan(nSamp,1) ;
    data.eye.binocular.gp                   =      nan(nSamp,2) ;
    data.eye.binocular.gp3                  =      nan(nSamp,3) ;
    % 2.2 throw data into storage
    qNotMissing                             = arrayfun(@(x) isfield(x.data,'gaze2d'),gazeData); % struct is empty (and thus doesn't have this field) if there is no data
    gazeData                                = cat(1,gazeData(qNotMissing).data);
    data.eye.binocular.gp (qNotMissing,:)   = cat(2,gazeData.gaze2d).';
    data.eye.binocular.gp3(qNotMissing,:)   = cat(2,gazeData.gaze3d).';
    [qNotMissingLA,qNotMissingRA]           = deal(qNotMissing);
    qNotMissingL                            = arrayfun(@(x) isfield(x.eyeleft ,'gazeorigin'),gazeData);
    qNotMissingR                            = arrayfun(@(x) isfield(x.eyeright,'gazeorigin'),gazeData);
    qNotMissingLA(qNotMissing)              = qNotMissingL;
    qNotMissingRA(qNotMissing)              = qNotMissingR;
    left                                    = cat(1,gazeData(qNotMissingL).eyeleft);
    right                                   = cat(1,gazeData(qNotMissingR).eyeright);
    if ~isempty(left)
        data.eye.left .pc(qNotMissingLA,:)      = cat(2,left.gazeorigin).';
        data.eye.left .pd(qNotMissingLA)        = cat(2,left.pupildiameter).';
        data.eye.left .gd(qNotMissingLA,:)      = cat(2,left.gazedirection).';
    end
    if ~isempty(right)
        data.eye.right.pc(qNotMissingRA,:)      = cat(2,right.gazeorigin).';
        data.eye.right.pd(qNotMissingRA)        = cat(2,right.pupildiameter).';
        data.eye.right.gd(qNotMissingRA,:)      = cat(2,right.gazedirection).';
    end
    % 2.3 for each binocular sample, see on how many eyes its based
    data.eye.binocular.nEye                 = sum([qNotMissingLA qNotMissingRA],2);
    % clean up
    clear gazeData left right qNotMissing qNotMissingL qNotMissingLA qNotMissingR qNotMissingRA
    % 2.4 fill up missed samples with nan
    data.eye                                = fillMissingSamples(data.eye,data.eye.fs);
    % 2.5 convert gaze vectors to azimuth elevation
    [la,le] = cart2sph(data.eye. left.gd(:,1),data.eye. left.gd(:,3),data.eye. left.gd(:,2));   % matlab's Z and Y are reversed w.r.t. ours
    [ra,re] = cart2sph(data.eye.right.gd(:,1),data.eye.right.gd(:,3),data.eye.right.gd(:,2));
    data.eye. left.azi  =  la*180/pi-90;    % I have checked sign and offset of azi and ele so that things match the gaze position on the scene video in the data file (gp)
    data.eye.right.azi  =  ra*180/pi-90;
    data.eye. left.ele  = -le*180/pi;
    data.eye.right.ele  = -re*180/pi;
    % clean up
    clear la le ra re
    
    % 3 read in event data
    % 3.1 unpack gz file, if doesn't exist
    gzFile = fullfile(recordingDir,recording.events.file);
    [~,eventFile,~] = fileparts(gzFile);
    eventFile = fullfile(recordingDir,eventFile);
    if ~exist(eventFile,'file')
        gunzip(fullfile(recordingDir,recording.events.file));
    end
    % 3.2 read in event data
    fprintf('reading: %s\n',eventFile);
    fid = fopen(eventFile,'rt');
    eventData = fread(fid,inf,'*char').';
    fclose(fid);
    delete(eventFile);
    % turn into something we can read
    eventData(eventData==10) = ',';
    eventData = jsondecoder(['[' eventData ']']);
    % 3.3 sync signal
    qSync= strcmp({eventData.type},'syncport');
    sync = cat(1,eventData(qSync).data);
    ts   = cat(1,eventData(qSync).timestamp);
    qOut = strcmp({sync.direction},'out');
    % 3.3.1 outgoing
    if any(qOut)
        data.syncPort.out.ts    = ts(qOut);
        data.syncPort.out.state = cat(1,sync(qOut).value);
    else
        [data.syncPort.out.ts,data.syncPort.out.state] = deal([]);
    end
    % 3.3.2 incoming
    if any(~qOut)
        data.syncPort.in.ts    = ts(~qOut);
        data.syncPort.in.state = cat(1,sync(~qOut).value);
    else
        [data.syncPort.in.ts,data.syncPort.in.state] = deal([]);
    end
    % 3.4 API events
    qAPI = strcmp({eventData.type},'event');
    if any(qAPI)
        data.APIevent.ts    = cat(1,eventData(qAPI).timestamp);
        temp                = cat(1,eventData(qAPI).data);
        data.APIevent.tag   = {temp.tag}.';
        data.APIevent.object= {temp.object}.';
        clear temp
    else
        [data.APIevent.ts,data.APIevent.tag,data.APIevent.object] = deal([],{},{});
    end
    % clean up
    clear eventData sync ts qSync qOut qAPI
    
    % 4 read in IMU data (NB some old firmware versions didn't record IMU
    % data)
    % 4.1 unpack gz file, if doesn't exist
    if isfield(recording,'imu')
        gzFile = fullfile(recordingDir,recording.imu.file);
        [~,imuFile,~] = fileparts(gzFile);
        imuFile = fullfile(recordingDir,imuFile);
        if ~exist(imuFile,'file')
            gunzip(fullfile(recordingDir,recording.imu.file));
        end
        % 4.2 read in event data
        fprintf('reading: %s\n',imuFile);
        fid = fopen(imuFile,'rt');
        imuData = fread(fid,inf,'*char').';
        fclose(fid);
        delete(imuFile);
        % turn into something we can read
        imuData(imuData==10) = ',';
        imuData = jsondecoder(['[' imuData ']']);
        % 4.3 turn into our format
        % find out what each packet is. Packets either have accelerometer and
        % gyroscope data, or magnetometer data
        qAccGyro = arrayfun(@(x) isfield(x.data,'accelerometer'),imuData);
        % accelerometer + gyroscope
        data.accelerometer.ts   = cat(1,imuData(qAccGyro).timestamp);
        data.gyroscope.ts       = cat(1,imuData(qAccGyro).timestamp);
        temp = cat(1,imuData(qAccGyro).data);
        data.accelerometer.ac   = cat(2,temp.accelerometer).';
        data.gyroscope.gy       = cat(2,temp.gyroscope).';
        % magnetometer
        data.magnetometer.ts    = cat(1,imuData(~qAccGyro).timestamp);
        temp = cat(1,imuData(~qAccGyro).data);
        data.magnetometer.mag   = cat(2,temp.magnetometer).';
        % clean up
        clear imuData qAccGyro temp
    end
    
    % 5 check video files for each segment: how many frames, and make
    % frame timestamps
    qHasEyeVideo = ~isempty(recording.eyecameras);
    data.video.scene.fts        = [];
    data.video.scene.segframes  = [];
    if qHasEyeVideo
        data.video.eye.fts          = [];
        data.video.eye.segframes    = [];
    end
    for p=1:1+qHasEyeVideo
        switch p
            case 1
                file = recording.scenecamera.file;
                field= 'scene';
            case 2
                file = recording.eyecameras.file;
                field= 'eye';
        end
        fname = fullfile(recordingDir,file);
        % get frame timestamps and such from info stored in the mp4
        % file's atoms
        [timeInfo,sttsEntries,atoms,videoTrack] = getMP4VideoInfo(fname);
        % 1. timeInfo (from mdhd atom) contains info about timescale,
        % duration in those units and duration in ms
        % 2. stts table, contains the info needed to determine
        % timestamp for each frame. Use entries in stts to determine
        % frame timestamps. Use formulae described here:
        % https://developer.apple.com/library/content/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25696
        fIdxs = SmartVec(sttsEntries(:,2),sttsEntries(:,1),'flat');
        timeStamps = cumsum([0 fIdxs]);
        timeStamps = timeStamps/timeInfo.time_scale;
        % last is timestamp for end of last frame, should be equal to
        % length of video
        assert(floor(timeStamps(end)*1000)==timeInfo.duration_ms,'these should match')
        % 3. determine number of frames in file that matlab can read by
        % direct indexing. It seems the Tobii files sometimes have a
        % few frames at the end erroneously marked as keyframes. All
        % those cannot be read by matlab (when using read for a
        % specific time or frame number), so take number of frames as
        % last real keyframe. If not a problem, just take number of
        % frames as last for which we have timeStamp
        lastFrame = [];
        [sf,ef] = bool2bounds(diff(atoms.tracks(videoTrack).stss.table)==1);
        if ~isempty(ef) && ef(end)==length(atoms.tracks(videoTrack).stss.table)
            lastFrame = atoms.tracks(videoTrack).stss.table(sf(end));
        end
        if isempty(lastFrame)
            lastFrame = sum(sttsEntries(:,1));
        end
        % now that we know number of readable frames, we may have more
        % timestamps than actually readable frames, throw away ones we
        % don't need as we can't read those frames
        assert(length(timeStamps)>=lastFrame)
        timeStamps(lastFrame+1:end) = [];
        % Sync video frames with data by offsetting the timelines for
        % each based on timesync info in tobii data file
        data.video.(field).fts = [data.video.(field).fts timeStamps];
        data.video.(field).segframes = [data.video.(field).segframes lastFrame];
        
        % resolution sanity check
        if atoms.tracks(videoTrack).tkhd.width~=atoms.tracks(videoTrack).stsd.width || atoms.tracks(videoTrack).tkhd.height~=atoms.tracks(videoTrack).stsd.height
            % NB: i've seen this in recordings with very old firmware
            % version 1.7.2+sommarregn, can be safely ignored in that case
            warning('mp4 file weird: video widths and/or heights in tkhd and stsd atoms do not match')
        end
        data.video.(field).width    = atoms.tracks(videoTrack).stsd.width;
        data.video.(field).height   = atoms.tracks(videoTrack).stsd.height;
        data.video.(field).fs       = round(1/median(diff(data.video.(field).fts)));    % observed frame rate
        
        % store name of video file
        data.video.(field).file{1}  = file;
    end
    
    % 6 check video file quality
    data.video = checkMissingFrames(data.video, 0.05, 0.1);
    
    % 7 scale binocular gaze point on video data to pixels
    % we can do so now that we know how big the scene video is
    data.eye.binocular.gp(:,1) = data.eye.binocular.gp(:,1)*data.video.scene.width;
    data.eye.binocular.gp(:,2) = data.eye.binocular.gp(:,2)*data.video.scene.height;
    
    % 8 add time information -- data interval to be used
    % use data from last start of video (scene or eye, whichever is later)
    % to first end of video. To make sure we have data during the entire
    % interval, these start and end times are adjusted such that startTime
    % is the timestamp of the last sample before t=0 if there is no sample
    % at t=0, and similarly endTime is adjusted to the timestamp of the
    % first sample after t=end if there is no sample at t=end. If data ends
    % before end of any video, endTime is end of data.
    % 8.1 start time: timestamps are already relative to last video start
    % time, so just get time of first sample at 0 or just before
    data.time.startTime = data.eye.left.ts(find(data.eye.left.ts<=0,1,'last'));
    if isempty(data.time.startTime)
        data.time.startTime = data.eye.left.ts(1);
    end
    % 8.2 end time
    if qHasEyeVideo
        te = min([data.video.scene.fts(end) data.video.eye.fts(end)]);
    else
        te = data.video.scene.fts(end);
    end
    data.time.endTime   = data.eye.left.ts(find(data.eye.left.ts>=te,1));
    if isempty(data.time.endTime)
        % if video continues after end of data, take data end as end time
        data.time.endTime = data.eye.left.ts(end);
    end
    
    % 9 add scene camera calibration info
    data.video.scene.calibration.position               = recording.scenecamera.camera_calibration.position.';
    data.video.scene.calibration.focalLength            = recording.scenecamera.camera_calibration.focal_length.';
    data.video.scene.calibration.rotation               = recording.scenecamera.camera_calibration.rotation;
    data.video.scene.calibration.skew                   = recording.scenecamera.camera_calibration.skew;
    data.video.scene.calibration.principalPoint         = recording.scenecamera.camera_calibration.principal_point.';
    data.video.scene.calibration.radialDistortion       = recording.scenecamera.camera_calibration.radial_distortion.';
    data.video.scene.calibration.tangentialDistortion   = recording.scenecamera.camera_calibration.tangential_distortion.';
    data.video.scene.calibration.resolution             = recording.scenecamera.camera_calibration.resolution.';
    
    % 10 compute user streams, if any
    if ~isempty(userStreams)
        data = computeUserStreams(data, userStreams);
    end
    
    % 11 store to cache file
    data.subjName           = participant.name;
    data.recName            = recording.name;
    data.fileVersion        = fileVersion;
    data.userStreamSettings = userStreams;
    save(cacheFile,'-struct','data');
else
    fprintf('loading: %s\n',cacheFile);
    data = load(cacheFile);
    % still output warning messages about holes in video, if any
    checkMissingFrames(data.video, 0.05, 0.1);
    % recompute user streams, if needed because settings changed, or
    % because requested
    qResaveCache = false;
    if ~isequal(userStreams,data.userStreamSettings)
        % settings changed, throw away old and recompute
        if isfield(data,'user')
            data = rmfield(data,'user');
        end
        data = computeUserStreams(data, userStreams);
        qResaveCache = true;
    end
    if ~isempty(userStreams)
        recomputeOnLoad = [userStreams.recomputeOnLoad];
        if any(recomputeOnLoad)
            % one or multiple userStreams are set to recompute on load
            data = computeUserStreams(data, userStreams(recomputeOnLoad));
            qResaveCache = true;
        end
    end
    if qResaveCache
        data.userStreamSettings = userStreams;
        save(cacheFile,'-struct','data');
    end
end

% these fields are internal to this function, remove from output
data = rmfield(data,{'fileVersion','userStreamSettings'});

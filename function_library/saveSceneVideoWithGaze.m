function saveSceneVideoWithGaze(data, directory, clrs, alpha, ffmpegPath, callback)

% Cite as: Niehorster, D.C., Hessels, R.S., and Benjamins, J.S. (2020).
% GlassesViewer: Open-source software for viewing and analyzing data from
% the Tobii Pro Glasses 2 eye tracker. Behavior Research Methods. doi:
% 10.3758/s13428-019-01314-1

qHaveCallback = nargin>5 && ~isempty(callback);
percDone = 0;
if qHaveCallback
    callback(percDone);
end

qHaveFFmpeg = nargin>4 && ~isempty(ffmpegPath) && exist(ffmpegPath,'file')==2;

% load videos
switch data.device
    case 'G2'
        segments = FolderFromFolder(fullfile(directory,'segments'));
        for s=length(segments):-1:1
            fullpath{s} = fullfile(directory,'segments',segments(s).name,'fullstream.mp4');
            reader{s}   = VideoReader(fullpath{s}); %#ok<TNMLP>
            % for warmup, read first frame
            reader{s}.read(1);
        end
    case 'G3'
        fullpath{1} = fullfile(directory,'scenevideo.mp4');
        reader{1}   = VideoReader(fullpath{1});
    otherwise
        error('device %s not supported for API events',data.device)
end
res = [reader{1}.Width reader{1}.Height];

% find where black frames should be inserted to make up for holes in scene
% video (e.g. segment switchover)
dt  = diff(data.video.scene.fts);
ifi = median(dt);
iGap= find(dt>ifi*4/3);    % index indicates sample _after_ which there is a gap

gapSzs          = dt(iGap);
nFrameMissing   = round(gapSzs/ifi)-1;     % round instead of ceil or floor gives smallest deviation from nominal framerate: 5.4->5, 5.6->6

% For each frame of output, figure out which input frame to use
fts             = data.video.scene.fts;
fridxs          = [1:length(fts)];
vididxs         = [];
switches        = [0 cumsum(data.video.scene.segframes)];
for p=length(data.video.scene.segframes):-1:1
    vididxs = [p*ones(1,data.video.scene.segframes(p)) vididxs]; %#ok<AGROW>
    if p>1
        qFrame = fridxs>switches(p);
        fridxs(qFrame) = fridxs(qFrame)-switches(p);
    end
end
isBlackFrame    = false(size(fridxs));
for p=length(iGap):-1:1
    blackFrameTs = interp1([0 nFrameMissing(p)+1],fts(iGap+[0 1]),[1:nFrameMissing(p)]);
    fts          = [         fts(1:iGap)       blackFrameTs                fts(iGap+1:end)];
    fridxs       = [      fridxs(1:iGap)  nan(1,nFrameMissing(p))       fridxs(iGap+1:end)];
    vididxs      = [     vididxs(1:iGap)  nan(1,nFrameMissing(p))      vididxs(iGap+1:end)];
    isBlackFrame = [isBlackFrame(1:iGap) true(1,nFrameMissing(p)) isBlackFrame(iGap+1:end)];
end
% last, cut off frame before start and after end
qRem = fts<data.time.startTime | fts>data.time.endTime;
fts(qRem)           = [];
fridxs(qRem)        = [];
vididxs(qRem)       = [];
isBlackFrame(qRem)  = [];

% open output video
if qHaveFFmpeg
    % run ffmpeg via java so we can pipe videodata into it
    % and directly copy audio
    % prep audio
    inputs  = {};
    filters = {};
    for s=1:length(reader)
        if s==1
            offset  = data.video.scene.fts(1)-data.time.startTime;
            filters = [filters sprintf('[0:a]atrim=start=%.6f,asetpts=PTS-STARTPTS[a]',max(0,-offset))];
        else
            startTs = data.video.scene.fts(data.video.scene.segframes(s-1)+1)-data.time.startTime;
            filters = [filters sprintf('[%d:a]adelay=delays=%.3f:all=1[%c]',s-1,startTs*1000,char('a'+s-1))];
        end
    
        inputs = [inputs '-i' fullpath{s}];
    end
    filters = [filters; repmat({';'},size(filters))];
    filters = [filters{:}];
    filters = [filters sprintf('%samix=%d[audio];',sprintf('[%c]',char('a'+[1:length(reader)]-1)),length(reader))];
    % prep video
    inputs = [inputs '-f','rawvideo','-video_size',sprintf('%dx%d',res),'-framerate',sprintf('%.3f',1/ifi),'-pixel_format','rgb24','-i','pipe:'];
    filters = [filters sprintf('[%d:v]format=yuv420p[video]',length(reader))];
    % prep command and launch ffmpeg
    command = {ffmpegPath,'-y',inputs{:},'-filter_complex',filters,'-map','[video]','-map','[audio]','-c:v','libx264',fullfile(directory,'scenevideo_gaze.mp4')};
    h       = java.lang.ProcessBuilder(command).redirectErrorStream(true).start();
    stdin   = h.getOutputStream();
    % NB: need to get all handles as we need to close them all
    % also, need to read from stdout+stderr to not get blocked
    jReader = java.io.BufferedReader(java.io.InputStreamReader(h.getInputStream()));
    
else
    outName             = fullfile(directory,'scenevideo_gaze.mp4');
    writer              = VideoWriter(outName,'MPEG-4');
    writer.FrameRate    = 1/ifi;
    writer.Quality      = 75;
    open(writer);
end

% prep gaze circle
rad     = max(res)/190;
[x,y]   = meshgrid(linspace(-rad,rad,ceil(2*rad)+2),linspace(-rad,rad,ceil(2*rad)+2));
circle  = abs(x./rad).^2 + abs(y./rad).^2 < 1;
circle  = circle(any(circle,1),any(circle,2));  % crop edges so its tightly fitting
cIdx    = [-floor(size(circle,1)/2):ceil(size(circle,1)/2)-1];
mask    = repmat(alpha*circle, [1 1 3]);

% overlay gaze on each frame and store
for f=1:length(fridxs)
    % get frame
    if isBlackFrame(f)
        frame = zeros(res(2),res(1),3,'uint8');
    else
        frame = reader{vididxs(f)}.read(fridxs(f));
    end
    
    % get corresponding data
    if f==length(fridxs)
        qDat = data.eye.binocular.ts>=fts(f) & data.eye.binocular.ts<data.time.endTime;
    else
        qDat = data.eye.binocular.ts>=fts(f) & data.eye.binocular.ts<fts(f+1);
    end
    dat = round(data.eye.binocular.gp  (qDat,:));
    nEye=       data.eye.binocular.nEye(qDat,:);
    
    % overlay circle
    for d=1:size(dat,1)
        if isnan(dat(d,1))
            continue
        end
        
        oIdxX = dat(d,1)+cIdx;
        oIdxY = dat(d,2)+cIdx;
        
        qUseX = oIdxX>1 & oIdxX<=res(1);
        qUseY = oIdxY>1 & oIdxY<=res(2);
        
        dCircle = cat(3,...
            circle(qUseY,qUseX)*clrs(nEye(d),1),...
            circle(qUseY,qUseX)*clrs(nEye(d),2),...
            circle(qUseY,qUseX)*clrs(nEye(d),3));
        
        frame(oIdxY(qUseY),oIdxX(qUseX),:) = uint8(...
            double(frame(oIdxY(qUseY),oIdxX(qUseX),:)).*(1-mask(qUseY,qUseX,:)) + ...
            dCircle                                   .*   mask(qUseY,qUseX,:));
    end
    
    % write to video
    if qHaveFFmpeg
        stdin.write(reshape(permute(frame,[3 2 1]),1,[]));
        stdin.flush();
        while jReader.ready()
            fprintf('%s\n',jReader.readLine());
        end
    else
        writeVideo(writer,frame);
    end
    
    newPercDone = floor(f/length(fridxs)*100);
    if qHaveCallback && newPercDone ~= percDone
        callback(newPercDone);
    end
    percDone = newPercDone;
end

% finalize
if qHaveFFmpeg
    stdin.close();
    jReader.close();
else
    close(writer);
end
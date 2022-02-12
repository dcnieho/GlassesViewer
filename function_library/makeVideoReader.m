function rdr = makeVideoReader(fName,qGetPreciseEndFrame)
if nargin<2
    qGetPreciseEndFrame = false;
end
warnState = warning('OFF', 'MATLAB:audiovideo:VideoReader:unknownNumFrames');
cleaner = onCleanup(@()warning(warnState));

mmrobj = VideoReader(fName);

rdr.StreamHandle = mmrobj;

rdr.FrameRate  = get(mmrobj, 'FrameRate');
rdr.Dimensions = [get(mmrobj, 'Height') get(mmrobj, 'Width')];
rdr.AspectRatio= get(mmrobj, 'Width')./get(mmrobj, 'Height');

if qGetPreciseEndFrame
    % Now get real number of frames. Not as simple as hoped, because the
    % NumFrames field is not reliable. I get "The frame index requested is
    % beyond the end of the file." errors before reaching NumberOfFrames as
    % read index. So, try to read the last frame and run back until we find a
    % frame that can be read. NB: This happens for mp4 files where last few
    % frames are erroneously marked as keyframes. This seek method fails on
    % that. This can be determined directly from stss table of the video
    % track in the mp4 file (for the Tobii Glasses files I have looked at).
    nFrames = get(mmrobj, 'NumberOfFrames');
    if isempty(nFrames)
        error(message('MATLAB:audiovideo:VideoReader:unknownNumFrames',lastwarn));
    end
    s = nFrames;
    while true
        try
            rdr.StreamHandle.read(s);
            break;  % break out of loop once we read a frame successfully
        catch
            % do nothing, try again
            s = s-1;
        end
    end
    % fprintf('%s: numframes %d (was %d)\n',mmrobj.Name,s,nFrames);
    rdr.NumFrames = s;
end

% Get full file name as read by the read function
% This heads off problems when the filename was specified without
% an extension, and a MATLAB file exists with the same name.
rdr.full_name = fullfile(mmrobj.Path, mmrobj.Name);
end
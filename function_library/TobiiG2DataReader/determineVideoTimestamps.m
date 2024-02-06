function timeStamps = determineVideoTimestamps(sttsEntries, atoms, videoTrack)

% 1. check if we have an edit list, so we can apply it
empty_duration = 0;
if isfield(atoms.tracks(videoTrack),'elst')
    assert(length(atoms.tracks(videoTrack).elst)<=2)
    edit_start_index = 1;
    % logic ported from mov_build_index() in ffmpeg's libavformat/mov.c
    for e=1:length(atoms.tracks(videoTrack).elst.segment_duration)
        if e==1 && atoms.tracks(videoTrack).elst.media_time(e) == -1
            % if empty, the first entry is the start time of the stream
            % relative to the presentation itself
            empty_duration = atoms.tracks(videoTrack).elst.segment_duration(e);
            edit_start_index = 2;
        elseif e==edit_start_index && atoms.tracks(videoTrack).elst.media_time(e) > 0
            error('File contains an edit list that is too complicated (start time is not 0) for this parser, not supported');
        elseif e>edit_start_index
            error('File contains an edit list that is too complicated (multiple edits) for this parser, not supported');
        end
    end
    % durations are in global timescale units; convert to s
    empty_duration = double(empty_duration)/atoms.moov.mvhd.timeScale;
end

% 2. stts table, contains the info needed to determine
% timestamp for each frame. Use entries in stts to determine
% frame timestamps. Use formulae described here:
% https://developer.apple.com/library/content/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25696
fIdxs = SmartVec(sttsEntries(:,2),sttsEntries(:,1),'flat');
timeStamps = cumsum([0 fIdxs]);
timeStamps = timeStamps/atoms.tracks(videoTrack).mdhd.time_scale + empty_duration;
% last is timestamp for end of last frame, should be equal to
% length of video
assert(any(floor((timeStamps(end)-[0 empty_duration])*1000)==atoms.tracks(videoTrack).mdhd.duration_ms),'these should match')

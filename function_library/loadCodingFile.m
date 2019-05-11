function coding = loadCodingFile(options,tsData,startT,endT)
% deal with special !!recordingDir!! string if at start of path
coding.wasLoaded = false;
fname = options.file;
special = '!!recordingDir!!';
if length(fname)>=length(special) && strcmpi(fname(1:length(special)),special)
    fname = [options.recordingDir filesep fname(length(special)+1:end)];
end
fname   = getFullPath(fname);
coding.fname = fname;
if exist(fname,'file')~=2
    return;
end
codeF   = fileread(fname);
coding.wasLoaded = true;
codeF   = reshape(sscanf(codeF,'%f'),2,[]);     % format: lines with [event start, event type]. this is sufficient as assumption of this code is that every sample is tagged with an event type. use event "none" or "other" for things that are not of interest to you
ts      = codeF(1,:);
type    = codeF(2,:);
% fix up output.
% 1. if t=0 is first sample in data instead of start of video, correct.
if options.needToCorrectT0
    ts  = ts+tsData(1);
end
% 2. align all markers to sample times
ts2 = findNearestTime(ts,tsData,startT,endT);
if any(abs(ts2-ts)>.001)
    warning('time markers in coding file were off from sample times by more than 1 ms. They have been corrected to nearest sample times, ensure this is not a problem for you. Coding file: %s.',fname);
end
ts = ts2;
% 3. truncate events to part of data during which we actually have videos
iBeforeSt   = find(ts<startT);
if ~isempty(iBeforeSt)
    ts  (iBeforeSt(end))    = startT;
    ts  (iBeforeSt(1:end-1))= [];
    type(iBeforeSt(1:end-1))= [];
end
iAfterEnd   = find(ts>=endT);
if ~isempty(iAfterEnd)
    ts  (iAfterEnd(1))      = endT;
    ts  (iAfterEnd(2:end))  = [];
    type(iAfterEnd(2:end))  = [];
end
% 4. make sure we have expected start and end markers
[ts,type] = addStartEndCoding(ts,type,startT,endT);
% store
coding.mark = ts;
coding.type = type;
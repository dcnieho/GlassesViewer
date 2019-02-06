function coding = loadCodingFile(options,endT)
% deal with special !!dataDir!! string if at start of path
fname = options.file;
special = '!!dataDir!!';
if length(fname)>=length(special) && strcmp(fname(1:length(special)),special)
    fname = [options.dataDir filesep fname(length(special)+1:end)];
end
fname   = getFullPath(fname);
codeF   = fileread(fname);
codeF   = reshape(sscanf(codeF,'%f'),2,[]);     % format: lines with [event start, event type]. this is sufficient as assumption of this code is that every sample is tagged with an event type. use event "none" or "other" for things that are not of interest to you
ts      = codeF(1,:);
type    = codeF(2,:);
% fix up
[ts,type] = addStartEndCoding(ts,type,endT);
% store
coding.mark = ts;
coding.type = type;
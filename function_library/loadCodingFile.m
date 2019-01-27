function coding = loadCodingFile(options,endT)
fname   = getFullPath(options.file);
codeF   = fileread(fname);
codeF   = reshape(sscanf(codeF,'%f'),2,[]);     % format: lines with [event start, event type]. this is sufficient as assumption of this code is that every sample is tagged with an event type. use event "none" or "other" for things that are not of interest to you
ts      = codeF(1,:);
type    = codeF(2,:);
if nargin>1
    [ts,type] = addStartEndCoding(ts,type,endT);
else
    [ts,type] = addStartEndCoding(ts,type);
end
% store
coding.mark = ts;
coding.type = type;
function coding = loadCodingFile(options,endT)
fname   = getFullPath(options.file);
codeF   = fileread(fname);
codeF   = reshape(sscanf(codeF,'%f'),2,[]);     % format: lines with [event start, event type]. this is sufficient as assumption of this code is that every sample is tagged with an event type. use event "none" or "other" for things that are not of interest to you
ts      = codeF(1,:);
type    = codeF(2,:);
% add start of time
if ts(1)>1
    ts  = [1 ts];
    if type(1)==1
        type= [2 type];
    else
        type= [1 type];
    end
end
% add end
if nargin>1
    if ts(end)>=endT
        % last mark at last sample: this does not start a new
        % event anymore (always one more mark than type as
        % marks also needed to close off events)
        type(end) = [];
        ts(end) = endT; % ensure end not beyond data
    else
        ts = [ts endT];
    end
else
    type(end) = [];
end
% store
coding.mark = ts;
coding.type = type;
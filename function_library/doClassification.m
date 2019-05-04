function coding = doClassification(tobiiData,func,parameters,startT,endT)

% run classification
func = str2func(func);
% User function should accept tobiiData struct, and struct with parameter
% names as fields and values as their values.
% Should return timestamps for _start_ of each event, and event's type.
% Only start times are required as coding should not have gaps.
% Also return end time of last event in ts (so ts return is always one
% longer than type return array).
% get ready to call event detector function:
% 1. extract parameters
for p=1:length(parameters)
    val = parameters{p}.value;
    switch parameters{p}.type
        case 'double'
            val = double(val);
        case 'int'
            val = int32(val);
        case 'bool'
            val = logical(val);
    end
    params.(parameters{p}.name) = val;
end
% call func
[ts,type]   = func(tobiiData,params);
% ensure row vectors
ts          = ts(:).';
type        = type(:).';
% fix up output
% 1. truncate events to part of data during which we actually have videos
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
% 2. make sure we have expected start and end markers
[ts,type]   = addStartEndCoding(ts,type,startT,endT);
% store
coding.mark = ts;
coding.type = type;
function coding = doClassification(tobiiData,func,parameters,endT)

% run classification
func = str2func(func);
% user function should accept tobiiData struct, and struct with parameter
% names as fields and values as their values.
% should return timestamps for _start_ of each event, and event's type
% only start times are required as coding should not have gaps
% also return end time of last event in ts (so ts return is always one
% longer than type return array)
[ts,type] = func(tobiiData,parameters);
if nargin>3
    [ts,type] = addStartEndCoding(ts,type,endT);
else
    [ts,type] = addStartEndCoding(ts,type);
end
% store
coding.mark = ts;
coding.type = type;
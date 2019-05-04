function time = findNearestTime(time,ts,startTime,endTime)
% find nearest sample time, constrained to lay between 0 and endTime
% clamps to 0 and end, and rounds to nearest (ideal) sample

% 1. find which sample time is nearest to requested time
for t=1:length(time)
    [~,i]   = min(abs(ts-time(t)));
    time(t) = ts(i);
end

% 2. clamp to [startTime endTime] range
time = min(max(time,startTime),endTime);
end
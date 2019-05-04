function [emark,type] = HC13(tobiiData,params)

% NB! classifier function should output event mark times in original times
% as passed in here, so t=0 should correspond to the same sample as what
% was input here. It should also be in seconds, like the input
time    = tobiiData.eye.binocular.ts*1000;  % this classifier wants time in ms

%%%%% determine velocity
vx      = HC13_detvel(tobiiData.eye.binocular.gp(:,1),time);
vy      = HC13_detvel(tobiiData.eye.binocular.gp(:,2),time);
v       = hypot(vx,vy);

%%%%% detect slow phases
emark   = HC13_detectfixaties2015(v,params,time);

% turn back to seconds. Otherwise we're fine with this one, it keeps the
% input time signal intact
emark   = emark/1000;
% this denotes slow event, now add fast in and turn into expected output
% format
% events are denoted as interleaved start and end times. we want only
% starts, so take starts (uneven) and turn ends (even) into starts of other
% event
smarks  = sort([emark(1:2:end); emark(2:2:end)+1]);
% defined categories are named with powers of 2, so in this case json
% contains:
% "categories": [ "none", 20, "slow", 4, "fast", 5 ]
% then:
% none: 1
% slow: 2
% fast: 4

% TODO: be bit smarter: if not slow phase because no data in interval, code
% as 1, not 4
type    = repmat([2 4].',length(smarks)/2,1);
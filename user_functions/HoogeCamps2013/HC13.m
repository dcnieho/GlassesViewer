function [emark,type] = HC13(tobiiData,params,endT)

% select data during part from which we actually have videos (in some cases
% you may want to classify everything and only then truncate events)
qT      = tobiiData.eye.binocular.ts>=0 & tobiiData.eye.binocular.ts<=endT;
time    = tobiiData.eye.binocular.ts(qT)*1000;
%%%%% determine velocity
vx      = HC13_detvel(tobiiData.eye.binocular.gp(qT,1),time);
vy      = HC13_detvel(tobiiData.eye.binocular.gp(qT,2),time);
v       = hypot(vx,vy);

%%%%% detect fixations
emark   = HC13_detectfixaties2015(v,params,time);

% this denotes slow event, now add fast in and turn into expected output
% format
% 1. turn time back into sample number
emark   = arrayfun(@(x) find(time==x),emark);
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
type    = repmat([2 4].',length(smarks)/2,1);
function [emark,type] = HesselsEtAl19(tobiiData,params)

% NB! classifier function should output event mark times in original times
% as passed in here, so t=0 should correspond to the same sample as what
% was input here. It should also be in seconds, like the input
time    = tobiiData.eye.binocular.ts*1000;  % this classifier wants time in ms

%%%%% determine velocity
vx      = HC13_detvel(tobiiData.eye.binocular.gp(:,1),time);
vy      = HC13_detvel(tobiiData.eye.binocular.gp(:,2),time);
v       = hypot(vx,vy);

% prep params
params.windowsize   = round(params.windowlength./(1000/tobiiData.eye.fs)); % window size in samples


%%%%% detect slow phases with moving window averaged threshold
nSamp   = numel(time);
% max windowstart
lastwinstart = nSamp-params.windowsize+1;

[thr,ninwin] = deal(zeros(nSamp,1));
for b=1:lastwinstart
    idxs    = b:b+params.windowsize-1;
    
    % get fixation-classification threshold
    thrwindow = HesselsEtAl19_detectfixaties2018thr(v(idxs),params);
    
    % add threshod
    thr(idxs)       = thr(idxs)+thrwindow;
    % update number of times in win
    ninwin(idxs)    = ninwin(idxs)+1;
end

% now get final thr
thr = thr./ninwin;

emark = HesselsEtAl19_detectfixaties2018fmark(v,time,thr,params);

%%%%% prep output
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
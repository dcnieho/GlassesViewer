function [smarks,type] = HesselsEtAl2020(tobiiData,params)
%
% Classifier as used in Roy S. Hessels, Andrea J. van Doorn, Jeroen S.
% Benjamins, Gijs A. Holleman & Ignace T. C. Hooge (2020). Task-related
% gaze control in human crowd navigation. Attention, Perception, &
% Psychophysics 82, pp. 2482–2501. doi: 10.3758/s13414-019-01952-9

% NB! classifier function should output event mark times in original times
% as passed in here, so t=0 should correspond to the same sample as what
% was input here. It should also be in seconds, like the input
time    = tobiiData.eye.binocular.ts*1000;  % this classifier wants time in ms

%%%%% determine velocity
switch params.signal
    case 'videoGaze'
        x = tobiiData.eye.binocular.gp(:,1);
        y = tobiiData.eye.binocular.gp(:,2);
    case 'leftVec'
        x = tobiiData.eye.left.azi;
        y = tobiiData.eye.left.ele;
    case 'rightVec'
        x = tobiiData.eye.right.azi;
        y = tobiiData.eye.right.ele;
    otherwise
        error('signal type ''%s'' unknown',params.signal)
end
vx      = HesselsEtAl2020_detvel(x,time);
vy      = HesselsEtAl2020_detvel(y,time);
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
    thrwindow = HesselsEtAl2020_detectfixaties2018thr(v(idxs),params);
    
    % add threshod
    thr(idxs)       = thr(idxs)+thrwindow;
    % update number of times in win
    ninwin(idxs)    = ninwin(idxs)+1;
end

% now get final thr
thr = thr./ninwin;

emark = HesselsEtAl2020_detectfixaties2018fmark(v,time,thr,params);

%%%%% prep output
% "emark" denotes slow events, now add fast in and turn into expected
% output format
% events are denoted as interleaved start and end times. we want only
% starts, so take starts (uneven) and turn ends (even) into starts of other
% event
imarks  = find(ismember(time,emark));
assert(length(imarks)==length(emark),'some output samples do not correspond to an input time. consider using findNearestTime, or fix algorithm')    % general advice, this should never fire for this algorithm
imarks  = sort([imarks(1:2:end); imarks(2:2:end)+1]);

% turn back to seconds. Otherwise we're fine with this one, it keeps the
% input time signal intact
time    = time/1000;
smarks  = time(imarks);

% defined categories are named with powers of 2, so in this case json
% contains:
% "categories": [ "none", 20, "slow", 4, "fast", 5 ]
% then:
% none: 1
% slow: 2
% fast: 4

% add fast in between the slow phases
type    = repmat([2 4].',length(smarks)/2,1);

% check each fast phase if actually missing (>50% of samples invalid), then
% put code 1 instead ("none"). NB: this is specific to this classifier, you
% may want something else for yours.
% NB: this classifier always also eats one sample at either end of event,
% so check for missing for 2:end-1. also, since one event end is other
% event start, remove an extra sample from end for check
for e=1:length(imarks)-1
    idxs = imarks(e)+1:imarks(e+1)-2;
    if sum(isnan(x(idxs)))>length(idxs)*.5
        type(e) = 1;
    end
end

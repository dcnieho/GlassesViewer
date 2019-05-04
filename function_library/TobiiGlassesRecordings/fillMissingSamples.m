function data = fillMissingSamples(data,expectedFs)
% NB!! we have data for each eye and binocular for matched gidx (by now
% removed from data as no longer needed). Data for same gidx doesn't
% however always come with exactly the same timestamps. As differences are
% (should be) tiny, we can ignore this. check differences are tiny though.
u=unique(data.left.ts-data.right.ts);
assert(all(isnan(u) | u<1000))  % arbitrarily decide that less than one ms is small
u=unique(data.left.ts-data.binocular.ts);
assert(all(isnan(u) | u<1000))  % arbitrarily decide that less than one ms is small

% fill holes with nans (just split time interval between two samples
% into equally sized bits). You may think we can do this based on gidx.
% every non-existent gidx just needs a ts (or better yet, just keep those
% ts). Can't do that as the gidx are a bit messy. there are some spurious
% ones in there with non-zero s (crap). so best we can do is just look at
% the data and go from there. I see there are some very few samples where
% there is e.g. 13 ms between samples instead of 10. we'll just have to
% live with that

% step 1, for left, check if in right we do have corresponding ts, use it
% to fill gap. do same vice versa. Then check for binocular
% NB: timestamps are nan if for a given gidx there was no data, see
% organizeTobiiGlassesEyeData
% 1. right -> left eye
qInRight = isnan(data.left.ts) & ~isnan(data.right.ts);
data.left.ts(qInRight) = data.right.ts(qInRight);
% 2. left -> right
qInleft = isnan(data.right.ts) & ~isnan(data.left.ts);
data.right.ts(qInleft) = data.left.ts(qInleft);
% 3. left -> binocular
qInleft = isnan(data.binocular.ts) & ~isnan(data.left.ts);
data.binocular.ts(qInleft) = data.left.ts(qInleft);

% gaps are places where ISI is 1.667 (5/3) times longer than expected given
% sampling frequency expectedFs (arbitrarily chosen). deal with these.
% First remove all nan ts from a signal, find gaps by above definition,
% fill with new ts and nan data
% Note that we now break correspondence between the three signals, as they
% may have different missing data in them. As we have taken maximum care to
% have corresponding timestamps in the three signals, in practice after the
% below operation, the three signals will correspond again (i.e., have the
% same ts fields). I struggle to think of a situation where this would not
% be the case, and have not found a recording where this failed.
data.left       = replaceElementsInStruct(data.left     ,isnan(data.left.ts),[],[],true);
data.right      = replaceElementsInStruct(data.right    ,isnan(data.left.ts),[],[],true);
data.binocular  = replaceElementsInStruct(data.binocular,isnan(data.left.ts),[],[],true);
thr = round(1000*1000/expectedFs*5/3); % consider a gap as more than thr time elapsed between consequtive samples (5/3 means gap when ISI is 1.667 times longer than expected)
for c=1:3
    switch c
        case 1
            ch = 'left';
        case 2
            ch = 'right';
        case 3
            ch = 'binocular';
    end
    
    % find all gaps
    dt      = diff(data.(ch).ts);
    iGap    = find(dt>thr);    % index indicates sample _after_ which there is a gap
    
    % determine how long the new signal will be with gaps filled
    gapSzs          = dt(iGap);
    nSampMissing    = round(gapSzs/(1000*1000/expectedFs))-1;     % round instead of ceil or floor gives smallest deviation from nominal framerate: 5.4->5, 5.6->6
    
    % place samples in the right places (effectively inserts the missing
    % samples)
    % indicate where real samples should be in timeline
    idxs            = ones(1,length(data.(ch).ts));
    idxs(iGap+1)    = nSampMissing+1;
    idxs            = cumsum(idxs);
    % put them there, couched in nan
    fields = fieldnames(data.(ch));
    for f=1:length(fields)
        temp                    = nan(idxs(end),size(data.(ch).(fields{f}),2));
        temp(idxs,:)            = data.(ch).(fields{f});
        data.(ch).(fields{f})   = temp;
    end
    
    % fill gaps in time with faked equally intersecting intervals
    data.(ch).ts = round(interp1(idxs,data.(ch).ts(idxs),1:idxs(end),'linear')).';
end
if ~isequal(data.left.ts,data.right.ts) || ~isequal(data.left.ts,data.binocular.ts)
    warning('timestamps for the different eyes are not the same. please contact dcnieho@gmail.com if you are willing to share this recording, I would love to see it and check if this is a problem')
end
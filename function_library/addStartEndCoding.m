function [ts,type] = addStartEndCoding(ts,type,endT)
if isempty(ts)
    % if no marks, add start one. We always have a start mark, code expects
    % that
    ts = 1;
    type = [];
    return;
end

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
if nargin>2
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
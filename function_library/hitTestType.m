function hndl = hitTestType(hm,type)
% NB: for update of this to output on cursor movement, window needs to have
% WindowButtonMotionFcn callback set. Otherwise only updates upon clicks.
% Same for CurrentPoint property of a figure or axis

hndl=hittest(hm);   % works when we have a mouse motion callback
if strcmp(class(hndl),'opaque') %#ok<STISA>
    hndl = [];
elseif ~strcmp(hndl.Type,type)
    hndl = ancestor(hndl,type);
end
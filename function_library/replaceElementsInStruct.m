function str = replaceElementsInStruct(str,idxOrBool,elem,fieldFilter,applyOverDim)
% goes over all non-scalar fields of a struct (note that a string is
% non-scalar!) and replaces the elements indicated by idxOrBool with the
% elem in elem. Elem can be empty, in which case you're deleting those
% entries from all fields, a scalar, or the same length as the number of
% elements indicated by idxOrBool.
% An optional fourth input, a cellstring fieldFilter, can be provided to
% only apply the function on some fields, or to exclude some fields. Append
% fieldnames in fieldFilter with an exclamation mark ! to exclude them. No
% error is generated when requested fields do not exists, the fields in the
% struct are simply matched against the filter and any in both are
% included/excluded. Its is pointless to include some fields while
% excluding others, but the code deals with it correctly. If a field is
% both included and excluded, the exclusion takes preference.
% if applyOverDim is nonempty, it is cast over all other dimensions instead
% of used as a linear index. so if applyOverDim==2 and idxOrBool is a 1x10
% vector, the operation is done as variable(:,idxOrBool,:,:,:,...)

qAllScalar = all(structfun(@isscalar,str));
if nargin<5
    applyOverDim = [];
end
if ~isempty(applyOverDim)
    assert(isvector(idxOrBool),'if applying the index over all other dimensions, it needs to be vector')    % also true for scalar. fine
end
if nargin<4
    fieldFilter = [];
end

if isempty(fieldFilter)
    % apply on all (non-scalar) fields, we can use structfun
    str = structfun(@(x) replaceTheElements(x,idxOrBool,elem,qAllScalar,applyOverDim),str, 'uni',false);
else
    % need to for-loop this by hand
    % get names of fields in struct
    fn = fieldnames(str);
    
    % split fieldFilter in those to include and those to exclude
    qFilter     = cellfun(@(x) x(1)=='!',fieldFilter);
    excluded    = fieldFilter(qFilter);
    included    = fieldFilter(~qFilter);
    % and get rid of the exclamation mark
    excluded    = cellfun(@(x) x(2:end),excluded,'uni',false);
    
    
    % remove fields not included from processing queue
    % is included is empty, then all are included before we remove the
    % excluded fields below
    if ~isempty(included)
        fn(~ismember(fn,included)) = [];
    end
    % remove fields that are excluded from processing queue
    fn( ismember(fn,excluded)) = [];
    
    for p=1:length(fn)
        str.(fn{p}) = replaceTheElements(str.(fn{p}),idx,elem,qAllScalar,applyOverDim);
    end
end


% helper funcs
function field = replaceTheElements(field,idxOrBool,elem,allowScalar,applyOverDim)

if allowScalar || ~isscalar(field)
    idx = getIdxVector(idxOrBool,applyOverDim,field);
    if isempty(elem)
        field(idx{:}) = [];
    else
        field(idx{:}) = elem;
    end
end

function idxs = getIdxVector(idxOrBool,applyOverDim,fieldRef)
if isempty(applyOverDim)
    idxs = {idxOrBool};
else
    idxs = repmat({':'},1,ndims(fieldRef));
    idxs{applyOverDim} = idxOrBool;
end

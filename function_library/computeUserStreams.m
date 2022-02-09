function data = computeUserStreams(data, userStreams)

for p=1:length(userStreams)
    fprintf('  creating user streams: %s() -> %s\n',userStreams(p).function,formatStreamNames(userStreams(p).streams));
    
    % check stream names
    builtIns = getBuiltInPanels();
    qClash = ismember(userStreams(p).streams,builtIns);
    assert(~any(qClash),'The following streams clash with built-in streams: %s\nDo not define streams with the following names: %s',formatStreamNames(userStreams(p).streams(qClash)),formatStreamNames(builtIns));
    qValid = cellfun(@isvarname,userStreams(p).streams);
    assert(all(qValid),'The following streams are not valid matlab variable names: %s. Refer to isvarname()',formatStreamNames(userStreams(p).streams(~qValid)));
    
    % get function, check outputs
    func = str2func(userStreams(p).function);
    nout    = nargout(func);
    assert(nout>=length(userStreams(p).streams),'function %s is defined to yield %d streams, but function only has %d outputs, impossible',userStreams(p).function, length(userStreams(p).streams), nout);
    
    % run and assign outputs
    outputs = cell(1,nout);
    [outputs{:}] = func(data, userStreams(p).parameters);
    for q=1:length(userStreams(p).streams)
        data.user.(userStreams(p).streams{q}).ts   = outputs{q}{1};
        data.user.(userStreams(p).streams{q}).data = outputs{q}{2};
    end
end



function streams = formatStreamNames(streams)
if isempty(streams)
    streams = '';
else
    streams = sprintf('%s, ',streams{:});
    streams(end-1:end) = [];
end

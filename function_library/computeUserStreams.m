function data = computeUserStreams(data, userStreams)

for p=1:length(userStreams)
    streams = sprintf('%s, ',userStreams(p).streams{:}); streams(end-1:end) = [];
    fprintf('  creating user streams: %s() -> %s\n',userStreams(p).function,streams);
    
    func = str2func(userStreams(p).function);
    
    nout    = nargout(func);
    assert(nout>=length(userStreams(p).streams),'function %s is defined to yield %d streams, but function only has %d outputs, impossible',userStreams(p).function, length(userStreams(p).streams), nout);
    outputs = cell(1,nout);
    [outputs{:}] = func(data, userStreams(p).parameters);
    
    for q=1:length(userStreams(p).streams)
        data.user.(userStreams(p).streams{q}).ts   = outputs{q}{1};
        data.user.(userStreams(p).streams{q}).data = outputs{q}{2};
    end
end
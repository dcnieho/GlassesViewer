function data = computeUserStreams(data, userStreams)

for p=1:length(userStreams)
    fprintf('  creating user streams: %s\n',userStreams(p).function);
    
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
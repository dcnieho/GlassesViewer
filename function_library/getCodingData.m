function coding = getCodingData(filedir,fname,codeSettings,tobiiData)
if isempty(codeSettings.streams)
    return;
end

if isempty(fname)
    fname = 'coding.mat';
end

% deal with coding tags for each stream
if ~iscell(codeSettings.streams)
    codeSettings.streams = num2cell(codeSettings.streams);
end
% 1. get categories for all streams
categories = cellfun(@(x) x.categories, codeSettings.streams, 'uni', false);
% 2. transform into lookup table
categories = cellfun(@(x) reshape(x,2,[]).', categories, 'uni', false);
% 3. remove color info, that's just cosmetic
theCats = cellfun(@(x) x(:,1),categories,'uni',false).';
nStream = length(theCats);
% 4. create bitmask values for each stream
for p=1:nStream
    theCats{p} = [theCats{p} num2cell(bitshift(1,[0:length(theCats{p})-1].'))];
end
% 5. get colors in easy format too
theColors = cellfun(@(x) x(:,2),categories,'uni',false).';
for p=1:nStream
    theColors{p} = cellfun(@(x) codeSettings.colors(x,:),theColors{p},'uni',false,'ErrorHandler',@(~,~)[]);
end

% parse type of each stream, and other info
type    = cellfun(@(x) x.type, codeSettings.streams, 'uni', false);
locked  = true(size(type)); % a stream is locked by default, for all except buttonPress stream, user can set it to unlocked (i.e., user can edit coding)
qSyncEvents = ismember(lower(type),{'syncin','syncout'});
locked(~qSyncEvents) = cellfun(@(x) x.locked, codeSettings.streams(~qSyncEvents));
lbls    = cellfun(@(x) x.lbl, codeSettings.streams, 'uni', false);
options = cellfun(@(x) rmFieldOrContinue(x,{'lbl','type','locked','categories','parameters'}), codeSettings.streams, 'uni', false);

% set file format version. coding files older than this version are ignored
fileVersion = 2;

qHaveExistingCoding = exist(fullfile(filedir,fname),'file');
if qHaveExistingCoding
    % we have a cache file, check its file version and if coding streams
    % and categories are the same
    coding = load(fullfile(filedir,fname),'fileVersion','codeCats');
    qHaveExistingCoding = isfield(coding,'fileVersion') && coding.fileVersion==fileVersion && isequal(coding.codeCats,theCats);
end

% for start of coding stream, need first timestamp equal to zero or
% less
tFirst = tobiiData.eye.left.ts(find(tobiiData.eye.left.ts<=0,1,'last'));
if qHaveExistingCoding
    % load
    coding                  = load(fullfile(filedir,fname));
    % always replace some things by values from settings
    coding.codeColors       = theColors;
    coding.stream.lbls      = lbls;
    coding.stream.isLocked  = locked;
    coding.stream.options   = options;
else
    % create empty
    coding.log              = cell(0,3);                        % timestamp, identifier, additional data
    coding.mark             = repmat({tFirst},nStream,1);       % we code all samples, so always start with a mark at t is roughly 0
    coding.type             = repmat({zeros(1,0)},nStream,1);   % always one less elements than in mark, as two marks define one event
    coding.codeCats         = theCats;                          % info about what each event in each stream is, and the bitmask it is coded with
    coding.codeColors       = theColors;                        % just cosmetics, can be ignored, but good to have in easy format
    coding.fileVersion      = fileVersion;
    coding.stream.type      = type;
    coding.stream.lbls      = lbls;
    coding.stream.isLocked  = locked;
    coding.stream.options   = options;
end

% process some streams
if isfield(tobiiData.videoSync,'eye')
    endT = min([tobiiData.videoSync.scene.fts(end) tobiiData.videoSync.eye.fts(end)]);
else
    endT = min([tobiiData.videoSync.scene.fts(end)]);
end
for p=1:nStream
    switch lower(coding.stream.type{p})
        case {'syncin','syncout'}
            % load sync channel data from Tobii data
            if strcmpi(coding.stream.type{p},'syncin')
                ts  = tobiiData.syncPort.in.ts(:).';
                type= tobiiData.syncPort.in.state(:).'+1;
            else
                ts  = tobiiData.syncPort.out.ts(:).';
                type= tobiiData.syncPort.out.state(:).'+1;
            end
            % sometimes multiple times same event in a row, merge
            iSame = find(diff(type)==0);
            ts(iSame+1)     = [];
            type(iSame+1)   = [];
            if isempty(ts)
                warning('glassesViewer: no %s events found for stream %d',coding.stream.type{p},p);
            end
            [ts,type]       = addStartEndCoding(ts,type,tFirst,endT);
            % store
            coding.mark{p} = ts;
            coding.type{p} = type;
        case 'handstream'
            % nothing to do
        case 'filestream'
            % if nothing there yet, or always reload option set, load from
            % file
            coding.stream.options{p}.dataDir = filedir;
            if isscalar(coding.mark{p}) || (isfield(coding.stream.options{p},'alwaysReload') && coding.stream.options{p}.alwaysReload)
                tempCoding = loadCodingFile(coding.stream.options{p},tobiiData.eye.left.ts,tFirst,endT);
                % store
                coding.mark{p} = tempCoding.mark;
                coding.type{p} = tempCoding.type;
            end
        case 'classifier'
            if ~isfield(coding.stream,'classifier') || ~isfield(coding.stream.classifier,'defaults') || length(coding.stream.classifier.defaults)<p
                [coding.stream.classifier.defaults{p}, coding.stream.classifier.currentSettings{p}] = deal([]);
            end
            % Determine settings:
            % 1. default values are always reloaded from json, so user can
            %    change those without affecting anything else. These are
            %    loaded when user clicks "reset to defaults"
            % 2. currentSettings stores settings used for the currently
            %    stored event coding, may be equal to defaults.
            coding.stream.classifier.defaults{p} = codeSettings.streams{p}.parameters;
            if ~isfield(coding.stream.classifier,'currentSettings') || isempty(coding.stream.classifier.currentSettings{p})
                coding.stream.classifier.currentSettings{p} = coding.stream.classifier.defaults{p};
            else
                % copy over all parameter config except value, so that we
                % can change labels, precision, etc. Keep value intact. Do
                % it in the below way, to ensure that removed or added
                % parameters in the settings file are taken into account.
                temp = coding.stream.classifier.defaults{p};
                names = cellfun(@(x) x.name,coding.stream.classifier.currentSettings{p},'uni',false);
                for s=1:length(temp)
                    qName = strcmp(temp{s}.name, names);
                    if any(qName)
                        assert(sum(qName)==1,'parameter name ''%s'' occurs more than one for stream %d (''%s''), please fix your settings',temp{s}.name,p,coding.stream.lbls{p})
                        temp{s}.value = coding.stream.classifier.currentSettings{p}{qName}.value;
                    end
                end
                coding.stream.classifier.currentSettings{p} = temp;
            end
            % if nothing there yet, or always recalculate option set,
            % reclassify: always use default settings and recalculate
            if isempty(coding.type{p}) || (isfield(coding.stream.options{p},'alwaysRecalculate') && coding.stream.options{p}.alwaysRecalculate)
                % run classification
                if isfield(coding.stream.options{p},'alwaysRecalculateUseStoredSettings') && coding.stream.options{p}.alwaysRecalculateUseStoredSettings
                    settings = coding.stream.classifier.defaults{p};
                else
                    settings = coding.stream.classifier.currentSettings{p};
                end
                tempCoding = doClassification(tobiiData,coding.stream.options{p}.function,settings,tFirst,endT);
                % store
                coding.mark{p} = tempCoding.mark;
                coding.type{p} = tempCoding.type;
                % update currentSettings to make sure they reflect the
                % coding
                coding.stream.classifier.currentSettings{p} = settings;
            end
    end
    
    % check if types are valid (flag bits are set only if that
    % bit is marked as flag)
    % how flags work: an event whose name is suffixed with '+' can take as
    % flag an event whose name is prefixed with '*'. These are then
    % bit-anded together to make a special code
    vals        = cat(1,coding.codeCats{p}{:,2});
    qIsFlag     = cellfun(@(x) x( 1 )=='*',coding.codeCats{p}(:,1));
    assert(sum(qIsFlag)<=1,'Error in code category definition for stream %d: User can only define up to a single flag code category per stream',p);
    qTakesFlag  = cellfun(@(x) x(end)=='+',coding.codeCats{p}(:,1));
    assert(~xor(any(qIsFlag),any(qTakesFlag)),'Error in code category definition for stream %d: User must define either no flag events (''*'' prefix) and flag-accepting events (''+'' suffix) or both a flag event and at least one flag-accepting event',p);
    typeBits    = arrayfun(@(x) bitget(x,vals),coding.type{p},'uni',false);
    typeBits    = [typeBits{:}];
    % check 1: more than one bit set for any coded event even though no
    % flags or flag-acceptors defined?
    qMulti      = sum(typeBits,1)>1;
    assert(~any(qMulti)||(any(qIsFlag)&&any(qTakesFlag)),'invalid event code found in stream %d (''%s''): at least one event does not have a power-of-two (e.g. 1, 2, 4, etc) code, but no flag-events defined, impossible',p,coding.stream.lbls{p});
    % check 2: if any event codes have multiple bits set, check if its a
    % valid combination
    for i=find(qMulti)
        assert(~any(typeBits(~(qIsFlag|qTakesFlag),i)),'event code for event %d in stream %d invalid: event code has multiple bits set, but at least one of these bits is not for a flag event or a flag-accepting event',i,p)
    end
end

% store back up of file and classifier streams. Allows checking if coding
% is manually changed
if ~isfield(coding,'original')
    [coding.original.mark,coding.original.type] = deal(cell(size(coding.stream.type)));
end
qStoreOriginal              = false(size(coding.stream.type));
for p=1:length(coding.stream.type)
    % only relevant for 'classifier' and 'filestream'
    switch lower(coding.stream.type{p})
        case 'classifier'
            qStoreOriginal(p) = isempty(coding.original.mark{p}) || (isfield(coding.stream.options{p},'alwaysRecalculate') && coding.stream.options{p}.alwaysRecalculate);
        case 'filestream'
            qStoreOriginal(p) = isempty(coding.original.mark{p}) || (isfield(coding.stream.options{p},'alwaysReload') && coding.stream.options{p}.alwaysReload);
    end
    if qStoreOriginal(p)
        coding.original.mark{p} = coding.mark{p};
        coding.original.type{p} = coding.type{p};
    end
end


% add log entry indicated new session started
if exist('GetSecs','file')==3
    time = GetSecs;
else
    time = now;
end
coding.log(end+1,:) = {time,'SessionStarted',[]};
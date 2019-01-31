function coding = getCodingData(filedir,fname,codeSettings,tobiiData)
if isempty(fname)
    fname = 'handCoding.mat';
end

% deal with coding tags for each stream
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
options = cellfun(@(x) rmFieldOrContinue(x,{'lbl','type','locked','categories'}), codeSettings.streams, 'uni', false);

% set file format version. coding files older than this version are ignored
fileVersion = 1;

qHaveExistingCoding = exist(fullfile(filedir,fname),'file');
if qHaveExistingCoding
    % we have a cache file, check its file version
    coding = load(fullfile(filedir,fname),'fileVersion','codeCats');
    qHaveExistingCoding = coding.fileVersion==fileVersion && isequal(coding.codeCats,theCats);
end

if qHaveExistingCoding
    % load
    coding = load(fullfile(filedir,fname));
else
    % create empty
    coding.log              = cell(0,3);                        % timestamp, identifier, additional data
    coding.mark             = repmat({1},nStream,1);            % we code all samples, so always start with a mark at first sample
    coding.type             = cell(nStream,1);                  % always one less elements than in mark, as two marks define one event
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
endT = timeToMark(endT,tobiiData.eye.fs);
for p=1:nStream
    switch lower(coding.stream.type{p})
        case {'syncin','syncout'}
            % load sync channel data from Tobii data
            if strcmpi(coding.stream.type{p},'syncin')
                ts  = timeToMark(tobiiData.syncPort.in.ts(:).',tobiiData.eye.fs);
                type= tobiiData.syncPort.in.state(:).'+1;
            else
                ts  = timeToMark(tobiiData.syncPort.out.ts(:).',tobiiData.eye.fs);
                type= tobiiData.syncPort.out.state(:).'+1;
            end
            % sometimes multiple times same event in a row, merge
            iSame = find(diff(type)==0);
            ts(iSame+1)     = [];
            type(iSame+1)   = [];
            if isempty(ts)
                ts = 1; % we always have a start mark, code expects that
                warning('glassesViewer: no %s events found for stream %d',coding.stream.type{p},p);
            else
                [ts,type]       = addStartEndCoding(ts,type,endT);
            end
            % store
            coding.mark{p} = ts;
            coding.type{p} = type;
        case 'handstream'
            % nothing to do
        case 'filestream'
            % if nothing there yet, or always reload option set, load from
            % file
            if isscalar(coding.mark{p}) || (isfield(coding.stream.options{p},'alwaysReload') && coding.stream.options{p}.alwaysReload)
                tempCoding = loadCodingFile(coding.stream.options{p},endT);
                % store
                coding.mark{p} = tempCoding.mark;
                coding.type{p} = tempCoding.type;
            end
        case 'classifier'
            [coding.stream.classifier.defaults{p}, coding.stream.classifier.currentSettings{p}] = deal([]);
            % Determine settings:
            % 1. default values are always reloaded from json, so user can
            %    change those without affecting anything else. These are
            %    loaded when user clicks "reset to defaults" (TODO)
            % 2. currentSettings stores settings used for the currently
            %    stored event coding, may be equal to defaults.
            coding.stream.classifier.defaults{p}        = coding.stream.options{p}.parameters;
            if ~isfield(coding.stream.classifier,'currentSettings') || isempty(coding.stream.classifier.currentSettings{p})
                coding.stream.classifier.currentSettings{p} = coding.stream.classifier.defaults{p};
            end
            % if nothing there yet, or always recalculate option set,
            % reclassify. This always uses defaults
            if isscalar(coding.mark{p}) || (isfield(coding.stream.options{p},'alwaysRecalculate') && coding.stream.options{p}.alwaysRecalculate)
                if 0
                    % TODO: below function needs to change marks so that
                    % GUI starttime is also 1 in marks (we may have data
                    % earlier, and thus classifications starting earlier,
                    % need to deal with that case)
                    tempCoding = doClassification(tobiiData,coding.stream.options{p}.function,coding.stream.classifier.defaults{p},endT);
                    % store
                    coding.mark{p} = tempCoding.mark;
                    coding.type{p} = tempCoding.type;
                else
                    coding.mark{p} = 1;
                    coding.type{p} = [];
                end
                % update currentSettings to make sure they reflect the
                % coding
                coding.stream.classifier.currentSettings{p} = coding.stream.classifier.defaults{p};
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
    assert(~any(qMulti)||(any(qIsFlag)&&any(qTakesFlag)),'invalid event code found in stream %d: at least one event does not have a power-of-two (e.g. 1, 2, 4, etc) code, but no flag-events defined, impossible',p);
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
coding.log(end+1,:) = {GetSecs,'SessionStarted',[]};
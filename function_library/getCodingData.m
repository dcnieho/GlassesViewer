function coding = getCodingData(filedir,fname,codeSettings)
if isempty(fname)
    fname = 'handCoding.mat';
end

% deal with coding tags for each stream
% 1. get categories for all streams
categories = cellfun(@(x) x.categories, codeSettings.streams, 'uni', false);
% 2. transform into lookup table
categories = cellfun(@(x) [fieldnames(x) struct2cell(x)], categories, 'uni', false);
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
locked  = true(size(type));
qButtonPress = strcmpi(type,'buttonPress');
locked(~qButtonPress) = cellfun(@(x) x.locked, codeSettings.streams(~qButtonPress));
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

% add log entry indicated new session started
coding.log(end+1,:) = {GetSecs,'SessionStarted',[]};
function success = G3ProjectParser(recordingFolder,dontFailOnLockedFile)
% function to read in relevant JSON files of a Tobii Projects folder and
% create a human-readable lookup table in the project folder that can then
% be used by recordingSelector, which selects a recording for the
% glassesViewer or GazeCode
%
% can also be passed a specific project's folder, in which case it will
% list all the recordings belonging to the project.

if nargin<2 || isempty(dontFailOnLockedFile)
    dontFailOnLockedFile = false;
end

[recs, nrec] = FolderFromFolder(recordingFolder);

if ~isempty(which('matlab.internal.webservices.fromJSON'))
    jsondecoder = @matlab.internal.webservices.fromJSON;
elseif ~isempty(which('jsondecode'))
    jsondecoder = @jsondecode;
else
    error('Your MATLAB version does not provide a way to decode json (which means its really old), upgrade to something newer');
end

fid = [];   % only open the lookup file once we have something to write in it
for p = 1:nrec
    % for each folder in recordings, check if its a G3 recording and if so, process
    recorddir        = fullfile(recordingFolder, recs(p).name);
    recs(p).jsonfile = fullfile(recorddir, 'recording.g3');
    if exist(recs(p).jsonfile,'file')~=2
        warning('No Glasses 3 recording.g3 file found for: %s\n',recorddir);
        continue;
    end
    
    recording = jsondecoder(fileread(recs(p).jsonfile));
    
    % run over recordings, copying over relevant calibrations and
    % participant info as we go
    [...
        recs(p).recName,recs(p).recStartT,recs(p).durationSecs,...
        recs(p).partName,...
        recs(p).sysFWVersion,recs(p).sysHUSerial,recs(p).sysRUSerial...
        ] = deal('!!unknown');
    
    
    recs(p).recName         = recording.name;
    recs(p).recStartT       = datenum(recording.created,'yyyy-mm-ddTHH:MM:SS.FFF');
    recs(p).durationSecs    = recording.duration;
    
    recs(p).partName        = jsondecoder(fileread(fullfile(recorddir,recording.meta_folder,'participant'))).name;
    
    % get system/setup info
    recs(p).sysFWVersion = fileread(fullfile(recorddir,recording.meta_folder,'RuVersion'));
    recs(p).sysRUSerial  = fileread(fullfile(recorddir,recording.meta_folder,'RuSerial'));
    recs(p).sysHUSerial  = fileread(fullfile(recorddir,recording.meta_folder,'HuSerial'));
    
    if isempty(fid)
        lookupFile = fullfile(recordingFolder,'lookup_G3.tsv');
        fid = fopen(lookupFile,'wt');
        if fid==-1
            if dontFailOnLockedFile && ~~exist(lookupFile,'file')
                warning('Could not open the lookup_G3.tsv file for writing, probably because you have it open. Any changes in projects/recordings will not be picked up. Make sure ''%s'' is writeable and not opened in another program.',lookupFile)
                success = true;
                return;
            else
                error('Could not open the lookup_G3.tsv file for writing. Full filename: ''%s''',lookupFile);
            end
        end
        fprintf(fid,'RecordingFolder\tParticipantName\tRecordingName\tRecordingStartTime\tRecordingDurationSecs\tFirmwareVersion\tHeadUnitSerial\tRecordingUnitSerial\n');
    end
    
    fmt = '%s\t%s\t%s\t%s\t%.3f\t%s\t%s\t%s\n';
    fprintf(fid,fmt,recs(p).name,recs(p).partName,recs(p).recName,datestr(recs(p).recStartT,'yyyy-mm-dd HH:MM:SS.FFF'),recs(p).durationSecs,recs(p).sysFWVersion,recs(p).sysHUSerial,recs(p).sysRUSerial);
end
success = ~isempty(fid);
if success
    fclose(fid);
end
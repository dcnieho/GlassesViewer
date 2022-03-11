function recfolder = recordingSelector(projectfolder)
recfolder =[];


f = figure;
set(f,'Name','Select Recording','NumberTitle','off');
set(f,'MenuBar','none');
set(f,'DockControls','off');
set(f,'Resize','off');
set(f,'Units','pixels');

f.UserData.projfolder = projectfolder;

f.UserData.isG2 = ~~exist(fullfile(projectfolder,'lookup_G2.tsv'),'file');
f.UserData.isG3 = ~~exist(fullfile(projectfolder,'lookup_G3.tsv'),'file');

if f.UserData.isG2
    fid = fopen(fullfile(projectfolder,'lookup_G2.tsv'));
    fgetl(fid);
    C = textscan(fid,repmat('%s',1,18),'delimiter','\t');
    fclose(fid);
    
    f.UserData.ProjID = C{1};
    f.UserData.ProjName = C{5};
    f.UserData.ProjDate = C{6};
    
    f.UserData.PartID = C{2};
    f.UserData.PartName = C{7};
    
    f.UserData.RecID = C{3};
    f.UserData.RecName = C{9};
    f.UserData.RecDate = C{10};
    f.UserData.RecDur = C{11};
    
    f.UserData.CalID = C{4};
    f.UserData.CalStatus = C{13};
    
    [f.UserData.uProjID,i] = unique(f.UserData.ProjID);
    f.UserData.uProjName = f.UserData.ProjName(i);
    f.UserData.uProjDate = f.UserData.ProjDate(i);
    f.UserData.uProjLabel= cellfun(@(x,y) [x ', created: ' y],f.UserData.uProjName,f.UserData.uProjDate,'uni',false);
    qOnlyOneProject = isscalar(f.UserData.uProjID);
elseif f.UserData.isG3
    fid = fopen(fullfile(projectfolder,'lookup_G3.tsv'));
    fgetl(fid);
    C = textscan(fid,repmat('%s',1,8),'delimiter','\t');
    fclose(fid);
    
    f.UserData.PartName = C{2};
    
    f.UserData.RecID = C{1};
    f.UserData.RecName = C{3};
    f.UserData.RecDate = C{4};
    f.UserData.RecDur = C{5};
    
    f.UserData.CalStatus = repmat({'unknown'},length(C{1}),1);
else
    disp('No lookup table available for this projects/recordings folder');
    return
end
set(f,'Position',[0 0 440 280+60*f.UserData.isG2]);

if f.UserData.isG2
    f.UserData.pProj = uipanel('Title','Project','Units','pixels','Position',[10 280 420 50],'BackgroundColor',[1 .5 0.2]);
    f.UserData.popupProj = uicontrol('Style', 'popup',...
        'String', [{'<select project>'}; f.UserData.uProjLabel],...
        'Position', [20 260 400 50],...
        'Value',1,'CallBack',@changeProj);
end

f.UserData.pPart = uipanel('Title','Participant','Units','pixels','Position',[10 220 420 50],'BackgroundColor',[1 .5 0.2]);
if f.UserData.isG2
    str1 = 'first select a project';
    str2 = 'first select a project';
else
    str1 = '<select participant>';
    str2 = 'first select a participant';
end
f.UserData.popupPart = uicontrol('Style', 'popup',...
    'String', str1,...
    'Position', [20 200 400 50],...
    'Value',1,'CallBack',@changePart);

f.UserData.pRec = uipanel('Title','Recording','Units','pixels','Position',[10 160 420 50],'BackgroundColor',[1 .5 0.2]);
f.UserData.popupRec = uicontrol('Style', 'popup',...
    'String', str2,...
    'Position', [20 140 400 50],...
    'Value',1,'CallBack',@changeRec);

f.UserData.pCal = uipanel('Title','Calibration status:','Units','pixels','Position',[10 100 420 50]);
f.UserData.CalStat = uicontrol('Style', 'text',...
    'String', 'Unknown',...
    'Position', [20 110 400 20],...
    'Value',1,'BackgroundColor',[1 .5 0.2]);


f.UserData.butOK = uicontrol('Style','pushbutton',...
    'String','Use selected recording',...
    'Position', [20 30 400 50],...
    'Value',1,'CallBack',@useRec);
movegui(f,'center');

f.UserData.recfolder = '';

if f.UserData.isG2
    if qOnlyOneProject
        % only one project available, preselect
        f.UserData.popupProj.Value = 2;
        changeProj(f.UserData.popupProj,[]);
    end
else
    setParticipants(f);
end

waitfor(f);
end

function changeProj(src,~)
f = src.Parent;
welkeProj = src.Value-1;
if welkeProj==0
    f.UserData.pProj.BackgroundColor = [1 0.5 0.2];
    f.UserData.pPart.BackgroundColor = [1 0.5 0.2];
    f.UserData.popupPart.Value = 1;
    f.UserData.popupPart.String = 'first select a project';
    f.UserData.pRec.BackgroundColor = [1 0.5 0.2];
    f.UserData.popupRec.Value = 1;
    f.UserData.popupRec.String = 'first select a project';
    f.UserData.CalStat.String = 'Unknown';
    f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];
    return;
end
ProjName = f.UserData.uProjName{welkeProj};
ProjDate = f.UserData.uProjDate{welkeProj};
projIndex= strcmp(f.UserData.ProjName,ProjName) & strcmp(f.UserData.ProjDate,ProjDate);

f.UserData.CalStat.String = 'Unknown';
f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];

if isfield(f.UserData,'pProj')
    f.UserData.pProj.BackgroundColor = [0.5 1 0.5];
end

setParticipants(f,projIndex);
end

function setParticipants(f,projIndex)
if nargin>1
    tempPartName = f.UserData.PartName(projIndex);
else
    tempPartName = f.UserData.PartName;
end
f.UserData.uPartName = unique(tempPartName);
f.UserData.pPart.BackgroundColor = [1 0.5 0.2];
f.UserData.popupPart.Value = 1;
f.UserData.popupPart.String = [{'<select participant>'}; f.UserData.uPartName];

f.UserData.pRec.BackgroundColor = [1 0.5 0.2];
f.UserData.popupRec.Value = 1;
f.UserData.popupRec.String = 'first select a participant';

if isscalar(tempPartName)
    % only one participant available, preselect
    f.UserData.popupPart.Value = 2;
    changePart(f.UserData.popupPart,[]);
end
end

function changePart(src,~)
f = src.Parent;

welkePart = src.Value-1;
if welkePart==0
    f.UserData.pPart.BackgroundColor = [1 0.5 0.2];
    f.UserData.pRec.BackgroundColor = [1 0.5 0.2];
    f.UserData.popupRec.Value = 1;
    f.UserData.popupRec.String = 'first select a participant';
    f.UserData.CalStat.String = 'Unknown';
    f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];
    return;
end
PartName = f.UserData.uPartName{welkePart};
f.UserData.pPart.BackgroundColor = [0.5 1 0.5];

if isfield(f.UserData,'pProj')
    welkeProj = f.UserData.popupProj.Value-1;
    ProjName = f.UserData.uProjName{welkeProj};
    ProjDate = f.UserData.uProjDate{welkeProj};
    % only search for particpant recordings within a project, so get
    % that index first
    indexProj = strcmp(f.UserData.ProjName,ProjName) & strcmp(f.UserData.ProjDate,ProjDate);
    indexPart = strcmp(f.UserData.PartName,PartName);
    index = indexProj & indexPart;
else
    index = strcmp(f.UserData.PartName,PartName);
end

f.UserData.uRecName = f.UserData.RecName(index);
f.UserData.uRecDate = f.UserData.RecDate(index);
f.UserData.uRecDur  = f.UserData.RecDur(index);
f.UserData.uRecLabel= cellfun(@(x,y,z) [x ', recorded: ' y ', duration: ' z ' s'],f.UserData.uRecName,f.UserData.uRecDate,f.UserData.uRecDur,'uni',false);

f.UserData.popupRec.String = [{'<select recording>'}; f.UserData.uRecLabel];
f.UserData.popupRec.Value = 1;

f.UserData.pRec.BackgroundColor = [1 0.5 0.2];
f.UserData.CalStat.String = 'Unknown';
f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];

if sum(index) == 1
    % only one recording available, preselect
    f.UserData.popupRec.Value = 2;
    changeRec(f.UserData.popupRec,[]);
end
end

function changeRec(src,~)
f = src.Parent;

welkeRec = src.Value-1;
if welkeRec==0
    f.UserData.pRec.BackgroundColor = [1 0.5 0.2];
    f.UserData.CalStat.String = 'Unknown';
    f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];
    return;
end
RecName = f.UserData.uRecName{welkeRec};
RecDate = f.UserData.uRecDate{welkeRec};

welkePart = f.UserData.popupPart.Value-1;
PartName = f.UserData.uPartName{welkePart};

% only search for particpant recordings within a project,
% so get that index first
indexPart = strcmp(f.UserData.PartName,PartName);
indexRec  = strcmp(f.UserData.RecName, RecName) & strcmp(f.UserData.RecDate, RecDate);
if isfield(f.UserData,'pProj')
    welkeProj = f.UserData.popupProj.Value-1;
    ProjName = f.UserData.uProjName{welkeProj};
    ProjDate = f.UserData.uProjDate{welkeProj};
    indexProj = strcmp(f.UserData.ProjName,ProjName) & strcmp(f.UserData.ProjDate,ProjDate);
    index = indexProj & indexPart & indexRec;
else
    index = indexPart & indexRec;
end

f.UserData.pRec.BackgroundColor = [0.5 1 0.5];
tempCalStatus = f.UserData.CalStatus{index};
if strcmp(tempCalStatus,'calibrated')
    f.UserData.CalStat.String = tempCalStatus;
    f.UserData.CalStat.BackgroundColor = [0.5 1 0.5];
elseif strcmp(tempCalStatus,'failed')
    f.UserData.CalStat.String = tempCalStatus;
    f.UserData.CalStat.BackgroundColor = [1 0.5 0.5];
else
    f.UserData.CalStat.String = 'Unknown';
    f.UserData.CalStat.BackgroundColor = [1 0.5 0.2];
end

f.UserData.pRec.BackgroundColor = [0.5 1 0.5];
if f.UserData.isG2
    temprecfolder = fullfile(f.UserData.projfolder,f.UserData.ProjID{index},'recordings',f.UserData.RecID{index});
    if exist(temprecfolder,'dir')~=7
        % f.UserData.projfolder might be a specific project's folder, retry
        % with that
        temprecfolder = fullfile(f.UserData.projfolder,'recordings',f.UserData.RecID{index});
    end
else
    temprecfolder = fullfile(f.UserData.projfolder,f.UserData.RecID{index});
end
f.UserData.recfolder = temprecfolder;
end

function useRec(src,~)
f = src.Parent';
assignin('caller','recfolder',f.UserData.recfolder);
close(f);
end

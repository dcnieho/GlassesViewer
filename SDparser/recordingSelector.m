function recfolder = recordingSelector(projectfolder)

data.projfolder = projectfolder;

f = figure;
set(f,'Name','Select Recording','NumberTitle','off');
set(f,'MenuBar','none');
set(f,'DockControls','off');
set(f,'Resize','off');
set(f,'Position',[0 0 440 340]);
set(f,'Units','pixels');

if exist(fullfile(projectfolder,'lookup.xls'),'file')
    fid = fopen(fullfile(projectfolder,'lookup.xls'));
    fgetl(fid);
    C = textscan(fid,repmat('%s',1,17),'delimiter','\t');
    fclose(fid);
    
    data.ProjID = C{1};
    data.ProjName = C{5};
    data.ProjDate = C{6};
    
    data.PartID = C{2};
    data.PartName = C{7};
    
    data.RecID = C{3};
    data.RecName = C{9};
    data.RecDate = C{10};
    
    data.CalID = C{4};
    data.CalStatus = C{12};
    
    [data.uProjID,i] = unique(data.ProjID);
    data.uProjName = data.ProjName(i);
    data.uProjDate = data.ProjDate(i);
    data.uProjLabel= cellfun(@(x,y) [x ', created: ' y],data.uProjName,data.uProjDate,'uni',false);
    set(f,'userdata',data);
else
    disp('No lookup table available for this projects folder');
    return
end

data.pProj = uipanel('Title','Project','Units','pixels','Position',[10 280 420 50],'BackgroundColor',[1 .5 0.2]);
data.popupProj = uicontrol('Style', 'popup',...
    'String', [{'<select project>'}; data.uProjLabel],...
    'Position', [20 260 400 50],...
    'Value',1,'CallBack',@changeProj);

data.pPart = uipanel('Title','Participant','Units','pixels','Position',[10 220 420 50],'BackgroundColor',[1 .5 0.2]);
data.popupPart = uicontrol('Style', 'popup',...
    'String', 'first select a project',...
    'Position', [20 200 400 50],...
    'Value',1,'CallBack',@changePart);

data.pRec = uipanel('Title','Recording','Units','pixels','Position',[10 160 420 50],'BackgroundColor',[1 .5 0.2]);
data.popupRec = uicontrol('Style', 'popup',...
    'String', 'first select a project',...
    'Position', [20 140 400 50],...
    'Value',1,'CallBack',@changeRec);

data.pCal = uipanel('Title','Calibration status:','Units','pixels','Position',[10 100 420 50]);
data.CalStat = uicontrol('Style', 'text',...
    'String', 'Unknown',...
    'Position', [20 110 400 20],...
    'Value',1,'BackgroundColor',[1 .5 0.2]);


data.butOK = uicontrol('Style','pushbutton',...
    'String','Use selected recording',...
    'Position', [20 30 400 50],...
    'Value',1,'CallBack',@useRec);
movegui(f,'center');

data.recfolder = '';
set(f,'userdata',data);
recfolder =[];
waitfor(f);

    function changeProj(src,~)
        hf = get(src,'Parent');
        data = get(hf,'userdata');
        welkeProj = get(src,'Value')-1;
        if welkeProj==0
            set(data.pProj,'BackgroundColor',[1 0.5 0.2]);
            set(data.pPart,'BackgroundColor',[1 0.5 0.2]);
            set(data.popupPart,'Value',1);
            set(data.popupPart,'String','first select a project');
            set(data.pRec ,'BackgroundColor',[1 0.5 0.2]);
            set(data.popupRec ,'Value',1);
            set(data.popupRec ,'String','first select a project');
            set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
            return;
        end
        ProjName = data.uProjName{welkeProj};
        ProjDate = data.uProjDate{welkeProj};
        index = strcmp(data.ProjName,ProjName) & strcmp(data.ProjDate,ProjDate);
        
        tempPartName = data.PartName(index);
        data.uPartName = unique(tempPartName);
        set(data.pPart,'BackgroundColor',[1 0.5 0.2]);
        set(data.popupPart,'Value',1);
        set(data.popupPart,'String',[{'<select participant>'}; data.uPartName]);
        
        set(data.pRec,'BackgroundColor',[1 0.5 0.2]);
        set(data.popupRec ,'Value',1);
        set(data.popupRec ,'String','first select a participant');
        
        set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
        
        set(data.pProj,'BackgroundColor',[0.5 1 0.5]);
        
        set(hf,'userdata',data);
        
        if sum(index) == 1
            % only one participant available, preselect
            set(data.popupPart,'Value',2);
            changePart(data.popupPart,[]);
        end
    end

    function changePart(src,~)
        hf = get(src,'Parent');
        data = get(hf,'userdata');
        
        welkePart = get(src,'Value')-1;
        if welkePart==0
            set(data.pPart,'BackgroundColor',[1 0.5 0.2]);
            set(data.pRec ,'BackgroundColor',[1 0.5 0.2]);
            set(data.popupRec ,'Value',1);
            set(data.popupRec ,'String','first select a participant');
            set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
            return;
        end
        PartName = data.uPartName{welkePart};
        set(data.pPart,'BackgroundColor',[0.5 1 0.5]);
        
        welkeProj = get(data.popupProj,'Value')-1;
        ProjName = data.uProjName{welkeProj};
        ProjDate = data.uProjDate{welkeProj};
        % only search for particpant recordings within a project, so get
        % that index first
        indexProj = strcmp(data.ProjName,ProjName) & strcmp(data.ProjDate,ProjDate);
        indexPart = strcmp(data.PartName,PartName);
        
        index = indexProj & indexPart;
        
        data.uRecName = data.RecName(index);
        data.uRecDate = data.RecDate(index);
        data.uRecLabel= cellfun(@(x,y) [x ', recorded: ' y],data.uRecName,data.uRecDate,'uni',false);
        
        set(data.popupRec,'String',[{'<select recording>'}; data.uRecLabel]);
        set(data.popupRec,'Value',1);
        
        set(data.pRec,'BackgroundColor',[1 0.5 0.2]);
        set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
        
        
        set(hf,'userdata',data)
        
        if sum(index) == 1
            % only one recording available, preselect
            set(data.popupRec,'Value',2);
            changeRec(data.popupRec,[]);
        end
    end

    function changeRec(src,~)
        hf = get(src,'Parent');
        data = get(hf,'userdata');
        
        welkeRec = get(src,'Value')-1;
        if welkeRec==0
            set(data.pRec ,'BackgroundColor',[1 0.5 0.2]);
            set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
            return;
        end
        RecName = data.uRecName{welkeRec};
        RecDate = data.uRecDate{welkeRec};
        
        welkePart = get(data.popupPart,'Value')-1;
        PartName = data.uPartName{welkePart};
        welkeProj = get(data.popupProj,'Value')-1;
        ProjName = data.uProjName{welkeProj};
        ProjDate = data.uProjDate{welkeProj};
        
        % only search for particpant recordings within a project,
        % so get that index first
        indexProj = strcmp(data.ProjName,ProjName) & strcmp(data.ProjDate,ProjDate);
        indexPart = strcmp(data.PartName,PartName);
        indexRec  = strcmp(data.RecName, RecName) & strcmp(data.RecDate, RecDate);
        index = indexProj & indexPart & indexRec;
        
        set(data.pRec,'BackgroundColor',[0.5 1 0.5]);
        tempCalStatus = data.CalStatus{index};
        if strcmp(tempCalStatus,'calibrated')
            set(data.CalStat,'String', tempCalStatus,'BackgroundColor',[0.5 1 0.5]);
        elseif strcmp(tempCalStatus,'failed')
            set(data.CalStat,'String', tempCalStatus,'BackgroundColor',[1 0.5 0.5]);
        else
            set(data.CalStat,'String', 'Unknown','BackgroundColor',[1 0.5 0.2]);
        end
        
        set(data.pRec,'BackgroundColor',[0.5 1 0.5]);
        data.recfolder = fullfile(data.projfolder,data.ProjID{index},'recordings',data.RecID{index});
        set(hf,'userdata',data)
    end

    function useRec(src,~)
        hf = get(src,'Parent');
        data = get(hf,'userdata');
        assignin('caller','recfolder',data.recfolder);
        close(hf);
    end
end

function [yLim,unit,pType] = getPlotLimUnitType(panel, plotData, plotSettings, data_video_scene)

yLim = [];
if isfield(plotSettings.lims,panel)
    lim = plotSettings.lims.(panel);
    if isscalar(lim)
        yLim = [-lim lim];
    else
        yLim = lim;
    end
end
if isempty(yLim) || ismember(panel,plotSettings.adjustLimsToData)
    switch panel
        case 'videoGaze'  % gaze point video
            lim = [0 max([data_video_scene.width data_video_scene.height])];
        case 'vel'  % velocity
            lim = [0 nanmax(cellfun(@nanmax,plotData{2}))];
        case 'pup'  % pupil
            lim = [0 nanmax(cellfun(@nanmax,plotData{2}))];
        otherwise
            % just take range of data
            mins = cellfun(@nanmin,plotData{2});
            maxs = cellfun(@nanmax,plotData{2});
            lim = [nanmin(mins) nanmax(maxs)];
    end
    if ismember(panel,plotSettings.adjustLimsToData) && ~isempty(yLim)
        yLim = [max([yLim(1) lim(1)]) min([yLim(2) lim(2)])];
    else
        yLim = lim;
    end
end


switch panel
    case {'azi','ele'}
        unit = 'deg';
    case 'videoGaze'
        unit = 'pix';
    case {'gazePoint3D','pup','pupCentLeft','pupCentRight'}
        unit = 'mm';
    case {'vel','gyro'}
        unit = 'deg/s';
    case 'acc'
        unit = 'm/s^2';
    case 'magno'
        unit = '\mu T';
    otherwise
        assert(isfield(plotSettings,'units')&&isfield(plotSettings.units,panel),'Stream %s is not built-in, you must provide panel unit for it to be plotted',panel);
        unit = plotSettings.units.(panel);
end


switch panel
    case {'azi','ele','vel','pup'}
        pType = 'lr';
    case {'videoGaze','gazePoint3D','pupCentLeft','pupCentRight','gyro','acc','magno'}
        pType = 'xyz';
    otherwise
        assert(isfield(plotSettings,'type')&&isfield(plotSettings.type,panel),'Stream %s is not built-in, you must provide panel type for it to be plotted',panel);
        pType = plotSettings.type.(panel);
end
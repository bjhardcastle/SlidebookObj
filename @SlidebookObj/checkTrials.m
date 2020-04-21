function varargout = checkTrials(obj , trialsettings, trialstarts, trialends)
%CHECKTRIALS Plot currently detected trial start/stop times
% checkFig = checkTrials(obj, trialsettings, trialstarts, trialends)
%
% A function for checking trial start/stop times. Run with no inputs
% (except obj) to plot currently stored trialtimes. Or test new settings by
% providing input arguments.
%
% This function accepts the following input:
%
%   trialstarts  -   (optional) [Nx1] array of trial start times, as Daq
%                               sample index
%
%   trialends    -   (optional) [Nx1] array of trial stop times, as Daq
%                               sample index
%
%   trialsettings-   (optional) structure with fields for customizing trial
%                               start/stop detections (see getTrialtimes)
%
% This function returns the following output:
%
%   checkFig     -   (optional) figure handle for plot of trial times
%
%
% See also getTrialtimes.

if nargin < 4
    trialsettings = obj.TrialSettings;
end
if nargin == 1
    if isempty( obj.TrialStartSample ) || isempty( obj.TrialSettings )
        getTrialtimes(obj);
    end
    if isempty( obj.TrialStartSample ) || isempty( obj.TrialSettings )
        return
    else
        trialstarts = obj.TrialStartSample;
        trialends = obj.TrialEndSample;
    end
    
end

if isempty( obj.Daq )
    getDaqData(obj);
end

wstim = obj.Daq;

checkFig = figure;
axes
ax = checkFig.CurrentAxes;
% Plot DAQ AI channels
col = ax.ColorOrder(ax.ColorOrderIndex,:);
brightcol = col+(1-col)*0.55;
idxvec = [1:trialsettings.setlimits(1)];
plot(ax, idxvec, wstim(idxvec,trialsettings.chan), 'color',brightcol )
hold on
idxvec = [trialsettings.setlimits(1):trialsettings.setlimits(2)];
line1 = plot(ax, idxvec, wstim(idxvec,trialsettings.chan), 'color',col);
idxvec = [trialsettings.setlimits(2):size(wstim,1)];
plot(ax, idxvec, wstim(idxvec,trialsettings.chan), 'color',brightcol )

% Plot detected trialtimes on top
pt1 = plot(ax, trialstarts,wstim(trialstarts,trialsettings.chan),'go');
pt2 = plot(ax, trialends,wstim(trialends,trialsettings.chan),'r*');
hold off
% xlim(ax,trialsettings.setlimits);
legend(ax,[line1 pt1 pt2],['DAQ(:,' num2str(trialsettings.chan) ')'],['Trial starts (' num2str(length(trialstarts)) ')'],['Trial stops (' num2str(length(trialends)) ')'])

% If figure handle was requested:
if nargout == 1
    varargout{1} = checkFig;
end
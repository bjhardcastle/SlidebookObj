function varargout = plotStimPatch(obj,taxes,stimOnOff,chanStr,patchcolor)
%PLOTSTIMPATCH Add a patch to the specified axes to indicate stimulus duration
% [patchHandle] = plotStimPatch(obj,taxes,stimOnOff,chanStr,patchcolor)
% 
% Uses panels movement data returned by getParameters. A patch is drawn
% between the stimulus ON time and stimulus OFF time, between the yaxis
% minimum and maximum.
%
% This function accepts the following input:
%
%   taxes        -   (optional) Figure axes handle where patch will be
%                               added. Defualt is the current axes.
%
%   stimOnOff    -   (optional) [1x2] array of times (in seconds) for the
%                               stimulus [start stop]
%
%   chanStr      -   (optional) Specify the channel ('x' or 'y') which the
%                               stimulus was displayed on. By default, x is
%                               tried first. If no movement was found on
%                               x (x-gain = 0 in every trial), then y is
%                               tried. 
%
%   patchcolor   -   (optional) Manually choose patch color (RGB). Useful
%                               if multiple patches are plot.
%                               Default is light grey: [0.85 0.85 0.85]
%
% See also getParameters.

% If there's no Panels movement info stored in the object:
if isempty(obj.ExpXOnTime) && isempty(obj.ExpYOnTime)
    disp('Running getParameters...')
end

% If no axes are specified:
if nargin<2 || isempty(taxes)
    taxes = gca;
end

% If the times are specified as an input:
if nargin >= 3 && ~isempty(stimOnOff)
    
    timeON = stimOnOff(1);
    timeOFF = stimOnOff(2);
    
% Otherwise, try 'x' channel first ( if chanStr wasn't specified )
elseif nargin <4 || ~ischar(chanStr) || isempty(chanStr)
    
        if ~any(isnan([obj.ExpXOnTime]))
            timeON = mean( [obj.ExpXOnTime] );
            timeOFF= mean( [obj.ExpXOffTime] );
        
        
        else % Then try 'y' channel if 'x' didn;t move
            timeON = mean( [obj.ExpYOnTime] );
            timeOFF= mean( [obj.ExpYOffTime] );
        end
        
elseif ischar(chanStr) 
    % ChanStr was specified: Use that channel 
    
    if strcmp(chanStr,'x')
        % Get stim on/off time
        if ~any(isnan([obj.ExpXOnTime]))
            timeON = mean( [obj.ExpXOnTime] );
            timeOFF= mean( [obj.ExpXOffTime] );
        else
            error('obj.ExpXOnTime contains NaN values - cannot plot patch')
        end
        
    elseif strcmp(chanStr,'y')
        % Get stim on/off time
        if ~any(isnan([obj.ExpYOnTime]))
            timeON = mean( [obj.ExpYOnTime] );
            timeOFF= mean( [obj.ExpYOffTime] );
        else
            error('obj.ExpXOnTime contains NaN values - cannot plot patch')
        end
    else
        error('Please specify a channel (''x'' or ''y'') for the stimulus patch')
    end
else
    error('Please specify channel (''x'' or ''y'') as a string')
end

% If patchcolor is specified:
if nargin < 5 || ~(length(patchcolor) == 3)
    patchcolor = [0.85 0.85 0.85];
    if ischar(patchcolor)
        disp('Please input ''patchcolor'' as [1x3] array of RGB values.')
    end
end

% Store axis Ylims before plotting
ylimits = taxes.YLim;
yticks = taxes.YTick;

% Get patch position arrays:
x = [timeON timeON timeOFF timeOFF];
y = [ylimits(1) ylimits(2) ylimits(2) ylimits(1)];

% Draw the patch
stimPatch = patch(taxes, x,y, patchcolor, 'EdgeColor', 'none');

% % This keeps the stim patch across the whole y-extent even when resizing axes
% % No longer used. CPU usage is bonkers. 
% addlistener (taxes, 'MarkedClean', @(object,event)setPatchY(taxes,stimPatch));

% Restore axis YLims
taxes.YLim = ylimits;
% Move to bottom layer
uistack(stimPatch,'bottom')
taxes.Layer = 'Top';

taxes.YLimMode = 'auto';

% Return handle if requested
if nargout
    varargout{1} = stimPatch;
end
end

function setPatchY(ax,patch)

upper  = ax.YLim(2);
lower = ax.YLim(1);
patch.YData(1) = lower;
patch.YData(4) = lower;
patch.YData(2) = upper;
patch.YData(3) = upper;
ax.YLimMode = 'auto';
end
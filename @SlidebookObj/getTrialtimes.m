function getTrialtimes(obj)
%GETTRIALTIMES Gets trial starts / ends from DAQ AI Ch2 or 3
%
% Detection of trials is divided into two functions:
%
%  getTrialtimes - parses inputs and outputs
%                - checks trialtimes before assigning to object
%                - can be customized or overloaded in subclass
%
%  detectTrials  - core code with detection medthod
%                - not intended for modification or overloading
%
% To modify how trials are detected:
%   - override default TrialSettings in the object classdef file
%   - edit this function
%   - modify the arrays 'trystarts' / 'tryends' below, which are
%     retured from 'detectTrials'
%
% These are the settings which can be modified by assigning a non-default
% value in the classdef file:
%
%   obj.TrialSettings.chan            - DAQ channel number which has trial
%                                       markers on. Usually this is 
%                                       obj.Daq(:,2) or obj.Daq(:,3)
%                                       Default is 2
%
%   obj.TrialSettings.setlimits       - [1x2] array, marking [start end] of
%                                       DAQ data to be used for detection:
%                                       obj.Daq(setlimits(1):setlimits(2),chan)
%                                       The entire length of DAQ data is
%                                       normally used, but this setting may
%                                       be useful if distinct sets of
%                                       trials are used and should be
%                                       separated to distinguish
%                                       repetitions.
%                                       Default is [1 size(obj.Daq,1)] 
%
%   obj.TrialSettings.joined          - The detection method expects trial
%                                       markers to consist of a near-zero 
%                                       voltage, followed by a rising-edge,
%                                       followed by a falling edge at the
%                                       end of the trial:   __¬__¬__¬__
%                                       If markers were output without the
%                                       zero voltage period between trials,
%                                       as in Sufia's L2 experiments, they
%                                       will not be detected correctly.
%                                       Set 'joined' to 1 to detect these
%                                       trials:             __¬¬¬¬¬¬¬__
%                                       Default is 0
% 
%   obj.TrialSettings.minpeak         - Changes in DAQ voltage signal are
%                                       found with the 'diff' function.
%                                       Peaks in this signal are then
%                                       detected. 'minpeak' is the minimum
%                                       amplitude to be counted as a
%                                       possible trial marker start/end. If
%                                       trials aren't being detected, or
%                                       too many detected, try
%                                       lowering/raising this value.
%                                       Default is 0.1

%                                       Reasoning being: 10V AI range / 96
%                                       panel pixels = 0.1042, usually the
%                                       smallest voltage increments on DAQ
%                                       
%   obj.TrialSettings.firstTrialError - It's expected that every trial
%                                       marker is preceded by a near-zero 
%                                       voltage. If the voltage was not set
%                                       to zero at the start of the
%                                       experiment (can happen when a
%                                       previous experiment was ended
%                                       early by an error) the first trial
%                                       might not be detected properly.
%                                       Set 'fristTrialError' to 1 to
%                                       attempty  to rectify this problem.%                                       
%                                       Default is 0
%
%   obj.TrialSettings.plotflag        - Calls the function 'checkTrials'
%                                       after detection. Set 'plotflag' to 
%                                       1 to plot trial starts/end as soon
%                                       as they're found.                                     
%                                       Default is 0
% 
%
% This function writes to object:
%    
%   obj.TrialStartSample    - Each trial's start time, in DAQ samples
%   obj.TrialEndSample      - Each trial's end time, in DAQ samples
%
%   obj.TrialStartFrame     - Each trial's start time, in frame number  
%   obj.TrialEndFrame       - Each trial's end time, in frame number
% 
%   obj.TrialSettings       - Settings used for the trialtimes stored.
% 
%
% See also detectTrials.

if isempty(obj.DaqFile)
    disp('No DAQ file exists - try running ''getDaqFile(obj)''')
    return
end

% Daq data and frametimes are required for trial detection:
if isempty(obj.Frametimes)
    getFrametimes(obj);
end
if isempty(obj.Daq)
    getDaqData(obj);
end

% Get settings for detection.
if ~isempty(obj.TrialSettings)
    ts = obj.TrialSettings;
else
    ts = struct;
end
% The following fields can be assigned in obj.TrialSettings:
if ~isfield(ts,'chan')
    ts.chan = 2;
end
if ~isfield(ts,'setlimits')
    ts.setlimits = [1 size(obj.Daq,1)];
end
if ~isfield(ts,'joined')
    ts.joined = 0;
end
if ~isfield(ts,'minpeak')
    ts.minpeak = 0.1;
end
if ~isfield(ts,'firstTrialError')
    ts.firstTrialError = 0;
end
if ~isfield(ts,'plotflag')
    ts.plotflag = 0;
end

% Main code:

% Find trial times in DAQ signal with settings specified:
[trystarts, tryends] = detectTrials(obj,ts);


%
%    Opportunity to modify detected times here..
%


% Check trialtimes seem reasonable:
if ( length(trystarts)==length(tryends) ) && ( all(trystarts<tryends) )
    trialstarts = trystarts;
    trialends = tryends;
else
    %If not, plot the problematic trials:
    checkTrials(obj, ts, trystarts, tryends);
    title('Check for errors: no trials saved to object')
    % And don't save anything to the object:
    trialstarts = [];
    trialends = [];
    ts = [];
    return
end

% When finished, push to obj :

% Trial starts / ends
%Saved as sample number:
obj.TrialStartSample = trialstarts;
obj.TrialEndSample = trialends;
% Saved as Frame number:
obj.TrialStartFrame = nextFrame(obj,trialstarts);
obj.TrialEndFrame = prevFrame(obj,trialends);

% The current parameters:
obj.TrialSettings = ts;



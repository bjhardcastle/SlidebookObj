function getParameters(obj)
%GETPARAMETERS Extract additional trial parameters from saved DAQ data
% getParameters(obj)
%
% For each saved .tiff file, a single .mat file is usually saved by Matlab
% with time-series data from the DAQ that contains control signals to the
% LED panels, frame-time markers, user-defined trial markers, pattern-
% number and sequence-number markers, plus signals from auxillary
% equipment, such as temperature probes or wingbeat analysers.
%
% Functions 'getFrametimes' and 'getTrialtimes' extract the minimum data
% required for a basic analysis.
% This function extracts any additional data.
%
% Subfunctions do the basic detection of peaks etc. on signals. These
% should generally be left alone - just modify the input arguments to
% tweak. This parent function assigns parameters to the object and is the
% one that should be customized if needed.
%
% Currently, the function saves to the object:
%
% Different values per trial:   all [1 x numTrials] arrays:
%       obj.TrialPatNum         Voltage level on DAQ(:,2) multiplied by 5
%       obj.TrialSeqNum         Voltage level on DAQ(:,3) multiplied by 5
%       obj.TrialXGain          Panels X gain from DAQ(:,5)
%       obj.TrialYGain          Panels Y gain from DAQ(:,4)
%       obj.TrialCh6            Voltage level on DAQ(:,6) if it exists
%       obj.TrialCh7            Voltage level on DAQ(:,7) if it exists
%
% Note:
% The default behaviour is panels X data on ch5 | Y data on ch4
% This can be reversed by assigning the following parameter value:
%          obj.SwitchXYDaqChans = 1
% 
% Similarly, default is Pattern Number on ch2 | Sequence Numbero n ch3
% This can be reversed by assigning the following parameter value:
%          obj.SwitchPatSeqDaqChans = 1
%
% Same values for entire object:
%       obj.ExpXGains           Array of X gains used in experiment
%       obj.ExpYGains           Array of Y gains used in experiment
%       obj.ExpXOnTime          Median stimulus onset/offset, in seconds
%       obj.ExpXOffTime         (relative to trial onset: used to indicate
%       obj.ExpYOnTime          stimulus region in 'plotTrials')
%       obj.ExpYOffTime
%
% To be added, if required:
%                               Stimulus position (static)
%                               Timing of changes in static stim position
%
% See also getTrialtimes, getDaqData, getFrametimes.

if isempty(obj.TrialStartFrame)
    getTrialtimes(obj);
end
if isempty(obj.Daq)
    getDaqData(obj)
end

% For each trial find some parameters from the DAQ file:
% for each trial,
% for each channel (except daq(:,1))
% get voltage level or slope
ch6 = [];
ch7 = [];
for tidx = 1:length(obj.TrialStartFrame)
    
    % Get ch2 mean voltage within trials 
    ch2(tidx) = mean( obj.Daq( obj.TrialStartSample(tidx) : obj.TrialEndSample(tidx) ,2) );
    
    % Get ch3 mean voltage within trials 
    ch3(tidx) = mean(obj.Daq( obj.TrialStartSample(tidx) : obj.TrialEndSample(tidx) ,3) );
    
    % If it exists, get the max voltage within trials on channel 6, which is connected directly to the LED analog input
    if size(obj.Daq,2) >= 6
        % voltage amplitude obj.Daq(:,6)
		va6 = obj.Daq( obj.TrialStartSample(tidx) : obj.TrialEndSample(tidx) ,6);
		% sample idx where voltage is above 0
		th6 = obj.Daq( obj.TrialStartSample(tidx) : obj.TrialEndSample(tidx) ,6) > 0.01;
        ch6(tidx) = mean(va6(th6));
    end
    % If it exists, get the mean voltage within trials on channel 7
    if size(obj.Daq,2) >= 7
        % voltage amplitude obj.Daq(:,7)
        ch7(tidx) = mean(obj.Daq( obj.TrialStartSample(tidx): obj.TrialEndSample(tidx) ,7) );
    end
    
end

% Get Panels x- and y-gain values (not assigned at this point):
panels_refresh_rate = 50; % Approximate value is sufficient - used as a threshold
ch4gain = detectTrialGains(obj, 4, panels_refresh_rate);
ch5gain = detectTrialGains(obj, 5, panels_refresh_rate);

% % Push to object:

% X and Y Gains
% Default behaviour is x on ch5, y on ch4
% These can be reversed by adding a property to the object and setting it
% to 1:
if isprop(obj,'SwitchXYDaqChans') && ~isempty(obj.SwitchXYDaqChans) && obj.SwitchXYDaqChans == 1
    obj.TrialXGain = ch4gain;
    obj.TrialYGain = ch5gain;
else
    obj.TrialXGain = ch5gain;
    obj.TrialYGain = ch4gain;
end
obj.ExpXGains = unique(obj.TrialXGain);
obj.ExpYGains = unique(obj.TrialYGain);

% Ch2 and Ch3 data
% Default behaviour is patternNum on ch2, sequenceNum on ch3 
% These can also be reversed by adding a property to the object and setting it
% to 1:
patternNum = round(ch2*5); % obj.Daq(:,2) voltage x 5
sequenceNum = round(ch3*5); % obj.Daq(:,3) voltage x 5
if isprop(obj,'SwitchPatSeqDaqChans') && ~isempty( obj.SwitchPatSeqDaqChans ) && obj.SwitchPatSeqDaqChans == 1
    obj.TrialPatNum = sequenceNum;
    obj.TrialSeqNum = patternNum;
else
    obj.TrialPatNum = patternNum;
    obj.TrialSeqNum = sequenceNum;
end

% Ch6 and Ch7 data
obj.TrialLED = round(ch6,2);
obj.TrialCh7 = round(ch7);


% Display results
disp(['ExpXGains found: [' regexprep(num2str(obj.ExpXGains),'\s{1,}',' ') ']']);
disp(['ExpYGains found: [' regexprep(num2str(obj.ExpYGains),'\s{1,}',' ') ']']);


% Now get stimulus onset/offsets from ch4 and ch5 ( relies on obj.TrialXGain
% and obj.TrialYgain that we just found, so this must be run after previous
% info has already been found)

disp('Detecting stimulus on/off times..')


[obj.ExpXOnTime, obj.ExpXOffTime, obj.TrialXOnFrame, obj.TrialXOffFrame] = ...
    detectPanelsMovement(obj,'x');
[obj.ExpYOnTime, obj.ExpYOffTime, obj.TrialYOnFrame, obj.TrialYOffFrame] = ...
    detectPanelsMovement(obj,'y');


disp('Done.')
end
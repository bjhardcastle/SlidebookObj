function [timeVector, normFPS, trialDuration] = findStandardTrial(objarray)
%FINDSTANDARDTRIAL Find an appropriate trial length for resampling trials of different lengths
% [timeVector, normFPS, trialDuration] = findStandardTrial(objarray)
%
% We will commonly have trials of different lengths across experiments (or
% even within an experiment) due to differences in framerate. This function
% looks at all of the trials across the objects in an object array and,
% based on the average trial length, guesses what the 'actual' trial length
% should be in seconds. Then, based on the longest trial, finds a standard
% sampling rate, 20x higher than the highest original frame rate to ensure
% peaks in the data are captured fairly accurately. 
%
% All trials should then be upsampled to match the standard trial for
% plotting and taking averages.
%
% The major assumption is that all trials were intended to be the same
% length. If a mix of shorter and longer trials was used in experiments, 
% this function will not work.
%
% There isn't a convenient way to store the calculated standard trial
% parameters for an array of objects so this function should just be called 
% on-demand each time re-sampling is required.
%
% To ensure good interpolation of signal, we'll enforce a rate of at least
% 20x higher than the minimum trial recording frame rate across all trials.
% Fly vision experiments are not long and original frame rate is never high
% enough for this to cause excessive trial lengths.
%
% For the start/end of the standard trial, we get funny results where we
% average trials when only some have data points, and as we get to the
% extremes of the time vector, fewer and fewer trials will have data.
% To avoid this, we start/end at 1 x average frame-interval in from either 
% end, where all of the trials should have a data point for averaging. 
%
% This won't affect relative timings. It's akin to setting the x-axis 
% limits slightly tighter. However, the last entry in timeVector will now
% not equal the estimated trial duration should, which is why the output
% trialDuration is made available. 
%
%
% Must be run before this function (for every object in array): 
%   getTrialtimes(obj)
%
%
% This function returns the following outputs:
% 
%   timeVector      - [1xN] vector of time-points, in seconds, for the
%                     standard trial length. 
%                     N = approx. mean(length(trial))*20
%                     Can be used as x-data for time-series plots. 
%
%   normFPS         - the standard sampling rate used for upsampled trials
%                     and time-series plots. Frames per second.
% 
%   trialDuration   - the estimated duration of the experiments' trials, 
%                     in seconds, rounded to 1 decimal place. 
%
% See also findRespArray, plotTrials.


% Work out the most common trial duration in seconds:
% Duration is: endFrame - startFrame + 1 
c1 = {objarray.TrialEndFrame};
c0 = {objarray.TrialStartFrame};
trial_frames = cellfun(@minus,c1,c0,'Un',0);
% ( we add the 1 on line 72: (median_frames+1) )

% Median frames per trial, for each object
median_frames = cellfun(@median,trial_frames); 

% Divide by frame-rate to get trial duration, in seconds, for each object
durations = (median_frames+1).*[objarray.IFI]./[objarray.AIrate]; 

% Mean trial duration in seconds
trialDuration = round(mean(durations),1); 

% Check if any trials are significantly different (+/- 0.1*length) to the
% mean trial duration in frames
% Subtract median length from each trial length to get differences:
diff_to_mean = cellfun(@minus,trial_frames,num2cell(median_frames),'Un',0);
% Express differences as proportions of length:
proportional_diff = cellfun(@mrdivide,diff_to_mean,trial_frames);
% Check whether any are more than 10% different to the median length:
if any( abs(proportional_diff) > 0.1)
    disp('<a href="matlab:opentoline(''findStandardTrial.m'',84)">Line 84: findStandardTrial</a>')
    disp('Some trials may be a different length')
end

% Work out the highest frame rate across all trials
% Find the longest trial length (in num frames):
allTlengths = ([objarray.TrialEndFrame])-([objarray.TrialStartFrame]) + 1;
maxTlength = max(allTlengths);
assert(maxTlength > 1, 'Some trials have been detected incorrectly (length = 1 frame)');

% Sampling rate of standard trial (frames per second):
normFPS = 20*maxTlength / trialDuration;

% Get bounds for time vector from average frame-interval:
oneFrame = mean([objarray.IFI]./[objarray.AIrate]);

% Make standard trial time vector:
timeVector = [oneFrame:1/normFPS:trialDuration-oneFrame];

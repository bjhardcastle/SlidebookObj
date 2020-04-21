function fittedData = findFittedTrial(obj, trialData, trialIdx, timeVector, normFPS, trialDuration)
%FINDFITTEDTRIAL Fit trial data to standard trial time vector by interpolation
% fittedData = findFittedTrial(obj, trialData, trialIdx, timeVector, normFPS, trialDuration)
%
% Simple function for interpolating a single trial's time-series data to
% fit the standard trial length and time vector, found with
% findStandardTrial.
%
% Two options are available, selected with obj.AccurateInterpolation:
%
%  obj.AccurateInterpolation  = 1  (default) Use this if all trial lengths
%                                  in your experiment were intended to be 
%                                  equal. Finds precise timing of
%                                  individual frames relative to the trial
%                                  start.
%
%  obj.AccurateInterpolation  = 0  Use this if your experiment contained a 
%                                  mix of trial lengths, but you want to
%                                  scale them all to the same duration.
%                                  This is bad practice and ideally you 
%                                  should analyze each group of trial 
%                                  lengths separately, fitting them to 
%                                  their own standard trial length. 
% 
%
% This function accepts the following inputs:
% 
%  trialData                -    [1xN] time-series data, from scanROI
%
%  trialIdx                 -    index of the trial within the object
%
%  timeVector               -    [1xM] vector of points in time, from 0 to
%  trialDuration                 trialDuration, with interval normFPS.
%  normFPS                       These are outputs from findStandardTrial,
%                                which should be run on the entire array of
%                                objects in the experiment. trialData will
%                                be interpolated to match the sampling of
%                                trialData. 
%
% This function returns the following outputs:
%
%  fittedData              -    [1xM] interpolated time-series data.
%                               length(fittedData) >> length(trialData)
%
% See also findStandardTrial, findRespArray.

switch obj.AccurateInterpolation
    
    case 0  % Bad version, for different trial lengths: 
        % No matter how long the trial is, make a vector which runs from 0 to the
        % length of the standard trial (trialDuration)

        timeScale  = trialDuration/length(trialData);
        this_time = [ timeScale : timeScale :length(trialData)*timeScale];

    case 1 % Accurate version, for when trial lengths are consistent:
        % Get the sample index of each frame within the trial
        trial_samp_idx = [obj.Frametimes( obj.TrialStartFrame(trialIdx) : obj.TrialEndFrame(trialIdx) )];
        
        % Convert into samples relative to trial start
        trial_samp_idx_rel = trial_samp_idx - obj.TrialStartSample(trialIdx);
        
        % Convert into times, in seconds, relative to trial start
        this_time = trial_samp_idx_rel./obj.AIrate;
end

% Then interpolate the current trial data to fit the time points in the
% standard trial (timeVector)
fittedData = interp1( this_time , trialData , timeVector );
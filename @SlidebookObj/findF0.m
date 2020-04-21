function F0 = findF0(obj, mask, trialData,  trialIdx, timeVector, normFPS)
%FINDF0 Defines the time-series that will be used for each trial's baseline intensity
% F0 = findF0(obj, mask, trialData, trialIdx, timeVector, normFPS)
%
% This function is called when normalizing trial time-series data, for
% example when using 'plotTrials'. F0 values are not stored, but found
% on-demand.
%
% MUST BE CUSTOMIZED FOR YOUR EXPERIMENT!
% Choose a period of time that will be used as the F0 for each trial.
% The average intensity within an examined ROI is found for this time
% range by using either:
%  - the provided 'trialData' which has already been scanned for an ROI
%  - the input 'mask' and the 'scanROI' function
% All input arguments are optional - excess inputs are provided to ensure
% that there's sufficient information to find the correct samples to use
% for the trial F0 in every experiment, and to avoid customizing the
% function that calls this one. 
%
% Input an empty array, [], or ~, if an input is unused. 
%
% Do not edit the input argument list!
%
% This function accepts the following inputs:
%
%   mask        - logical array, representing an ROI mask. If trialData is
%                 not provided, the function 'scanROI' can be run using the
%                 appropriate ROI(idx).mask.
%
%   trialData   - time-series of intensity values for all Tiff frames,
%                 already scanned for a particular ROI. Only a time range
%                 is required to find F0 from these data.
%
%   trialIdx    - trial number. Used as an index in TrialStartFrame(idx) etc
%
%   timeVector  - standard time points, in seconds, for interpolated trial
%                 intensity data.
%
%   normFPS     - sample rate used for interpolated trial intensity data
%                 (frames per second).
%   Note:
%   The two arguments above are outputs of 'findStandardTrial', computed
%   for an object array. findF0 operates on a single object, so obtaining
%   their values through findStandardTrial here could lead to different
%   results. There is no obvious way to store a property which applies to
%   a whole object array: instead we compute their values for all objects
%   in the experiment in the function which calls findF0, and then provide
%   them as arguments.
%
% This function returns the following outputs:
%
%   F0          - a single value, representing the mean pixel intensity
%                 within an ROI, over a particular time-range. Used as the
%                 baseline intensity for normalizing a single trial with
%                 trial number 'trialIdx'
%
% See also findRespArray, findStandardTrial, plotTrials.


% The default behavior (below) is to use the following range for F0:
% [trial start-time : onset-time of stimulus ]

% If insufficient trial parameter info is available it will try to use the
% a short period before each trial

% If that also fails, the first 0.5 seconds of the trial itself is used. 

% Customize for your own use.


try % Use panel movement markers:
    
    % Get scaling to express stim onset/offset for this trial in the
    % standardized time vector:
    orig_trial_length = obj.TrialEndFrame(trialIdx) - obj.TrialStartFrame(trialIdx);
    new_trial_length = length(trialData);
    fps_scale = new_trial_length/orig_trial_length;
    
    % Find whichever panels channel moved first, take that as the stim onset:
    % First, try the trial's stim movement, for a more accurate estimate of
    % interval:stimONframe = nanmin(obj.TrialXOnFrame(trialIdx) , obj.TrialYOnFrame(trialIdx));
    if ~isnan( stimONframe )
        
        stimONrelative = stimONframe - obj.TrialStartFrame(trialIdx);
        
        % Get the average value in the second half of the interval
        % [ trialstart : stimstart ]
        f0start = floor(0.5*stimONrelative*fps_scale);
        f0stop = floor(stimONrelative*fps_scale);
        
    else
        % If the stimulus didn't move in this trial, a nan is returned, so use
        % the estimated stim on time for the whole experiment:
        stimONtime= min(obj.ExpXOnTime , obj.ExpYOnTime);
        
        % Get the average value in the second half of the interval
        % [ trialstart : stimstart ]
        f0start = floor(0.5*stimONtime*normFPS);
        f0stop = floor(stimONtime*normFPS);
    end
    % Find F0
    F0_try = nanmean( trialData( f0start : f0stop ) );
    
    
catch % Use the interval before the trial:
    
%     disp('Error getting panels movement in findF0.')
    disp('Using pre-trial sequence for F0')
    
    try
        % Get number of frames between trials:
        spontLength = median( [obj.TrialStartFrame(2:end)] - [obj.TrialEndFrame(1:end-1)] );
        
        if spontLength > 2
            f0start = obj.TrialStartFrame(tidx)- floor(0.5*spontLength);
            f0stop = obj.TrialStartFrame(tidx)-1;
        else
            f0start = obj.TrialStartFrame(tidx)- 1;
            f0stop = obj.TrialStartFrame(tidx)-1;
        end
        % Find F0
        F0_try = mean( scanROI(obj, mask, [f0start,f0stop]) );
        
        
    catch % Manually set a length of time, and use that section of the trial response data:
        
        % Get the mean in the first X seconds of trialData:
        X = 0.5; % seconds
        f0start = 1; 
        f0stop = floor(X*normFPS);
        % Find F0 from the processed trialData:
        F0_try = nanmean( trialData(f0start:f0stop) );
        
    end
end

% Check it is appropriate size / format
assert( length(F0_try) == 1 && ~isnan(F0_try), 'F0 returned was not a single numerical value')

% Return F0:
F0 = F0_try;

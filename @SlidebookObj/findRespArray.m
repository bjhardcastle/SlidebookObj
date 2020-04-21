function [responseArray, timeVector, F0Array, ObjIdx] = findRespArray(objarray, ROImaskidx, fields)
%FINDRESPARRAY Extract the aligned, interpolated response time-series for
%all trials which match the specified parameters, across an object array
% [responseArray, timeVector, F0Array, ObjIdx] = findRespArray(objarray, ROImaskidx, fields)
%
% See documentation for findTrials. This is an extension of that function
% which accepts a [1xN] array of objects and returns all the trials, resampled
% to a common time series, timeVector, with correct duration in seconds.
% All trials are accumulated, so no information on which animal or Tiff
% they came from is retained, but the number of SlidebookObjs is counted
% and returned as numExps. If there are multiple tiffs per animal this
% could cause a problem for calculating SEM
%
% See also findTrials.

if nargin < 3 || isempty(fields)
    disp('''fields'' is empty. All trials will be returned.')
    fields = struct;
end
if nargin < 2 || isempty(ROImaskidx)
    ridx = 1;
    NOMASKFLAG = 1;
else
    ridx = ROImaskidx;
    NOMASKFLAG = 0;
end

% Get a common re-samplng rate and timeVector for plotting:
[timeVector, normFPS, trialDuration] = findStandardTrial(objarray);

% Now cycle through objects in objarray, and store matching trials in
% 'trials_returned' (after interpolating):
tcount = 0;
ObjIdx = []; % Store the object index from which each trial was taken
trials_returned = [];
F0_returned = [];
for oidx = 1:length(objarray)

    if  NOMASKFLAG == 1 || ( ~isempty( objarray(oidx).ROI ) && ...
            length( objarray(oidx).ROI ) >= ridx && ...
            isfield( objarray(oidx).ROI(ridx), 'mask' ) && ...
            ~isempty( objarray(oidx).ROI(ridx).mask ) )
        
        assert( ~isempty( objarray(oidx).TrialStartFrame ) , [ 'No trial info stored. Run ''getTrialtimes(objarray(' num2str(oidx) ')) first'] );
        
        trialidx = findTrials( objarray(oidx) , fields );

        for tidx = trialidx'
            
            %Get ROI mask
            if NOMASKFLAG
                mask = [];
            else
                
                mask = objarray(oidx).ROI(ridx).mask;
            end
            
            % Get trial start / end frames
            scan_extent = [objarray(oidx).TrialStartFrame(tidx) objarray(oidx).TrialEndFrame(tidx)];
            
            % Get trial data within ROI            
            this_trial = scanROI(objarray(oidx), mask, scan_extent);

            % Store trial, interpolated to common time vector 
            tcount = tcount + 1;
            trials_returned( tcount , : ) = findFittedTrial(objarray(oidx), this_trial, tidx, timeVector, normFPS, trialDuration);
            
            % Store F0 value for the trial			
            F0_returned( tcount, : ) = findF0( objarray(oidx), mask, trials_returned( tcount , : ),tidx, timeVector, normFPS  );
            
            % Store the index of the object for the trial
            ObjIdx(tcount) = oidx;
            
        end
        
        if ~isempty(trialidx)
            
            if objarray(oidx).BackgroundSubtracted
                % Warn if background has been subtracted
                disp(['Object(' num2str(oidx) '): background subtraction has previously been applied']);
            end
            
        end
        
    end
%     Otherwise, specified ROI mask does not exist for this object
end

responseArray = trials_returned;
F0Array = F0_returned;

if isempty( trials_returned )
    disp(['No ROI exists or no matching trials found for, ROI(' num2str(ridx) ')' ]);
end



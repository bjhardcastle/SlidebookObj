function addToTrialEnd(objarray,numSec)
%ADDTOTRIALEND Shift the end point of all trial markers by a number of seconds
% addToTrialEnd(objarray, numSec)
%
% A function for manually adjusting the end point of all trial markers identified by
% 'getTrialtimes' by a certain number of seconds. The adjustment is made to the DAQ 
% sampling points, then the last frame before the trial end point is found. This is 
% more precise than adjusting based on framerate. 
%
% Adds to trials in the sense that they expand if numSec is positive:
% numSec = 1 will move the trial end points forward 1 second.

% This function accepts the following input:
%
%   numSec  -   single numeric value, specifying number of seconds to shift trial end points.
% 				Positive values move the end point forward in time (adding length to the trial)
%				Negative values move the end point backward in time.
%
assert(nargin == 2,'A number of seconds must be input as numSec')
assert(isnumeric(numSec),'numSec argument must be a numerical value (time, in seconds)')

	for oidx = 1:length(objarray)
		if isempty(objarray(oidx).TrialEndFrame)
		getParameters(objarray(oidx))
		objarray(oidx).Daq = [];
		end
		
		% Shift trial end samples:
		objarray(oidx).TrialEndSample = objarray(oidx).TrialEndSample + numSec*objarray(oidx).AIrate;
		
		% Find new trial end frames:
		for tidx = 1:length(objarray(oidx).TrialEndSample)
			if objarray(oidx).TrialEndSample(tidx) > objarray(oidx).Frametimes(end)
				error('numSec is too large: non-existent samples requested, past last frame')
			elseif tidx <length(objarray(oidx).TrialEndSample) && objarray(oidx).TrialEndSample(tidx)>objarray(oidx).TrialEndSample(tidx+1)
				error('numSec is too large: trial end times are overlapping starts of next trials')
			elseif objarray(oidx).TrialEndSample(tidx) <= objarray(oidx).TrialStartSample(tidx)
				error('numSec is too large: trial end time cannot be less than start time')
			else
			tryFrame = prevFrame(objarray(oidx),objarray(oidx).TrialEndSample(tidx));
				if tryFrame > 0
					objarray(oidx).TrialEndFrame(tidx) =  tryFrame;
				end
			end
		end
		
	end
	disp(['Done. ', num2str(numSec) 's added at end of each trial'])
end

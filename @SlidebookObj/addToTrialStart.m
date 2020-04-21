function addToTrialStart(objarray,numSec)
%ADDTOTRIALSTART Shift the start point of all trial markers by a number of seconds
% addToTrialStart(objarray, numSec)
%
% A function for manually adjusting the start point of all trial markers identified by
% 'getTrialtimes' by a certain number of seconds. The adjustment is made to the DAQ 
% sampling points, then the first frame after the trial start point is found. This is 
% more precise than adjusting based on framerate. 
%
% Adds to trials in the sense that they expand if numSec is positive:
% numSec = 1 will move the trial start points back 1 second.

% This function accepts the following input:
%
%   numSec  -   single numeric value, specifying number of seconds to shift trial start points.
% 				Positive values move the start point backward in time (adding length to the trial)
%				Negative values move the start point forward in time.
%
assert(nargin == 2,'A number of seconds must be input as numSec')
assert(isnumeric(numSec),'numSec argument must be a numerical value (time, in seconds)')

	for oidx = 1:length(objarray)
		if isempty(objarray(oidx).TrialStartFrame)
		getParameters(objarray(oidx))
		objarray(oidx).Daq = [];
		end
		
		% Shift trial start samples:
		objarray(oidx).TrialStartSample = objarray(oidx).TrialStartSample - numSec*objarray(oidx).AIrate;
		
		% Find new trial start frames:
		for tidx = 1:length(objarray(oidx).TrialStartSample)
			if objarray(oidx).TrialStartSample(tidx) < 1
				error('numSec is too large: non-existent samples requested, below sample(1)')
			elseif tidx > 1 && objarray(oidx).TrialStartSample(tidx) <objarray(oidx).TrialEndSample(tidx-1)
				error('numSec is too large: trial start times are overlapping ends of previous trials')
			elseif objarray(oidx).TrialStartSample(tidx) >= objarray(oidx).TrialEndSample(tidx)
				error('numSec is too large: trial start time cannot be greater than end time')
			else
			tryFrame = nextFrame(objarray(oidx),objarray(oidx).TrialStartSample(tidx));
				if tryFrame > 0
					objarray(oidx).TrialStartFrame(tidx) =  tryFrame;
				end
			end
		end
		
	end
	disp(['Done. ', num2str(numSec) 's added at start of each trial'])
end

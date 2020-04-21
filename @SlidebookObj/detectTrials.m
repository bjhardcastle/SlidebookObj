function [trystarts, tryends] = detectTrials(obj,trialsettings)
%DETECTTRIALS Core code for detecting trial starts/ends in DAQ AI Ch2/3
%  [trystarts, tryends] = detectTrials(obj,trialsettings)
%
% DO NOT EDIT THIS FUNCTION. 
% The main purpose of this function is to be called by 'getTrialtimes'
%
% To modify how trials are detected:
%   - override default TrialSettings in the object classdef file
%   - edit 'getTrialtimes'
%   - modify the returned arrays 'trystarts' / 'tryends' in
%     getTrialtimes
% 
% By preserving this core code, the actual method of detecting trials can
% be consistent across all SlidebookObj subclasses, and improvements will
% similarly benefit all.
% 
% This function accepts the following input:
%
%   trystarts       - [Nx1] array of trial start times, as Daq sample index
%                      Not assigned to object. Intended to be checked.         
%
%   tryends         - [Nx1] array of trial end times, as Daq sample index
%                      Not assigned to object. Intended to be checked.
%
% This function returns the following output:
%  
%   trialsettings   - structure with fields for customizing trial start/
%                     end detections (see getTrialtimes)
%
%
% See also getTrialtimes.

assert(nargin == 2 && isstruct(trialsettings), 'Provide ''trialsettings'' as a structure of settings')

% Abbreviation for readability:
wstim = obj.Daq;
ts = trialsettings;

% Find trial start/end times (in samples)
switch ts.joined
    
    case 0
        % This is a simple, fast method:
        % Get the differential of the signal (to locate sudden steps)
        % Use inequalities to locate the peaks within an appropriate range:
        %    lower bound may have to be queried
        %    upper bound is set by 10V range of analog input
        
        trystarts = find(diff(wstim(:,ts.chan)) >= ts.minpeak  &  diff(round(wstim(:,ts.chan))) < 15 );
        tryends =  find(-diff(wstim(:,ts.chan)) >= ts.minpeak  & -diff(round(wstim(:,ts.chan))) < 15 );
           
    case 1 
        % If 'joined':
        % voltage does not reset to 0 after each trial, so trials are
        % not repreented by a rising and then falling edge, but
        % sometimes a rising followed by a rising edge, or vice
        % versa
        
        alltrials = find(abs(diff(wstim(:,ts.chan))) >= ts.minpeak  &  abs(diff(round(wstim(:,ts.chan)))) < 15 );
        % Discard any detected peaks which are too close to a previous trial to
        % be real:
        %   500 samples = 5 ms
        alltrials(find(diff(alltrials)<500)+1) = [];
        
        % Extract every other detected point
        trystarts = sort( [alltrials(1:2:end-1); alltrials(2:2:end-1)+1] , 'ascend');
        tryends = sort( [alltrials(2:2:end); alltrials(3:2:end-1)] , 'ascend');
        
end
               
% Discard any detected peaks which are too close to a previous trial to
% be real:
dblstarts = find(diff(trystarts)<500);   % 500 samples = 5 ms
if ~isempty(dblstarts)
    for didx = dblstarts
        ds(1) = diff(wstim(trystarts(didx):trystarts(didx)+1,ts.chan));
        ds(2) = diff(wstim(trystarts(didx+1):trystarts(didx+1)+1,ts.chan));
        if ds(1) > ds(2)
            trystarts(didx+1) = [];
        else
            trystarts(didx) = [];
        end
    end
end
% Same for trial end-points:
dblends= find(diff(tryends)<500);
if ~isempty(dblends)
    for didx = dblends
        ds(1) = diff(wstim(tryends(didx):tryends(didx)+1,ts.chan));
        ds(2) = diff(wstim(tryends(didx+1):tryends(didx+1)+1,ts.chan));
        if ds(1) > ds(2)
            tryends(didx+1) = [];
        else
            tryends(didx) = [];
        end
    end
end
% And the same across trial starts&ends combined
startendcombined = sort([trystarts; tryends],'ascend');
dblcombined = find(diff(startendcombined)<4) + 1;
if ~isempty(dblcombined) && ~ts.joined
	for didx = 1:length(dblcombined)
	
		switch ismember(startendcombined(dblcombined(didx)),trystarts)
		
			case 1 
				if startendcombined(dblcombined(didx)) == trystarts(end) && startendcombined(dblcombined(didx)-1) == tryends(end)
					% Erroneous 'start' at end of signal, where there is no actual trial
					findIdx = find(trystarts == startendcombined(dblcombined(didx)));
					trystarts(findIdx) = [];
					
				elseif ismember(startendcombined(dblcombined(didx)-1),tryends) && ismember(startendcombined(dblcombined(didx)+1),trystarts)
					% Then this is an erroneous 'start' sample: delete
					findIdx = find(trystarts == startendcombined(dblcombined(didx)));
					trystarts(findIdx) = [];
				
				end
				
			case 0 	
				if ismember(startendcombined(dblcombined(didx)-1),tryends) && ismember(startendcombined(dblcombined(didx)+1),trystarts)
					% Then this is an erroneous 'end' sample: delete
					findIdx = find(tryends == startendcombined(dblcombined(didx)));
					tryends(findIdx) = [];
				end
		end 

	end
end

% If wstim(:,chan) was not reset to 0 at the start of the experiment,
% the first trialstart may be missed.
if isfield(ts,'firstTrialError') && ts.firstTrialError
    if round(mean(wstim(1:100,ts.chan)*10)) ~= 0
       % Either one or two additional trial ends will be detected,
       % and the solution is different for each case:
       
       if (length(tryends) - length(trystarts)) == 2 && (tryends(1) < trystarts(1) && tryends(2) < trystarts(1) )
           % Signal looks like this:
           % _____________________
           %                     |
           %                     |____      ____      ____
           %                          |    |    |    |    |
           %                          |____|    |____|    |___           
           
           % Make the first detected trial end the first trial start
           trystarts(2:length(trystarts)+1) = trystarts;
           trystarts(1) = tryends(1);
           tryends(1) = [];
            
       elseif (length(tryends) - length(trystarts)) == 1 && (tryends(1) < trystarts(1) && tryends(2) > trystarts(1) )
           % Signal looks like this: start of first trial is missed
           % _____________________      ____      ____
           %                      |    |    |    |    |
           %                      |____|    |____|    |___           
           
           % Guess the start of the first trial, based on length of
           % other trials
            trystarts(2:length(trystarts)+1) = trystarts;
            trystarts(1) = tryends(1) - median(tryends-trystarts);
        end        
    end
end

% Apply setlimits
trystarts(trystarts<ts.setlimits(1)) = [];
tryends(tryends<ts.setlimits(1)) = [];
trystarts(trystarts>ts.setlimits(2)) = [];
tryends(tryends>ts.setlimits(2)) = [];

if ts.plotflag
    checkTrials(obj, ts, trystarts, tryends );
end

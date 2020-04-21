function chanGains = detectTrialGains(obj, chanIdx, panels_refresh_rate)
%DETECTTRIALGAINS Determine the Panels gain used for each trial, if there was Panels pattern motion.
% detectTrialGains(obj, chanIdx, panels_refresh_rate)
%
% Examines DAQ(:,chanIdx) and extracts the Panels gain used for each trial,
% if there was stimulus motion. Otherwise, gain is recorded as 0. This is a
% somewhat crude method, but seems to work: The time interval between
% voltage steps in DAQ(:,chanIdx) gives the gain (x10), so we simply search
% for peaks in diff(DAQ(:,chanIdx)) and look at their frequency. We then
% estimate whether the slope was increasing or decreasing to guess the sign
% of the gain.

% Some abbreviations to make code more readable:
trialstarts = obj.TrialStartSample;
trialends = obj.TrialEndSample;
airate = obj.AIrate;
wstim = obj.Daq;

chanGains = zeros(1,length(trialstarts));

for tidx = 1:length(trialstarts)
    c = wstim(trialstarts(tidx):trialends(tidx), chanIdx);
    
    % Peaks in signals:
    % 10V / 96 pixel steps should be the minimum step size in the
    % signal that corresponds to stimulus position/velocity change
    [~,locs] = findpeaks(abs(diff(c)),'MinPeakProminence',0.9*10/96);
%     locs = find(abs(diff(detrend(c)))>0.6*10/96);        
%     
%     % Remove spikes too close together:
%     x=1;
%     medC = median(diff(locs));n=0;
%     while ~isempty(x)
%         x = find( abs( diff(locs) - medC ) > 0.4* medC );
%         locs(x(1)) =[];
%         n=n+1;
%     end
%     
    % Examine the spacing between steps in signal:
    
    % The stimulus probably ran for at least 1s
    % And had a gain of 0.1 / 1x
    % Which equals at least 5 frames/steps in the signal
    if isempty(locs) || length(locs) < 6
        % If too few were found, store 0 gain
        gvalue = 0;
    else

        % Otherwise, round the median time between steps/frames to the
        % first decimal place
        gvalue = round(airate/median(diff(locs))/10,1);
        % If it's within 0.1 of an integer gain value, that was probably the
        % setting..
        if  abs( round(airate/median(diff(locs))/10) - gvalue ) < 0.11
            gvalue = round(airate/median(diff(locs))/10);
        end
        
        % Now we need to work out the sign
        % Convert c (0-10 Volts) to C (0-2Pi radians)
        C = c*2*pi/10;
        % Then unwrap phase:
        CC= unwrap(C);
        % Convert back to Volts
        Cc = CC*10/(2*pi);
        % We now have a trace which starts around 0 and either increases or
        % decreases
        % We could simply take the sign of the mean of this trace, but it's
        % preferable to examine the gradient itself, after a little extra
        % work.
        % First, downsample the signal to 10 samples per second
        % This gives us a smoothed version of the trace
        cc = downsample(Cc,airate/10);
        % Get the gradient of this downsampled trace and convert to the actual
        % gradient at the original sampling rate
        gsign = sign( mean(diff(cc)) );
        
        gvalue = gvalue*gsign;
        
    end
    % Store gain value
    chanGains(tidx) = gvalue;
    
end

end
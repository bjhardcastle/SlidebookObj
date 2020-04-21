function [ExpStimOnTime, ExpStimOffTime, TrialStimOnFrame, TrialStimOffFrame] = detectPanelsMovement(obj,gainStr)
%DETECTPANELSMOVEMENT Determine the frame numbers at which the Panels pattern started and stopped moving
% detectPanelsMovement(obj,gainStr) 
%
% Daq channel index is derived from input gainStr: 'x' or 'y' Examine
% DAQ(:,chanIdx) (usually ch4 or ch5) for each trial if the gain was not
% zero. These values aren't stored in the object: we just want the typical
% start point, relative to the trial start frames, and the duration of
% movement for indicating where the stimulus was running on plots of mean
% trial responses.

% Get the trial gains already found for the channel we're looking at:
% Default behaviour is x on ch5, y on ch4
% These can be reversed by adding a property to the object and setting it
% to 1:
if strcmpi(gainStr,'x')
    
    chanTrialGains = obj.TrialXGain;
    
    if isprop(obj,'SwitchXYDaqChans') && ~isempty(obj.SwitchXYDaqChans) && obj.SwitchXYDaqChans == 1
        chanIdx = 4;
    else
        % Default:
        chanIdx = 5;
    end
    
elseif strcmpi(gainStr,'y')
    
    chanTrialGains = obj.TrialYGain;
    
    if isprop(obj,'SwitchXYDaqChans') && ~isempty(obj.SwitchXYDaqChans) && obj.SwitchXYDaqChans == 1
        chanIdx = 5;
    else
        %Default:
        chanIdx = 4;
    end
    
else
    error('Please enter channel input as a string: ''x'' or ''y''')
end


% Some abbreviations to make code more readable:
trialstarts = obj.TrialStartFrame;
trialends = obj.TrialEndFrame;
airate = obj.AIrate;
wstim = obj.Daq;

% Extract voltage level at Frame times
f = wstim(obj.Frametimes,chanIdx);

% Round to closest reasonable voltage resolution: 10V / 96 steps
h = round(f*96/10)*10/96;

% Find places where frame rate is momentarily greater than one - not sustained -
% by checking if surrounding rate is zero
k = abs(diff(h));
l = find(k>0);
for p=1:length(l)
    n=l(p);
    % Eliminate points where that is the case (only > 0 for 1-2 frames)
    if n<=3 
         if ~( sum( k(1:n+3) > 0 ) > 2 )
             k(1:n+2) = 0;
         end
    elseif  n>=length(k)-3
         if ~( sum( k(n-3:end) > 0 ) > 2 )
             k(n-2:end) = 0;
         end
    else
        if ~( sum( k(n-3:n+3) > 0 ) > 2 )
            k(n-2:n+2) = 0;
        end
    end
end

% Rescan the diff signal, which now only contains continous movements:
ll = find(k>0);

if ~isempty(ll)
% Then find the start and stop points of the non-zero signal which remains.
% Do this within each trial(start:end) points:
z=0;
ts = []; % Stim start points
te = []; % Stim end points
for t = 1:length(trialstarts)
    
    if chanTrialGains(t) ~=0
        z=z+1;
        % Find all continuous movement after the starting frame for the trial
        o=ll(ll>=trialstarts(t));
        % The diff signal tells us about voltage change between
        % one frame and the next. The first index detected here represents the
        % first frame with a diff signal that shows movement of the stimulus.
        % That necessarily means that the stimulus starts moving in the
        % interval between this frame and the next. We want to find frames
        % *within* the stimulus movement window, which the first frame is not,
        % so we take the next one (index 2).
        ts(z) = o(2);
        % Find all continuous movement up to the end of the trial:
        u=ll(ll<=trialends(t));
        % For the end point of the stimulus movement, the last index detected
        % in the diff signal correctly indicates the last frame within the
        % stimulus window:
        te(z) = u(end);
        alltrialsS(t) = ts(z);
        alltrialsE(t) = te(z);
    else
        alltrialsS(t) = nan;
        alltrialsE(t) = nan;
    end
    
end

% Check the range of values found. For a typical stimulus (1sec +) the
% range of stimulus onsets/offsets should be found with an accuracy greater
% than +/- 0.5sec. The duration should therefore not be more than +/- 1sec.
% If that's the case, flag up an error.
stimFrameDurations = (te - ts);
medStimOn = median(ts - trialstarts(abs(chanTrialGains)>0));
medStimOff = median(te - trialstarts(abs(chanTrialGains)>0));
fps = airate/obj.IFI;
try
assert( ~any( abs( stimFrameDurations - median( stimFrameDurations ) ) > fps) , ...
    'Range of stimulus durations found is too large to determine a single common onset/offset times.' );

% After checking, return stim ON/OFF frame numbers for pushing to object:
TrialStimOnFrame = alltrialsS;
TrialStimOffFrame = alltrialsE;

% Convert to average frame numbers to seconds:
% Since we found the first frames *after* the stimulus started in each trial,
% on average the stimulus starts halfway between this frame and the
% preceding one. Likewise, the stimulus ended on average between the last
% frame found and the one following it.
% We use these mid-way frames to convert median frametimes into an estimate
% of "how many seconds after each trial starts does the stimulus start"
ExpStimOnTime = round( ( medStimOn - 0.5 )*obj.IFI/obj.AIrate , 1);
ExpStimOffTime = round( ( medStimOff + 0.5 )*obj.IFI/obj.AIrate, 1);

catch
TrialStimOnFrame = [];
    TrialStimOffFrame = [];
    ExpStimOnTime = [];
    ExpStimOffTime = [];
	disp('Range of stimulus durations found is too large to determine a single common onset/offset times.')
end

else % no movement detected
    TrialStimOnFrame = [];
    TrialStimOffFrame = [];
    ExpStimOnTime = [];
    ExpStimOffTime = [];
end


% For debugging purposes: plot the stim times found:
%{

figure, plot(f)
hold on, plot(ts,f(ts),'go')
plot(te,f(te),'ro')

%}

% Or:

%{

figure, plot(wstim(:,chanIdx))
hold on,plot(wstim(:,1))
plot(obj.Frametimes(ts),wstim(obj.Frametimes(ts),1),'go')
plot(obj.Frametimes(te),wstim(obj.Frametimes(te),1),'ro')

%}

end
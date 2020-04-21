function getFrametimes(obj)
%GETFRAMETIMES Detect frame markers in DAQ data and store in object
% getFrametimes(obj)
%
% Reads the data stored in obj.Daq(:,1) and looks for peaks that correspond
% to frame markers output by 3i 2P system. The sample index of each frame 
% is stored in the object. Use the functions prevFrame and nextFrame to
% find the closest frame marker to a particular sample index.
%
% This functions writes to object:
%   obj.Frametimes  -   [1 x numFrames] array of sample indices. Each entry
%                       corresponds to a Tiff frame detected in obj.Daq(:,1)
%
%   obj.IFI         -   double, equal to the median number of samples
%                       between each frame detected. Generally used for
%                       finding a Tiff's framerate.
%
% See also getDaqData, nextFrame, prevFrame.
if isempty(obj.DaqFile)
    disp('No DAQ file exists - try running ''getDaqFile(obj)''')
    return
end

if isempty(obj.Daq)
    getDaqData(obj);
end

% Some abbreviations for readability:
wstim = obj.Daq;
airate = obj.AIrate;

% For each tiff frame, DAQ AI0 records a pulse:
wframes=find(diff(round(wstim(:,1)/5))==1)+1;
% wframes(1) first grabbed frame
% wframes(end) last grabbed frame

% Get rid of any duplicate frames resulting from double blips in signal
wframes(find(diff(wframes)<0.1*mean(diff(wframes))) + 1) = [];

% Get inter-frame interval (in samples)
ifi = (median(diff(wframes)));

% Push to object
obj.IFI = ifi;
obj.Frametimes = wframes';
    
    

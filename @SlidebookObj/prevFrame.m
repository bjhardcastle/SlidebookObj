function frameIdx = prevFrame(obj,sampIdx) 
%PREVFRAME Find the last recorded frame before a particular sample in DAQ data
% frameIdx = prevFrame(obj,sampIdx)
%
% Input a DAQ sample index and this function outputs the sample index for
% the preceding frame recorded. Uses a Slidebook object's average inter-
% frame interval as a guide for how far behind to look for a frame.
% 
% This function accepts the following inputs:
% 
%   sampIdx   - sample index, referring to saved DAQ analog input data. Can
%               be a single value or a 1D array. 
%
% This function returns the following outputs:
% 
%   frameIdx  - frame index, corresponding to the sample index of the
%               preceding frame found on DAQ analog input channel 1, or 
%               obj.Daq(:,1), for each value in sampIdx.
%
% See also nextFrame, getFrametimes, getTrialtimes. 

for idx = 1:length(sampIdx)
tempframe = find(obj.Frametimes<=sampIdx(idx) & obj.Frametimes>=sampIdx(idx)-obj.IFI);
if isempty(tempframe) && any(obj.Frametimes<=sampIdx(idx))
    % If no frames were found within the correct window, we just have to
    % take the last frame that occured, regardless 
    tempframe = find(obj.Frametimes<=sampIdx(idx));
end

frameIdx(1,idx) = tempframe(end);
end
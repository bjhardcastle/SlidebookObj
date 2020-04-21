function [STDtrace] = scanROIstd(obj, mask, scan_extent)
%SCANROISTD Find standard deviation of deviation within mask across frames
% STDtrace = scanROIstd(obj, mask, scan_extent)
%
% Finds the STD value of the pixels within the passed ROI mask for each
% frame in the object's Frames. A subset of frames can also be specified.
% If Frames aren't already stored they will be requested on-demand.
% STD is calculated only on the intensity of pixels within the mask -
% pixels with zero value in the mask are discarded, not counted as zero. 
%
% Currently unused by any function. 
%
% Do not confuse this with the standard deviation of the mean intensity 
% across trials, for which you do not need this function.
% 
% This function accepts the following arguments:
%
%   mask        - (optional) 2D binary array with the same dimensions as 
%                 the image frames in obj.Frames or the object's RegTif 
%                 file. Values should be 1 in the ROI and 0 elsewhere. 
%                 Usually input as 'obj.ROI(index).mask'
%                 Default (with no input) is to use entire image.
%
%  scan_extent  - (optional) [1x2] vector that specifies [start stop] frame
%                 numbers to scan and find the STD of intensity within mask.
%                 Default is all frames.
%
% This function returns the following outputs:
%
%  STDtrace     - [1xN] vector where N is equal to the number of scanned
%                 frames. Each value is the STD of the intensity of pixels 
%                 within the ROI mask specified.
%
% See also scanROI.

% Check input arguments
% If scan_extent incorrectly specified, use default
if nargin<3 || isempty(scan_extent) || length(scan_extent) < 2
    scan_extent = [1 0];
end
if nargin==1 || isempty(mask)
    disp('ROI mask  was not specified: finding STD of entire image')
end

CLEARFLAG = 0;
% Check if Frames have already been scanned into object..

if isempty(obj.Frames) && isequal(scan_extent,[1 0])
    % if not, and all Frames are requested, we will store them in the obj
    getFrames(obj);
    % and adjust scan_extent to scan to the last frame
    scan_extent = [1 size(obj.Frames,3)];
    
elseif isempty(obj.Frames)
    % If scan_extent was specified, read only the frames requested
    obj.Frames = getFrames(obj,scan_extent);
    % We store them temporarily in obj.Frames
    % Set a marker for deleting them at the end of the function
    CLEARFLAG = 1;
    % And shift scan_extent to reflect the frames being at the start of
    % obj.Frames
    scan_extent = [1 1+scan_extent(end)-scan_extent(1)];
    
elseif ~isempty(obj.Frames) && isequal(scan_extent,[1 0])
    scan_extent = [1 size(obj.Frames,3)];
end


% If no ROI specified then use entire image frame
if isempty(mask)
    mask = true(size(obj.Frames,1),size(obj.Frames,2));
end

% If an ROI was specified it must be the same size as the tiff image frames
assert(isequal(size(mask),size(obj.Frames(:,:,1))) , ...
    'size(mask) does not match dimensions of tiff frames')

% Convert binary mask to logical array:
if ~islogical(mask)
    mask = logical(mask);
end

% Setup loop through Frames
m = 0;                   % Output array index
n = scan_extent(1) - 1;  % Frame counter
Fstd = nan(1,(1+scan_extent(end)-scan_extent(1)) );
while (m == 0) || ( n ~= scan_extent(end) )
    n = n + 1;
    m = m + 1;
    % Grab the current frame
    currentframe = obj.Frames(:,:,n);
    % Extract the STD of pixel intensity within the ROI
    Fstd(m) = std(currentframe(mask));
    % Indexing currentframe with the 'true' logical values in mask finds
    % their corresponding intensity. Pixels with 'false' values are
    % discarded, not counted as zero intensity, so area of ROI mask should
    % not affect the calculated STD.
end

% Check every frame returned a value:
assert( ~any(isnan(Fstd)), ...
    'Some frames scanned did not contain image data.')

% Return array of STD values:
STDtrace = Fstd;

if CLEARFLAG
    obj.Frames = [];
end
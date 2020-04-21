function [Ftrace] = scanROI(obj, mask, scan_extent)
%SCANROI Find mean intensity value within mask across frames
% Ftrace = scanROI(obj, mask, scan_extent)
%
% Finds the mean value of the pixels within the passed ROI mask for each
% frame in the object's Frames. A subset of frames can also be specified.
% If Frames aren't already stored they will be requested on-demand.
% Mean intensity is calculated as the sum of the intensity within the mask
% divided by the number of pixels in the mask.
%
% This is the basic function for making time-series plots, used by
% plotTrials, plotPWmax, findF0, getRespArray etc. Not usually run alone.
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
%                 numbers to scan and find the mean intensity within mask.
%                 Default is all frames.
%
% This function returns the following outputs:
%
%  Ftrace       - [1xN] vector where N is equal to the number of scanned
%                 frames. Each value is the mean pixel intensity within the
%                 ROI mask specified.
%
% See also scanROIstd, findF0, findRespArray.

% Check input arguments
% If scan_extent incorrectly specified, use default
if nargin<3 || isempty(scan_extent) || length(scan_extent) < 2
    scan_extent = [1 0];
end
if nargin==1 || isempty(mask)
    disp('ROI mask  was not specified: finding mean of entire image')
end

% If the ROI with the corresponding mask has already been scanned and
% saved, and the option to use the fixed ROI response is True, then don't
% scan the tiff object or saved obj.Frames, just use the Fixed response
Ftrace = [];
if isprop(obj,'UseFixedResp') && ~isempty(obj.UseFixedResp) && obj.UseFixedResp
    n=1;
    while n<=length(obj.ROI)
        if isequal( obj.ROI(n).mask, mask) && isfield(obj.ROI(n),'response') && ~isempty( obj.ROI(n).response )
            
            if scan_extent(2) == 0
                scan_extent(2) = length( obj.ROI(n).response );
            end
            Ftrace = obj.ROI(n).response(scan_extent(1):scan_extent(2));
            break
        else
            n= n+1;
        end
    end
end

clearObjFramesFlag = 0;

% In case no saved resp was found, continue as normal and scan frames (original method)
if isempty(Ftrace)

    % Check if Frames have already been scanned into object..
    
    if isempty(obj.Frames) && isequal(scan_extent,[1 0])
        % if not, and all Frames are requested, we will store them in the obj
        getFrames(obj);
        % and adjust scan_extent to scan to the last frame
        scan_extent = [1 size(obj.Frames,3)];
        frames = obj.Frames;
		
		% Also flag frames for subsequent deletion before exiting
		clearObjFramesFlag = 1;
		
    elseif isempty(obj.Frames)
        % If scan_extent was specified, read only the frames requested
        frames = getFrames(obj,scan_extent);
        % We store them temporarily in obj.Frames
        % Set a marker for deleting them at the end of the function
        % And shift scan_extent to reflect the frames being at the start of
        % obj.Frames
        scan_extent = [1 1+scan_extent(end)-scan_extent(1)];
        
    elseif ~isempty(obj.Frames)
        frames = obj.Frames;
    end
    
    
    % If no ROI specified then use entire image frame
    if nargin < 2 || isempty(mask)
        mask = true(size(frames,1),size(frames,2));
    end
    
    % If an ROI was specified it must be the same size as the tiff image frames
    assert(isequal(size(mask),size(frames(:,:,1))) , ...
        'size(mask) does not match dimensions of tiff frames')
    
    % Convert binary mask to logical array:
    if ~islogical(mask)
        mask = logical(mask);
    end
    
    % % % Setup loop through Frames
    % % m = 0;                   % Output array index
    % % n = scan_extent(1) - 1;  % Frame counter
    % % Fmean = nan(1,(1+scan_extent(end)-scan_extent(1)) );
    % % while (m == 0) || ( ( n ~= scan_extent(end) ) && (n ~= size(frames,3)) )
    % %     n = n + 1;
    % %     m = m + 1;
    % %     % Grab the current frame
    % %     currentframe = frames(:,:,n);
    % %
    % %     % Extract the mean pixel intensity within the ROI
    % %     Fmean(m) = mean(currentframe(mask));
    % %     % Indexing currentframe with the 'true' logical values in mask finds
    % %     % their corresponding intensity. Pixels with 'false' values are
    % %     % discarded, not counted as zero intensity, so area of ROI mask should
    % %     % not affect the calculated mean.
    % % end
    
    %%%%%%%%% Vectorized version of above code:
    
    if scan_extent(2) == 0
        scan_extent(2) = size(obj.Frames,3);
        SAVE_RESP_FLAG = 1;
    elseif scan_extent(2) == size(obj.Frames,3)
        SAVE_RESP_FLAG = 1;
    else
        SAVE_RESP_FLAG = 0;
    end
    
    Fmean = sum( reshape(frames(:,:,scan_extent(1):scan_extent(2)) ...
        .*mask, length(mask(:)) , (scan_extent(2)+1-scan_extent(1)) ) , 1  ) ...
        ./sum(mask(:));
    
    %%%%%%%%%%%%%%%%%%%%%%%
    
    
    % Check every frame returned a value:
    assert( ~any(isnan(Fmean)), ...
        'Some frames scanned did not contain image data.')
    
    % Return array of mean values:
    Ftrace = Fmean;
    
    % Attempt to save Ftrace to ROI.response
    %  - if whole trace was obtained
    %  - if  we can find a match for the mask among the current obj.ROIs
    if SAVE_RESP_FLAG
        for n = 1:length(obj.ROI)
			try
				if isequal( obj.ROI(n).mask , mask )
					obj.ROI(n).response = Ftrace;   
				end
			end
        end
    end
    
    clear frames;
	if clearObjFramesFlag
		obj.Frames = [];
	end
end

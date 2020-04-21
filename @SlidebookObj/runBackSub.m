function runBackSub(obj)
%RUNBACKSUB Subtract off background intensity changes from stored frames
% runBackSub(obj)
%
% This function modifies all frames stored in the object. Any ROI timeseries
% found through 'scanROI' or 'findRespArray' after execution will show the
% response with the background subtracted.
%
% Since the stored obj.Frames are a transient property of the object (ie.
% they are not stored when the object is saved), background subtraction is
% temporary, and must be performed each time the object is loaded and .tiff
% frames are re-read.
%
% The value of the transient property obj.BackgroundSubtracted shows if
% the background has been subtracted (1) or not (0, default).
%
% To undo background subtraction, run:
%  getFrames(obj)
%
% The current background subtraction is simple, but does not need user input:
%   - find the mean intensity image (one frame) for the experiment's tiff stack
%   - find the median intensity value within this mean image
%   - take all pixels below the median intensity ( 50% total image pixels remain )
%   - randomly discard 50% of those pixels ( 25% total image pixels remain )
%   - use this mask as an ROI and scan through every tiff frame, extracting
%     mean intensity within the ROI
%   - this timeseries shows the changes in 'background' intensity
%   - for each timepoint, subtract the background intensity from the stored
%     image frames, obj.Frames
%
% This process is iterated multiple times, equal to obj.BackSubReps (default is 1)
%
% UPDATE: 
% An option has been added to run a linear de-trending of the image data
% (see help for 'detrend') which will fix a gradual increase/decrease in
% intensity over a Tiff file, which can cause problems when comparing
% trials at the start with those at the end. If not such trend exists, the
% mean value will be subtracted, which is somewhat like what this function
% does, but more severe. Negative intensity values are likely to result.
% For simply visualizing activity during trials it can be useful, though.
% Turn ON by setting the property 
%   obj.Detrend = 1;        Default is 0. 
%
% See also getFrames, play.

if isprop(obj,'BackSubReps') && ~isempty(obj.BackSubReps)
    BackSubReps = obj.BackSubReps;
     if BackSubReps < 0
        disp('obj.BackSubReps must greater than 0. Using default 1.')
        BackSubReps = 1;
    end
    % Will iterate the background subtraction algorithm this many times.
    % Greater than 10 times will take 
else
    BackSubReps = 1;
end

if isprop(obj,'Detrend') && ~isempty(obj.Detrend)
    Detrend = obj.Detrend;
else
    Detrend = 0;
end


% So that we can get tiff frames without user input, store the
% object's Unattended status and temporarily set it to 1.
% We'll reverse this later if the object wasn't already in Unattended mode
undoflag = 0;
if ~obj.Unattended
    obj.Unattended = 1;
    undoflag=1;
end

if isempty( obj.Frames )
    % Get frames if they haven't been read already:
    getFrames(obj);
end

% If frames exist and background has already been subtracted:
if obj.BackgroundSubtracted
    % If not:
    str1 = 'Run getFrames';
    str2 = 'Cancel';
    
    if undoflag % = ~obj.Unattended
        
        % Prompt user for input
        qstring = 'Background subtraction has already been applied. To run it again, original Tiff frames must be fetched, which may take time. ';
        title = 'Apply subtraction again?';
        default = str1;
        button = questdlg(qstring,title,str1,str2,default);
        
    else % Run registration when in Unattended mode
        button = str1;
    end
    
    % Carry out the choice:
    switch button
        case str1
            disp('Restoring original frames..')
            getFrames(obj);
            disp('Done.')
        case str2
            disp('Cancelled. Existing frames with background subtraction are kept.')
            return
    end
end
% [ the only time we might want to subtract the background a second time is
% when changes to this function were made, or when the function is
% overloaded from a subclass, after the superclass version had already been
% run. Either way, original frames would be needed for re-scanning, so
% advise to run getFrames(obj)  ]


h = waitbar(0,'Subtracting background','Name','runBackSub',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');
h.Position(4) = h.Position(4) + 30; % To make room for mult-line text 
setappdata(h,'canceling',0);

% Detrend if requested
if Detrend
    obj.Frames = detrendFrames(obj);
end

% Mean pixel values:
meanFrame = mean(obj.Frames,3);
% Make a mask from pixels with average intensity lower than the median
medianIntensity = median(meanFrame(:));
fullMask = meanFrame<medianIntensity;
% Find the coordinates of mask pixels (50% of total image frame)
[ Py , Px ] = find(fullMask);


% While we have object's frames, we repeat the process multiple times to
% get a better result:
n=0;
maxInt = 2^16;

% while maxInt > BackSubReps && n < 99 % timeout
while n < BackSubReps %&& n < 99 % timeout

    % Check for Cancel button press
    if getappdata(h,'canceling')
        waitbar(1,h,sprintf(['Cancelled\n\nPartial background subtraction applied']))
        pause(3)
        break
    end
    % Report current estimate in the waitbar's message field
    barText = ['Subtracting background\n\nHint: try decreasing obj.BackSubReps if subtraction is slow'];
    waitbar(n/BackSubReps,h,sprintf(barText))
    
    
    % Mix up their indices
    randIdx = randperm(length(Px));
    % Discard half of the indices (kept indices will be set to zero in mask)
    randIdx( 1 : ceil(0.5*length(randIdx)) ) = [];

    % Apply to mask, to keep random half of pixels (25% total image frame)
    randMask = fullMask;
    Ry = Py(randIdx);
    Rx = Px(randIdx);
    % [ Can't figure out how to vectorize the following:
    % randMask(Ry,Rx) = 0;   %does not work :S ]
    for g = 1:length(randIdx)
        randMask(Ry(g),Rx(g)) = 0;
    end
    
    % Scan frames with the background mask
    bkg = scanROI(obj,randMask,[]) ;

    % Get rid of sudden massive spikes in F
    diff_bkg = diff(bkg);
    % Detect spikes greater than 3*STD
    spikes = find(diff_bkg>3*std(diff_bkg));
    % If the following diff value is similar magnitude flag for deletion:
    % (sudden increase and sudden decrease sometimes results from scanning
    % while chrimson LED or similar is on)
    delIdx = diff_bkg( spikes+1) < 2.5*std(diff_bkg);
    
    % Make the data at spikes equal the following frame:
    bkg(spikes(delIdx)+1) = bkg(spikes(delIdx)+2);
    bkg = smooth(bkg);
    
    % Get rid of spikes in Tiff frames in the same way:
    obj.Frames(:,:,spikes(delIdx)+1) = obj.Frames(:,:,spikes(delIdx)+2);
    
    % Subtract off background timeseries from each corresponding frame
    newmov = zeros(size(obj.Frames));
    for idx = 1:size(obj.Frames,3)
        newmov(:,:,idx) = obj.Frames(:,:,idx) - bkg(idx) - 0*std(bkg) ;
        % Set negative intensity values (which are meaningless) to zero
        newmov(:,:,idx) =  newmov(:,:,idx) .*  (newmov(:,:,idx)>=0);
    end
    
    % Replace stored frames
    obj.Frames = newmov;
    
    % loop counters
    n = n+ 1;
    maxInt = max(bkg);  % Background from previous iteration, so the
    % resulting subtraction will be at least as good
    % as this
    if BackSubReps == 1
        break
    end
end
delete(h)       % DELETE the waitbar; don't try to CLOSE it.

% Set flag
obj.BackgroundSubtracted = 1;

% Reverse any changes to Unattended mode
if undoflag
    obj.Unattended = 0;
end
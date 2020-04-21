function varargout = getFrames(obj,scan_extent)
%GETFRAMES Read the frames from an object's registered Tiff file
% frames = getFrames(obj,scan_extent)
%
% Reads the frames in a SlidebookObj's registered Tiff file. If it doesn't
% exist, a prompt gives the option to run registration. By default, with no
% input argument, all frames are read and stored in obj.Frames. A subset of
% frames can be requested using the argument 'scan_extent'.If obj.Frames
% have already been found, a prompt displays before overwriting; reading
% large Tiff files can be slow and we want to avoid if unnecessary.
%
% To skip all prompts and register and overwrite by default, put the object
% in Unattended mode:
%   obj.Unattended = 1
%
% This function writes to object:
%
%   obj.Frames  - (if scan_extent argument is not provided)
%                 This property is transient and is not stored with object
%                 when saved to disk. If an object is loaded, this function
%                 must be re-run.
%
% This function accepts the following inputs:
%
%   scan_extent - (optional) [1x2] numerical array, for specifying a subset
%                 of frames to be fetched from the Tiff file:
%                 [startFrameNumber , endFrameNumber]
%                 No frames are stored in the object: an output argument
%                 must be specified.
%
% This function returns the following outputs:
%
%   frames      - (optional) 3-dimensional array of image data returned
%                 when 'scan_extent' is specified.
%                 size(Frames,3) = scan_extent(2) - scan_extent(1) + 1
%
%
% See also runBackSub, play.

if nargin < 2 || isempty(scan_extent)
    scan_extent = [1 0]; % Default behavior, read all frames
end

% Check whether Frames already exist in the object:
% (in Unattended mode, frames are overwritten without prompting)
if ~( isempty(obj.Frames) ) && ~( obj.Unattended )
    
    % Prompt user for input
    qstring = 'Stored Frames already exist';
    wintitle = 'Overwrite Frames?';
    str1 = 'Overwrite';
    str2 = 'Keep existing Frames';
    default = str1;
    button = questdlg(qstring,wintitle,str1,str2,default);
    
    if strcmp(button, str2)
        disp('Cancelled. No frames returned.')
        return
    end
end

% Now check if we've got a registered Tiff available
FileName = [obj.Folder obj.TifRegFile];

if exist(FileName,'file') ~= 2
    % If not:
        str1 = 'Run registration';
        str2 = 'Use unregistered .tiff';
        str3 = 'Quit';

    if ~obj.Unattended
        
        % Prompt user for input 
        qstring = 'No registered .tiff file found';
        wintitle = 'Register .tiff?';
        default = str1;
        button = questdlg(qstring,wintitle,str1,str2,str3,default);
        
    else % Run registration when in Unattended mode
        button = str1;
    end
    
    % Carry out the choice:
    switch button
        case str1
            disp('Running registration with default settings')
            
            runTifReg(obj);
            
            undoflag = 0;
            if ~obj.Unattended 
                undoflag = 1;
            end
            obj.Unattended = 1;
            getFrames(obj);
            if undoflag
                obj.Unattended = 0;
            end
            
        case str2
            disp('Using unregistered .tiff')
            FileName = [obj.Folder obj.TiffFile];
            
        case str3
            disp('Cancelled. No frames returned.')
            return
    end
    
end

% Now we have the correct reg.tif or tiff we can open it
s = warning('off','all');           % Disable warnings temporarily

% Open Tiff file as an object. Read-only mode.
tifobj = Tiff(FileName,'r+');

% First, get the number of frames (called Directories in Tiff objects):
setDirectory(tifobj,1)              % Make sure we're at the first frame.
while ~lastDirectory(tifobj)
    nextDirectory(tifobj);          % Scan through to last frame
end
objframes = currentDirectory(tifobj); % Find index of last frame

% Initialize stkStruct to size of Tiff stack:
stkStruct = zeros( getTag(tifobj,'ImageLength'), getTag(tifobj,'ImageWidth'), objframes , 1);

% Now go back to the first Tiff frame (default), or the first within the
% user-specified scan_extent:
setDirectory(tifobj,scan_extent(1))

% Scan through again and read the image data from each directory:
for n = 1:objframes
    
    stkStruct(:,:,n) = read(tifobj);
    
    % If scan_extent was specified we break the loop at the last frame
    % requested
    if currentDirectory(tifobj) == scan_extent(end)
        % And clear the remaining frames
        stkStruct(:,:, n + 1 : end ) = [];
        break
    end
    % If scan_extent was not specified, then scan_extent(end) = 0, which is
    % never reached. Loop is not broken.
    
    % Go to next frame:
    if n ~= objframes
        nextDirectory(tifobj);
    end
end

if ~obj.Unattended
    disp([num2str(n) ' frames returned.'])
end

% After reading all frames requeste, close the Tiff object
close(tifobj);
clear tifobj

warning(s); % Restore previous warning state

% Now do something with the frames which were read. Two behaviors here:
if nargin < 2
    % Normal behavior (all frames were requested)
    
    % Push frames to object.
    obj.Frames = stkStruct;
    % Save the mean image intensity too
    obj.AverageFrame = mean(stkStruct,3);
        
    % Ift he background had previously been subjected from the stored
    % obj.Frames, reset the flag now that original frames are restored:
    if obj.BackgroundSubtracted
        obj.BackgroundSubtracted = 0;
    end
    
else
    % If the function was called with an input argument to request a
    % subset of frames, the frames are returned but not pushed to the
    % object.
    %
    % The reason for this is that the size of obj.Frames is sometimes used
    % by other functions, such as 'play', to find the size of the object's
    % Tiff file. In some cases, it could be misleading to store less than
    % the full complement of frames in obj.Frames.
    
    
    % (if no output argument was specified, give a helpful msg instead of
    % causing an error)
    if nargout < 1
        disp('Subset of frames was requested - please specify an output variable')
        disp('ie.  Frames = getFrames(obj, scan_extent)')
    else
        varargout{1} = stkStruct;
    end
    
end


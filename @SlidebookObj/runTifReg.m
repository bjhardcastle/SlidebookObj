function runTifReg(obj, poolSiz, walkThresh, usfac)
%RUNTIFREG Runs ca_RegSeries_v4 image alignment on an object's Tiff file
% runTifReg(obj, poolSiz, walkThresh, usfac)
%
% This function runs Orkun's registration algorithm on an object's Tiff
% file, aligning frames and returning a second file with the ending
% '_reg.tif' in the same folder as the original. If the object's Tiff file
% is stored on a network drive, it is copied locally for faster read/write
% speeds. Warnings for 'jerk in frame' have been suppressed.
%
% This function accepts the following inputs:
%
%   poolSiz     - (optional) number of consecutive frames that will be
%                 averaged to make a reference frame for alignment. Short
%                 poolSiz is suited to high frequency movements, but may be
%                 prone to drift within the image.
%                 Default is 400.
%
%   walkThresh  - (optional) frame-to-frame displacement magnitude, in
%                 pixels, considered a 'jerk'/error. If a jerk is detected,
%                 the frame is filtered to reduce intensity variation and
%                 registered again. If the jerk persists, the frame is
%                 'skipped'; that is, it is not displaced relative to the
%                 preceeding frame.
%                 Default is 5.
%
%   usfac       - (optional) up-sampling factor used in sub-pixel
%                 registration. Increasing this may improve quality but
%                 will also increase run time.
%                 Default is 10.
%
% If any of the argument variables are set in an object, ie.
%  obj.poolSiz = 400;
%  obj.walkThresh = 5;
%  obj.usfac = 10;
% the value assigned to the object will be used, so long as a value is 
% not also passed as an input argument to this function. 
% Priority is:
%  1. function input
%  2. object property
%  3. default setting
%
% See also ca_RegSeries_v4_InputArgs, getFrames, runBackSub, Tiff.

% If no input arguments are supplied, check within object, then use defaults:
if nargin < 4
    if isprop(obj,'usfac') && ~isempty( obj.usfac )
        usfac = obj.usfac;
    else
        usfac = 10;
    end
end
if nargin < 3
    if isprop(obj,'walkThresh') && ~isempty( obj.walkThresh )
        walkThresh = obj.walkThresh;
    else
        walkThresh = 5; % hard threshold to identify big jerks that need extra attention
    end
end
if nargin < 2
    if isprop(obj,'poolSiz') && ~isempty( obj.poolSiz )
        poolSiz = obj.poolSiz;
    else
        poolSiz = 400;
    end
end

NETWORK_FILE = 0;

% If file is not on C:\ or D:\ it's likely on a portable or network drive
if ~strcmpi(obj.Folder(1), 'c') && ~strcmpi(obj.Folder(1), 'd')
    
    NETWORK_FILE = 1;
    
    % .. so copy tiff file to a new local folder
    local_root = 'C:\tempMatlab\';
    local_dir = [local_root obj.File '\'];
    network_filepath = [obj.Folder obj.TiffFile];
    
    % If the temp folder already exists, remove it
    if exist(local_root, 'dir')
        
        % Matlab can't remove the folder if it's the current
        % working directory, so move one folder up
        if strcmp(local_dir,cd)
            cd('\')
        end
        
        % Remove non-empty folder
        rmdir(local_root,'s')
        
    end
    
    % Make local temp folder and subfolder for this file
    mkdir(local_root)
    mkdir(local_dir)
    
    % Copy into the subfolder the object's Tiff file
    disp(['Copying files to ' local_root ''])
    copyfile(network_filepath, local_dir)
    
else
    % If the Tiff file is on a local drive, work on it directly
    local_dir = [obj.Folder];
end

% Run registration:
ca_RegSeries_v4_InputArgs(obj.TiffFile, local_dir, poolSiz, walkThresh, usfac);

% Copy reg_tif back to original folder on network drive
if NETWORK_FILE
    disp('Copying files back to network drive..')
    copyfile([local_dir obj.TifRegFile], obj.Folder)
    rmdir(local_root, 's')
end
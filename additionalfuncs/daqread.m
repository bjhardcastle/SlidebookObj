function [data, time, abstime, eventinfo, daqinfo] = daqread(filename, varargin)
%DAQREAD Frye lab version of the Data Acquisition Toolbox function to read
%customized (.daq) files
%
% This is a function for extracting data from spoof .daq files created on
% the Frye lab 2p system. Post-Matlab 2015 )using the session-based daq
% interface) we could no longer create .daq files that were compatible with
% daqread, but to try to make the transition seemless we continued to save
% logged data in binary files with the .daq extension, giving them a unique
% fid: 'SlbObj Data Acquisition File.'. This function simply recognizes
% those files and extracts the data appropriately or redirects to the
% regular daqread function if available. We will try not to disturb normal
% function in case someone forgets about this version of daqread.m in their
% path.

% Suppress warning about support:
% warning(message('MATLAB:daqread:legacySupportDeprecated', 'daqread'));

% Do the same checking of output arguments as original daqread to avoid
% problems if we redirect to it
if nargout > 5
    error(message('MATLAB:daqread:tooManyOutputs'));
end

% add .daq if missing from filename
[~,~,extStr] = fileparts(filename);
if isempty(extStr)
    filename = [filename '.daq'];
end

% Open the file and get its identifying file key
fid = fopen(filename, 'r', 'ieee-le');
assert(fid>=3, 'Invalid filetype')
fileKey=fscanf(fid,'%32c',1);

% Now check the file key to determine if custom .daq file
if ( strcmp(fileKey,['SlbObj Data Acquisition File.' 0 25 0]))
    % If so, we only have the logged data to extract:
    numChans = 1+str2double(fscanf(fid,'%1c',1));
    extractedData = fread(fid,[numChans,inf],'double');
    data = extractedData(2:end,:)';
    time=[]; abstime=[]; eventinfo=[]; daqinfo=[];
    fclose(fid);
    
elseif ( strcmp(fileKey,['MATLAB Data Acquisition File.' 0 25 0]))
    % Look for built-in function in usual location
    tryPath1 = fullfile(matlabroot,'toolbox','matlab','iofun','daqread.m');%should be located here if available
    
    % If it's not there we can also check for another version on the path,
    % assuming our version is still in a folder called additionalfuncs
    tryPath2 = which('daqread','-all');
    tryPath2(( ~cellfun('isempty',strfind(tryPath2,'additionalfuncs')) )) = [];
    
    % Check if the built-in version of daqread is available
    if exist(tryPath1, 'file')
        builtinPath = fileparts(tryPath1);
    elseif ~isempty(tryPath2) && exist(tryPath2{1}, 'file')
        builtinPath = fileparts(tryPath2);
    else
        fclose(fid);
        error('Could not locate built-in daqread function.');
    end
    
    % If found, change directory there and use that version of daqread
    currDir = cd;
    cd(builtinPath);
    try        
        % Make the number of input arguments match the user input to the top level call:
        if nargin < 2
            [data0, time0, abstime0, eventinfo0, daqinfo0] = daqread(filename); % Matlab built-in version
        else
            [data0, time0, abstime0, eventinfo0, daqinfo0] = daqread(filename, varargin{:}); % Matlab built-in version
        end
        % Same for the output arguments match the user input to the top level call:
        if nargout>0,data = data0;end
        if nargout>1,time = time0;end
        if nargout>2,abstime = abstime0;end
        if nargout>3,eventinfo = eventinfo0;end
        if nargout>4,daqinfo = daqinfo0;end
        
    catch ME
        % return to original directory if we get an error
        cd(currDir)
        rethrow(ME)
    end
    cd(currDir)
    
else % Neither a real or spoofed daq file
    fclose(fid);
    error(message('MATLAB:daqread:invalidDAQFile', filename));
end
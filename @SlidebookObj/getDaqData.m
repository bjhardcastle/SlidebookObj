function getDaqData(obj)
%GETDAQDATA Read an object's DAQ file and temporarily store the data within
% getDaqData(obj)
%
% This function writes to object:
%   obj.Daq     - all analog input channel data saved within obj.DaqFile
%                 This property is transient and is not stored with object
%                 when saved to disk. If an object is loaded, this
%                 function must be re-run.
%
% See also getFrametimes, getTrialtimes, getParameters.

% First, check DAQ file has been found automatically on object creation.
if isempty(obj.DaqFile) && obj.Unattended
    
    % If not, and this function was called in Unattended mode, show message:
    disp(['DAQ file not found. ' obj.File ' skipped'])
    return
    
elseif isempty(obj.DaqFile) && ~( obj.Unattended )
    % Otherwise, a file selection tool is launched:
    
    try
        getDaqFile(obj);
    catch
        % - in case GUI is cancelled
    end
    if isempty(obj.DaqFile)
        disp('No DAQ file exists - try running ''getDaqFile(obj)''')
        return
    end
    
end

% Read and push DAQ data to object:
disp('Reading DAQ file')
s = warning('off','all');           % Disable warnings temporarily
obj.Daq = daqread([obj.Folder obj.DaqFile]);
warning(s); % Restore previous warning state

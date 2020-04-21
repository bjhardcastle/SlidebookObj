function getDaqFile(obj)
% Find the path to the DAQ file saved by Matlab during an experiment. The
% function uses information from the log file associated with each tiff
% file (date, time) to locate the DAQ file in the same folder as the tiff.

% If the .log file is missing we can't reconstruct the DAQ file name
% automatically.
if isempty(obj.LogFile)
    %   Open a GUI and allow user to select a DAQ.
    getDaqFileGUI(obj)
    
else % Auto construct the DAQ filename
    
    % Shortcuts for filenames:
    daqTimeTry = str2num(obj.TimeStr);
    daqFile = getDaqPath(obj, daqTimeTry);
    daqPath = [obj.Folder daqFile];
            
    if exist(daqPath, 'file') ~= 2
        % Daq file may have been created up to 2 minutes before 2p capture started
        % Check for .daq files matching TimeStr - 1 minute, then -2 minutes
        n=0;
        while exist(daqPath, 'file') ~= 2 && n < 2
            n = n+1;
            daqTimeTry =  str2num(obj.TimeStr) - n;
            daqFile = getDaqPath(obj, daqTimeTry);
            daqPath = [obj.Folder daqFile];
        end
    end
        
        %Check the file exists before storing it
        if exist(daqPath, 'file') == 2
            obj.DaqFile = daqFile;
			% If unattended mode is off, open a user prompt
        elseif ~obj.Unattended
            getDaqFileGUI(obj);
		else
			obj.Daq = [];
            % At the end, if DAQ file hasn't been found, display a message:
	        disp(['No DAQ file added to object from ' obj.DateStr ' at ' obj.TimeStr ])
	end
    
	
end

function daqfiletry = getDaqPath(obj,exptime)
% Make sure exptime is within a correct range for hhmm
timeStr = num2str(exptime,'%04d');
if str2double(timeStr(3:4)) > 59
   exptime = exptime - 40;
end
daqfiletry = strcat(['aq_EXP_MASTER_20' obj.DateStr '_' num2str(exptime,'%.4d') '.daq']);

function getDaqFileGUI(obj)
% Prompt user for input
qstring = 'Could not find DAQ file automatically.';
title = 'Browse for DAQ file?';
str1 = 'Open file browser';
str2 = 'Continue without DAQ file';
default = str2;
button = questdlg(qstring,title,str1,str2,default);

if strcmp(button, str2)
    disp('Continue without DAQ file.')
    obj.DaqFile = [];
    return
end

% Open a file browser for manual selection of DAQ file
try
    [FileName] = uigetfile('*.daq',['Select the DAQ file for ' obj.DateStr ' at ' obj.TimeStr],obj.Folder);
    obj.DaqFile = FileName;
    
    % Grab the date and time strings from the DAQ filename too
    DigitStr = regexpi(FileName, '(\d*)', 'match');
    if length( DigitStr ) == 2 ...
            && length( DigitStr{1} ) == 8 ...
            && length( DigitStr{2} ) == 4
        obj.DateStr = char(DigitStr{1}(3:8));
        obj.TimeStr = char(DigitStr{2});
    end
    
catch % Avoids an error when file browser is closed before selecting a file
    obj.DaqFile = [];
    return
end
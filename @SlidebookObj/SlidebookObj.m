classdef SlidebookObj < handle_light
    %SLIDEBOOKOBJ Superclass for objects created from Slidebook Tiff files 
    %
    % The superclass contains some basic tools and the common core 
	% functionality for analysis of tiff files from the Frye lab 
	% 2p system, usually with a corresponding DAQ file from Matlab. 
	%
	% Please do not edit the FryeNas version of this file or its methods files,
	% as all existing subclasses rely on them to function! 
	%
	% Modifications and extensions should be made on a subclass.     
    % See MODIFICATION below.
    %
    %
    % CREATION: 
    % Create by calling
    %  obj = SlidebookObj(Tiffpath)
    % or 
    %  obj = SlidebookObj  - opens file browser
    % or
    %  makeObj             - opens GUI for constructing an object array
    % 
    %
    % ORGANIZATION: 
    % An experiment with N Tiff files should be organized as a [1xN] array,
    % ie.
    %  objarray(1) = SlidebookObj( Tiffpath{1} )
    %  objarray(2) = SlidebookObj( Tiffpath{2} )
    %  ... 
    % 
    %
    % CONVENTIONS: 
    % Some functions (METHODS) are designed to run on an array of objects,
    % indicated by input argument 'objarray', ie.
    %  sort(objarray)
    % 
    % while most run on a single object, or a single element within an
    % array, ie.
    %  runTifReg( objarray(1) )
    %
    % Generally, function prefixes mean:
    %  get....      - gets some data/parameter related to the experiment and
    %                 assigns them to the object
    %  run....      - modifies some data/parameter  
    %  find...      - similar to 'get...', but returns a more specific
    %                 parameter 'on-demand' for immediate use, which is not 
    %                 assigned to the object
    %  plot...      - you guessed it
    %
    % Object variables (PROPERTIES) may be unique for a single object, ie. 
    %  obj.DateStr  - the date the Tiff file was recorded
    %  obj.IFI      - average inter-frame interval
    % 
    % or saved individually for each 'trial'. Trial times are obtained from 
    % DAQ AI Ch 2 or 3, assuming the DAQ file can be located, and are saved
    % in terms of DAQ sample index and frame number, found from DAQ AI Ch 1.
    % Various parameters for each trial are found, ie.
    %  obj.TrialStartFrame 
    %  obj.TrialXGain
    %  obj.TrialPatNum
    %
    % The array of values for all trials can be accessed with square
    % brackets, ie.
    %  [obj.TrialXGain] 
    % or individual values accessed through indexing,
    %  obj.TrialXGain(1) 
    %  
    %
    % AUTOMATIC LINKING TO FILES:
    % Upon creation, the constructor function will attempt to find the
    % associated files:
    %  TifRegFile   - Registered Tiff file from ca_RegSeries
    %  LogFile      - log.txt saved on Tiff export from Slidebook
    %  DaqFile      - DAQ channel data saved during experiment 
    % If the DAQ file cannot be found a file browser will open for the user
    % to locate it manually, since most data processing relies on info from
    % the saved DAQ data. The exception to this is if obj.Unattended = 1.
    % If the other files do not exist they will be stored as empty arrays.
    %
    %
    % MODIFICATION:
	% Creating a subclass of the SlidebookObj class will give it all of the same
	% properties and methods available to the superclass. New methods can be added
	% and existing methods can be overloaded by giving them a new version of the 
	% .m file. 
	% (see Matlab documentation on subclasses, class definitions and overloading)
    %
	% An example subclass constructor method is provided below.
	%
    %
    % This is still in development and errors are likely to be encountered.
    % Please let me know when you find problems, need help or have any 
    % suggestions for changes/features.            					ben, Dec 2017
    %
    % See also makeObj, exampleSbObjSubclass.
   
     properties (Dependent)
        Link    % Link to open Folder in Windows File Explorer - depends on 'Folder'
		BackSubFile  % Filename for saving/loading background subtracted files (.mat format, stored in 'Folder')
     end

    properties
        Fly     % Fly number. A single fly can be linked to more than one object 
        File    % Tiff file name, without extension
        Folder  % Tiff file folder path
        DateStr % Tiff capture date: 'yymmdd'
        TimeStr % Tiff capture time: 'hhmm'
        DaqFile % DAQ data filename: aq_EXP_MASTER_20{DateStr}_{TimeStr}.daq
        Detrend = 0 % If set to 1, some functions (runBackSub, getActivityFrame) will detrend activity in frames 
        AIrate = 10000      % DAQ sampling rate, samples per second
		UseBackSubFrames    % If set to 1, scanROI and getFrames will use saved background subtracted frames, if available

    end
    
    properties (Transient)
        % Only stored temporarily. When the object is saved to disk, these
        % properties are not saved (since they are large and already on disk)
        
        Daq             % Time-series data extracted from DaqFile
        Frames          % Tiff frames. Clear to save memory
        Unattended = 0  % Set to 1 to run functions without requesting user input 
    end
    
    properties (Transient = true, SetAccess = protected)
        % As above, but can only be modified by a class method
                
        BackgroundSubtracted = 0  % Read-only marker that indicates background has been subtracted from stored Frames, if set to 1.

    end
    
    properties (SetAccess = protected, Hidden = true)
        % Can only be modified by a class method. 
        % Hidden from display in Command Window. 
        
        % Path to files below can be obtained using:
        % fullfile( obj.Folder, obj.LogFile )
        TiffFile            % Tiff file name with extension
        LogFile             % Log file name: File.log
        TifRegFile          % Registered Tiff file name: Tiff(1:end-4)_reg.tif
                        
        % Parameters extracted from the DAQ AI time-series data, using the 
        % functions getFrametimes and getTrialtimes:
        Frametimes          % Extracted frame times, in DAQ samples
        IFI                 % Inter-frame interval, in DAQ samples
        
        TrialStartSample    % Each trial's start time, in DAQ samples
        TrialEndSample      % Each trial's end time, in DAQ samples
        
        TrialStartFrame     % Each trial's start time, in frame number               
        TrialEndFrame       % Each trial's end time, in frame number
        
        % Parameters extracted from the DAQ AI time-series data, using the
        % function getParameters:
        ExpXGains           % Array of X gains used in experiment
        ExpYGains           % Array of Y gains used in experiment
        ExpXOnTime          % Estimated time of panels X movement onset after trial start, in seconds
        ExpXOffTime         % Estimated time of panels X movement offset after trial start, in seconds
        ExpYOnTime          % Estimated time of panels Y movement onset after trial start, in seconds
        ExpYOffTime         % Estimated time of panels Y movement offset after trial start, in seconds
        
        TrialPatNum         % Voltage level on DAQ(:,2) multiplied by 5
        TrialSeqNum         % Voltage level on DAQ(:,3) multiplied by 5
        % Ch 2/3 can be reversed by setting obj.SwitchPatSeqDaqChans = 1
        
        TrialXGain          % Panels X gain from DAQ(:,4)
        TrialYGain          % Panels Y gain from DAQ(:,5)
        % Ch 4/5 can be reversed by setting obj.SwitchXYDaqChans = 1
        
        TrialCh6            % Voltage level on DAQ(:,6) if it exists (no longer used)
		TrialLED			% Max voltage level on DAQ(:,6) if it exists
        TrialCh7            % Voltage level on DAQ(:,7) if it exists
                
        % Note: these 4 arrays are likely to include NaNs
        TrialXOnFrame       % Time of panels X movement onset after each trial start, in num. of frames
        TrialXOffFrame      % Time of panels X movement offset after each trial start, in num. of frames
        TrialYOnFrame       % Time of panels Y movement onset after each trial start, in num. of frames
        TrialYOffFrame      % Time of panels Y movement offset after each trial start, in num. of frames
    end

    properties (Hidden)
        % Hidden from display in Command Window, but can be manually
        % edited.
                
        TrialSettings = struct  % Settings used in getTrialtimes        
        % To modify how trials are detected, assign any of these fields in
        % your subclass ( Defaults are listed below - see getTrialtimes ):        
        % TrialSettings.extent = []; 
        % TrialSettings.chan = 2;
        % TrialSettings.minpeak = 0.1;
        % TrialSettings.joined = 0;
        % TrialSettings.plotflag = 0;
        % TrialSettings.firstTrialError = 1;
        
        % Images
        AverageFrame        % Mean of all Tiff frames
        ActivityFrame       % Mean of Tiff frames within trials, minus mean frame outside trials

        % Additional empty slots for images which can be added and
        % displayed in 'play' to aid in drawing ROIs:
        ActivityFrame1 
        ActivityFrame2 
        ActivityFrame3  
        ActivityFrame4
        ActivityFrame5
        ActivityFrame6 
        ActivityFrame7  
        ActivityFrame8
        ActivityFrame9 
        ActivityFrame10 
        ActivityFrame11 
        ActivityFrame12
        ActivityFrame13
        ActivityFrame14
        ActivityFrame15
        ActivityFrame16
        ActivityFrame17
        ActivityFrame18
        ActivityFrame19
        ActivityFrame20
        ActivityFrame21
        ActivityFrame22
        ActivityFrame23
        ActivityFrame24
        ActivityFrame25
		
        ROI                % Saved ROI information        
        % ROIs are drawn in 'play' and must be manually saved to the
        % object, using the button in the play toolbar.
        % Once saved, each ROI's (x,y) frame position is converted into a
        % binary mask, and stored along with the ROI's individual color.
        % Each object's ROI info is stored as a stucture array:
        %
        %  obj.ROI(ROIindex).mask
        %                   .color
        %                   .position
        %					.response   (see below)
		%
        % All ROI information can easily be transferred from one object to
        % another:
        %  obj2.ROI = obj1.ROI; 
        %
        % Note: 
        % The dimensions of each mask must be the same as the Tiff frame
        % size. If this isn't the case (following the example above): 
        %  run 'play(obj2)'
        %  save the imported ROIs
        % This will re-make the masks with the correct frame size. 
        %
		% obj.ROI.response was added later and is used to store the time-series extracted with scanROI using the ROI's mask.
		% The default behavior of 'scanROI' is to get this time-series 'on demand' using the current mask and frames.
		% If the property obj.UseFixedResp is set to 1, scanROI will look for a stored time-series in ROI.response 
		% and use that instead. This is quicker than pulling up the tiff files, but any changes to the ROI position or mask 
		% won't be reflected until the stored response is updated (updateROIs does this for all ROIs across all objects in an array). 
		UseFixedResp % Set to 1, the stored time-series in obj.ROI.response will be used by scanROI instead of scanning frames
		
        % Custom parameters for ca_RegSeries can also be set, see runTifReg
        poolSiz
        walkThresh
        usfac

        BackSubReps = 1                  % see runBackSub
        
        AccurateInterpolation = 1        % See findFittedTrial
        
        OA  % toggle for karen's T4/T5 subclass 
        
        SwitchPatSeqDaqChans % see getParameters
        SwitchXYDaqChans 
    end
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods  % Constructor - runs on object creation
        
        function obj = SlidebookObj(pathIN)
            
            % If no path is specified:
            if nargin == 0 || isempty(pathIN)
                try                    
                    [FileName,PathName] = uigetfile('*.tif*');
                    obj = getTiffPath(obj, fullfile(PathName,FileName) );
                catch
                end
            end
            
            % If path is specified:
            if nargin >0 && ~isempty(pathIN)
                if isa(pathIN,'char')
                    obj = getTiffPath(obj,pathIN);
                else
                    error('Please input path to tiff file as a string, or leave empty')
                end
            end
            
            % Get linked files:
            if  ~isempty(obj.File)
                
                getTifRegPath(obj);
                getLogData(obj);
                getDaqFile(obj);
            else 
                clear obj
                return
            end
            
        end
        
        % Basic code for a subclass constructor:
        %{
        function obj = subclassObj(pathIN)
        
            if nargin == 0                
               pathIN = [];
            end
        
            % Call superclass constructor:
            obj@SlidebookObj(pathIN);
            
            % Run some additional code on creation:
            try
                % SubclassFunction(obj);
            catch ME
                msgText = getReport(ME);
                disp('Constructor error:')
                disp(msgText)
            end
        
        end   
        %}
	end % end of constructor method
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	methods   % For dependent properties
		
		% Method for dependent property giving hyperlink to object path in explorer (Windows)
        function Link = get.Link(obj)
            Link = ['<a href="matlab:winopen(''' obj.Folder ''')">open folder</a>'];
        end
            
		% Method for dependent property that gives filename for background subtracted frames (stored in obj.Folder path as .mat file)
		function value = get.BackSubFile(obj)       
        % Test file exists before returning
        try_name = [obj.File '_BackSubFrames.mat'];
			if exist(fullfile( obj.Folder,try_name)) == 2
				value = try_name;
			else
				value = [];
			end
		end
	
	end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access=public)
        % All functions below can be copied into a subclass 
        % (along with their .m file) and re-defined as needed
        
        
        %%%%%% Functions that must be customized %%%%%%%%%%%%%%%%%%%%%%%%%%
        
        F0 = findF0(obj, mask, trialData,  trialIdx, timeVector, normFPS) % Define the time-series that will be used for each trial's baseline intensity
        % F0 is found 'on-demand' when requesting normalized trial data, 
        % e.g when plotting trials. The time period in each trial (or
        % before each trial) that should be used as the 'F0' baseline 
        % intensity is specific and should be defined according to your
        % experimental protocol within the function 'findF0'
        
        
        %%%%%% Functions for initial processing %%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        % Image registration
        runTifReg(obj, poolSiz, walkThresh, usfac) % Runs ca_RegSeries_v4 (O. Akin) image alignment on an object's Tiff file
                
        % Process DAQ AI channel data         
        % Each successive function relies on the previous one, and if
        % they haven't already been run, they will be called automatically.
        % So, to capture all information from the DAQ file, just run
        % getParameters. No need to run each individually. 
        getDaqData(obj) % Read an object's DAQ file and temporarily store the data within
        getFrametimes(obj) % Detect frame markers in DAQ data and store in object
        getTrialtimes(obj) % Gets trial starts / ends from DAQ channel 2 or 3
        getParameters(obj) % Extract additional trial parameters from saved DAQ data        
        
		[checkFig] = checkTrials(obj, trialsettings, trialstarts, trialends) % plots a figure with all trial start/stop times displayed on the Daq trace
		addToTrialStart(objarray,numSec) % manually shift the start point of all trials
		addToTrialEnd(objarray,numSec) % manually shift the end point of all trials  
			
				
				
		%%%%%% Explore data in GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
        play(obj,frame_idx) % Opens a GUI (J. Strother) to playback frames, draw ROIs, examine time-series 
        	
		% Make average images to guide ROI creation
        assignPatternActivityFrames(objarray,patnum) % Assigns average activity frames for all patterns and makes them available in 'play' as a toggle button 
		[image] = getActivityFrame(obj,fields,detrend) % Gets the average activity frame during specified trials. Assign image to obj.ActivityFrameN to make available in 'play'
		
		% Add some auto-generated ROIs 
		autoROI = findROIs(obj, numROIs, fields) % (uses k-means clustering on time-series)
		
		% Save/reload ROIs. 
		loadROIs(objarray) % The ROIs are associated with a tiff file, independent of the object itself
		saveROIs(objarray) % Saved as a .mat file in the same location as the tiff file
		
		
		
        %%%%%% Functions for plotting dF/F0 in ROIs for specific trials %%%   
        % Search for trials 
		[trialIdx] = findTrials(obj,fields); % Find trials which used specific values for a set of parameters        
			
		% Time-series plots 
        [tfig, taxes] = plotTrials(objarray, ROImaskidx, fields, errorbar, plotcolor, fig) % Basic time-series plotting function 
        [patchHandle] = plotStimPatch(obj,taxes,stimOnOff,chanStr,patchcolor) % Add a grey patch to mark a stimulus on a time-series plot
        
		% Pair-wise comparison plots
        [pwFig, pwAxes, pwMaxData] = plotPWmax(objarray, ROImaskidx, fields, before, after, pwFig) % compare max dF/F0 values in two sets of trials ('before','after')    
        
		
		
        %%%%% Other basic functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [Ftrace] = scanROI(obj, mask, scan_extent) % Find mean intensity value within binary mask across frames specified by 'scan_extent'
        changeRoot(objarray,oldroot,newroot) % Change part of the path to an object's tiff file (in case tiff data are moved but some folder structure remains the same)
		objarray = sort(objarray,direction) % Sort objects by date & time of capture in chronological order (default)
		updateROIs(objarray) % updates the stored response trace in each ROI (not commonly used)
		showROIs(obj,ROIidx,invertImage) % Plot the position of the object's ROIs on an average activity frame

		
		
        %%%%%% Tools called by other functions. Not usually run alone %%%%%        
        [frames] = getFrames(obj,scan_extent) % Read the frames from an object's registered Tiff file
        runBackSub(obj) % Subtract off background intensity changes from stored frames - also available in 'play' (not commonly used)
        loadBackSubROIs(objarray) % load function for ROIs which contain background subtracted time-series
		saveBackSubROIs(objarray) % save function for ROIs which contain background subtracted time-series
		[responseArray, timeVector, F0Array, numExps] = findRespArray(objarray, ROImaskidx, fields) % Get aligned time-series data with a common sampling rate across multiple objects
        [timeVector, normFPS, trialDuration] = findStandardTrial(objarray) % Used on an array of objects to find a common sampling rate 
        [fittedData] = findFittedTrial(obj, trialData, trialIdx, timeVector, normFPS, trialDuration) % Used on a single object to apply the common sampling rate parameters returned by 'findStandardTrial'
		[trialstarts, trialends] = detectTrials(obj,trialsettings); % Core code for detecting trial starts / ends from DAQ channel 2 or 3
        [chanGains] = detectTrialGains(obj, chanIdx, panels_refresh_rate) % Core code for detecting gains on LED panels, called by getParameters
        [ExpStimOnTime, ExpStimOffTime, TrialStimOnFrame, TrialStimOffFrame] = detectPanelsMovement(obj,gainStr)% Core code for detecting movement on LED panels, called by getParameters
        [frameIdx] = nextFrame(obj,sampIdx) % Find the first recorded frame after a particular sample in DAQ data
        [frameIdx] = prevFrame(obj,sampIdx) % Find the last recorded frame before a particular sample in DAQ data   
        [STDtrace] = scanROIstd(obj, mask, scan_extent) % Find std of intensity values within mask across frames (not commonly used)
        [detrendedFrames] = detrendFrames(obj) % Detrend activity across all frames (not commonly used)
		
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
end
# SlidebookObj

SlidebookObj is a Matlab class for processing and analyzing Tiff files generated by the Frye lab 3i 2-photon system.

The class contains some basic tools for exploring data using ROIs (similar to the Slidebook software), making use of the accompanying DAQ file saved with each experiment to make it easy to find sections of a recording which correspond to a particular stimulus event.

## Getting started

### Installation

Download the .zip file [here.](https://github.com/bjhardcastle/SlidebookObj/archive/master.zip)

Unzip the contents and save the 'SlidebookObj-master' folder somewhere, renaming it if you like. 

Add all subfolders to Matlab's path so it can access them. 
To do this automatically, open the included file [addToPath.m](addToPath.m) in Matlab and run it. 
 
  
### Creating an object from a Tiff file

Create a new object by running 
```
obj = SlidebookObj  % opens a file browser
```
or specify the path to a Tiff file
```
obj = SlidebookObj(Tiffpath) % Tiffpath is the location of a tiff file as a string
```

Alternatively, use a GUI to make multiple objects at once and run some initial processing on each one by running
```
makeObj
```




### Minimum requirements

Upon creation, the constructor function will attempt to find other files associated with the Tiff file:
```
obj.LogFile      % log.txt saved on Tiff export from Slidebook

obj.DaqFile      % DAQ analog input data logged during experiment 
```

If the DAQ file cannot be found a file browser will open for the user
to locate it manually, since most analysis of an experiment relies on info from
the logged DAQ data. 

Tested in Matlab 2017a and later. Some built-in Matlab functions used in this class (including 'contains.m') may be missing from earlier versions.

## Conventions

### Trials
Most analysis with the SlidebookObj class relies on markers encoded on DAQ analog input channel 2 or 3 that denote periods during which a stimulus was running (panels display, Chrimson excitation etc.). These periods are are referred to as 'trials'. Each trial is marked by a rising edge at the start and falling edge at the end, with a DC voltage in between which can be used to encode some parameter associated with the trial (pattern number, for example). Trial start/end times are stored both in terms of DAQ sampling index and the index of the nearest frame captured within the trial.

### Object variables 

Variables (or 'properties' in Matlab object terminology) may have a single value per object, for example: 
```
obj.DateStr  % the date the Tiff file was recorded

obj.IFI      % average inter-frame interval
```  

Variables with the prefix 'Trial' are a [1xN] array with one value per trial, for example:
```
obj.TrialStartFrame	% Index of first frame captured after onset of each trial

obj.TrialXGain		% Gain applied to panels X position during each trial

obj.TrialPatNum		% Pattern number used in each trial
```

The array of values for all trials can be accessed with square
brackets:
```
[obj.TrialXGain] 
```
or individual values can be accessed through indexing:
```
obj.TrialXGain(1) 
```


### Object functions
 
Most functions (or 'methods') can only run on a single object, for example:
```
getFrames(obj)
```

Where functions can run on an array of objects, the first input argument is changed to 'objarray':
```
sort(objarray)
```

For these functions to work, a dataset containing multiple Tiff files should be organized as a [1xN] object array:
```
objarray(1) = SlidebookObj( Tiffpath{1} )
objarray(2) = SlidebookObj( Tiffpath{2} )
```



## Workflow

### Initial processing

Process DAQ AI channel data with these commands:
```
getDaqData(obj) 
% Read an object's DAQ file and temporarily store the data within

getFrametimes(obj) 
% Detect frame markers in DAQ data and store in object

getTrialtimes(obj) 
% Gets trial starts/ends from DAQ channel 2 or 3

getParameters(obj) 
% Extract additional trial parameters from saved DAQ data    
```
Each successive function relies on processed data from all of the preceding functions, but the relevant functions will be called automatically if any of it is missing.

Then check trial detection and tweak start/end times if required:
```
[checkFig] = checkTrials(obj, trialsettings, trialstarts, trialends) 
% plots a figure with all trial start/stop times displayed on the Daq trace

addToTrialStart(objarray,numSec) % manually shift the start point of all trials
addToTrialEnd(objarray,numSec) % manually shift the end point of all trials  
 ```
 
 
 
### Explore data in GUI

```
 play(obj,frame_idx) % Opens a GUI (J. Strother) to playback frames, draw ROIs, examine time-series 
```
			
Make average images to guide ROI creation
```
assignPatternActivityFrames(objarray,patnum) 
% Assigns average activity frames for all patterns and makes them available in 'play' as a toggle button 

[image] = getActivityFrame(obj,fields,detrend) 
% Gets the average activity frame during specified trials. Assign image to obj.ActivityFrameN to make available in 'play'
```

Add some auto-generated ROIs 
```
autoROI = findROIs(obj, numROIs, fields) 
% (uses k-means clustering on time-series)
```


Save/reload ROIs
```
loadROIs(objarray) 
% The ROIs are associated with a tiff file, independent of the object itself

saveROIs(objarray) 
% Saved as a .mat file in the same location as the tiff file
```



### Find and plot activity in specific trials 

Search for trials 
```
[trialIdx] = findTrials(obj,fields); 
% Find trials which used specific values for a set of parameters        
```

Time-series plots 
```
[tfig, taxes] = plotTrials(objarray, ROImaskidx, fields, errorbar, plotcolor, fig) 
% Basic time-series plotting function 

[patchHandle] = plotStimPatch(obj,taxes,stimOnOff,chanStr,patchcolor) 
% Add a grey patch to mark a stimulus on a time-series plot
```

Pair-wise comparison plots
```
[pwFig, pwAxes, pwMaxData] = plotPWmax(objarray, ROImaskidx, fields, before, after, pwFig) 
% compare max dF/F0 values in two sets of trials ('before','after')    
```
		



### Other basic functions 

These may be useful building blocks for new functions:

```
[frames] = getFrames(obj,scan_extent)
% Read the frames from an object's registered Tiff file

[Ftrace] = scanROI(obj, mask, scan_extent) 
% Find mean intensity value within binary mask across frames specified by 'scan_extent'

[responseArray, timeVector, F0Array, numExps] = findRespArray(objarray, ROImaskidx, fields) 
% Get aligned time-series data with a common sampling rate across multiple objects

```

Some tools:
```
changeRoot(objarray,oldroot,newroot) 
% Change part of the path to an object's tiff file (in case tiff data are moved but some folder structure remains the same)

objarray = sort(objarray,direction) 
% Sort objects by date & time of capture in chronological order (default)

updateROIs(objarray) 
% updates the stored response trace in each ROI (not commonly used)

showROIs(obj,ROIidx,invertImage) 
% Plot the position of the object's ROIs on an average activity frame

runBackSub(obj) 
% Subtract off background intensity changes from stored frames - also available in 'play' (not commonly used)

loadBackSubROIs(objarray) 
% load function for ROIs which contain background subtracted time-series

saveBackSubROIs(objarray) 
% save function for ROIs which contain background subtracted time-series
```

Some tools called by other functions, these are not typically run on their own: 
```
[timeVector, normFPS, trialDuration] = findStandardTrial(objarray) 
% Used on an array of objects to find a common sampling rate 

[fittedData] = findFittedTrial(obj, trialData, trialIdx, timeVector, normFPS, trialDuration) 
% Used on a single object to apply the common sampling rate parameters returned by 'findStandardTrial'

[trialstarts, trialends] = detectTrials(obj,trialsettings);
 % Core code for detecting trial starts/ends from DAQ channel 2 or 3

[chanGains] = detectTrialGains(obj, chanIdx, panels_refresh_rate) 
% Core code for detecting gains on LED panels, called by getParameters

[ExpStimOnTime, ExpStimOffTime, TrialStimOnFrame, TrialStimOffFrame] = detectPanelsMovement(obj,gainStr)
% Core code for detecting movement on LED panels, called by getParameters

[frameIdx] = nextFrame(obj,sampIdx) 
% Find the first recorded frame after a particular sample in DAQ data

[frameIdx] = prevFrame(obj,sampIdx) 
% Find the last recorded frame before a particular sample in DAQ data   
```



## Modification and extension

Although the SlidebookObj class can run basic analyses for generic experiments, its intended purpose is to act as a 'superclass', from which subclasses can be made with more specific features tailored to individual experiments.

A subclass will inherit all of the SlidebookObj functionality, and in addition new methods can be created and existing methods can be modified.

See the Matlab documentation on subclasses, class definitions and overloading: 
[Introduction to object-oriented programming](https://www.mathworks.com/company/newsletters/articles/introduction-to-object-oriented-programming-in-matlab.html)

An example subclass constructor method is provided in the [SlidebookObj.m](https://github.com/bjhardcastle/SlidebookObj/blob/master/%40SlidebookObj/SlidebookObj.m) class definition file.





## Author 

Ben Hardcastle, Frye lab, UCLA

December 2017

## Acknowledgments

* James Strother's Neuron Image Analysis toolbox was the inspiration and blueprint for this project. The [play.m](https://github.com/bjhardcastle/SlidebookObj/blob/master/%40SlidebookObj/play.m) function also uses his GUI for playback of Tiff files. [bitbucket.com/jastrother](https://bitbucket.org/jastrother/neuron_image_analysis/src/master/)

## License

This project is licensed under the MIT License
<!--  - see the [LICENSE.md](LICENSE.md) file for details -->

# SlidebookObj

SlidebookObj is a Matlab class for processing and analyzing Tiff files generated from the Frye lab 3i 2-photon system.

The class contains some basic tools for exploring data using ROIs (much like the Slidebook software), making use of the accompanying DAQ file saved with each experiment to make it easy to find sections of a recording which correspond to a particular stimulus event.

## Getting Started

Find the green 'Clone or download' button and 'Download as ZIP'.

Unzip the contents and save the 'SlidebookObj-master' folder somewhere, renaming it if you like. 

Open the file
```
addToPath.m
```
in Matlab and run it, so Matlab can find the '@SlidebookObj' folder and 'additionalfuncs'.
 
 
## Creating an object from a .tiff file

Create a new object by running 
```
obj = SlidebookObj  % opens a file browser
```
or specify the path to a tiff file
```
obj = SlidebookObj(Tiffpath) % Tiffpath is the location of a tiff file as a string
```

Alternatively, use a GUI to make multiple objects at once and run some initial processing on each one by running
```
makeObj
```

## Minimum requirements
Upon creation, the constructor function will attempt to find other files associated with the Tiff file:
```
obj.LogFile      % log.txt saved on Tiff export from Slidebook
obj.DaqFile      % DAQ analog input data logged during experiment 
```

If the DAQ file cannot be found a file browser will open for the user
to locate it manually, since most analysis of an experiment relies on info from
the logged DAQ data. The exception to this is if obj.Unattended = 1.

## Object functions 
Most functions (called 'methods' in Matlab object-oriented terminology) will only run on a single object, for example
```
runTifReg(obj)
```
Some will run on an array of objects, indicated by the input argument 'objarray'
```
sort(objarray)
```
For these functions to work, a dataset containing multiple Tiff files should be organized as a [1xN] object array
```
objarray(1) = SlidebookObj( Tiffpath{1} )
objarray(2) = SlidebookObj( Tiffpath{2} )
```

## Object variables 
Variables ( or 'properties') may be unique for a single object, ie. 
```
obj.DateStr  % the date the Tiff file was recorded
obj.IFI      % average inter-frame interval
```  
or saved individually for each 'trial'. Trial times are obtained from 
DAQ analog input channel 2 or 3, assuming the DAQ file can be located, and are saved in terms of DAQ sample index and frame number, found from DAQ channel 1.
Various parameters for each trial are found:
```
obj.TrialStartFrame     % Index of first frame captured after trial onset
obj.TrialXGain			% Gain applied to panels X position during trial
obj.TrialPatNum			% Pattern number used in trial
```
The array of values for all trials can be accessed with square
brackets,
```
[obj.TrialXGain] 
```
or individual values accessed through indexing,
```
obj.TrialXGain(1) 
```

## Modification and extension
The SlidebookObj class can run basic analysis for generic experiments. Its intended purpose is to act as a 'superclass', from which subclasses can be made with more specific features tailored to individual experiments.

A subclass will inherit all of the SlidebookObj functionality, and in addition new methods can be created and existing methods can be modified.
(see Matlab documentation on subclasses, class definitions and overloading: 
[Mathworks introduction to object-oriented programming](https://www.mathworks.com/company/newsletters/articles/introduction-to-object-oriented-programming-in-matlab.html))

An example subclass constructor method is provided in the SlidebookObj.m class definition file.


## Author 
Ben Hardcastle, Frye lab, UCLA, December 2017

## Acknowledgments

* The original GUI for playback of Tiff files is taken from James Strother's Neuron Image Analysis toolbox, which was the inspiration and blueprint for this project. [bitbucket.com/jastrother]https://bitbucket.org/jastrother/neuron_image_analysis/src/master/

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

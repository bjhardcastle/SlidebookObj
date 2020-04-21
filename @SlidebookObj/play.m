function play(obj,scan_extent)
%PLAY Play the frames specified in the passed object.
% play(obj,scan_extent)
% 
% This function is a wrapper for a GUI developed by James Strother for 
% displaying 2P image data and drawing ROIs:
% https://bitbucket.org/jastrother/neuron_image_analysis
%
% It has been modified to fit with the SlidebookObj class, and some 
% Frye lab-specific features have been added.
% 
% The core code for the GUI is in  nia_sbo_playGenericMovie.m
% 
% Inputs to this function are: 
%     scan_extent     - (optional) [1x2] array of frame indices, marking 
%                       [start, stop] frames of the object's Tiff file to 
%                       be played. For large Tiff files, only reading in the 
%                       first few frames uses less memory and allows the GUI
%                       to run faster.
% 
% ROIs are drawn in play and must be manually pushed to the
% object using the 'Save' button in the toolbar.
% 
% Each ROI's (x,y) frame position is then converted into a
% binary mask and stored along with the ROI's individual color.
% Each object's ROI info is stored as a structure array:
% 
%  obj.ROI(ROIindex).mask
%                   .color
%                   .position
% 
% All ROI information can easily be transferred from one object to
% another:
%  obj2.ROI = obj1.ROI; 
% 
% Note: 
% The dimensions of each mask must be the same as the Tiff frame
% size. If this isn't the case (following the example above): 
%  run 'play(obj2)'
%  press the save button 
% This will re-make the masks with the correct frame size. 
%    
% The save button in this GUI only pushes the ROIs to the object. 
% To save them to disk in the same folder as the object's tiff file:
%  saveROIs(obj)
%
% Any object made with the same tiff file in the future can then reload 
% the saved ROIs by running:
%  loadROIs(obj)
%
% See also nia_sbo_playGenericMovie.

if nargin < 2
    scan_extent = [1 0];
end

if isempty(obj.Frames)
    if isempty(scan_extent) || nargin<2
        % Fetch tiff frames and store in object
        getFrames(obj);
        ObjMov = obj.Frames;
    else
        ObjMov = getFrames(obj,scan_extent);
    end
else % Frames already exist
    
    if isempty(scan_extent)
        ObjMov = obj.Frames;
    elseif isequal(scan_extent,[1 0])
        ObjMov = obj.Frames;
    else
        ObjMov = obj.Frames(:,:, scan_extent(1) : scan_extent(end) );
    end
end

try
    nia_sbo_playFlatMovie(obj, ObjMov);
catch ME
    msgText = getReport(ME);
    disp('Error playing object:')
    disp(msgText)
end

end
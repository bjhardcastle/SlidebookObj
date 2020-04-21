function showROIs(obj,ROIvector,invertImage)
% Quick function to make a figure with the average activity frame and one or more ROI positions.
% Input:
%
%       ROIvector     Numerical vector with index of each ROI belonging to the object to be added to the image
%		invertImage   logical, if true activity image will have white background, dark cells 
%
if nargin < 2 || isempty(ROIvector)
	ROIvector = [1:length(obj.ROI)];
end

if nargin < 3 || isempty(invertImage)
	invertImage = 0;
end

try
if isempty(obj.ActivityFrame)
aFrame = getActivityFrame(obj);
else
aFrame = obj.Activityframe;
end
titleStr = 'activity';
catch
aFrame = obj.AverageFrame;
titleStr = 'mean intensity';
end

figure,
imagesc(aFrame)
if invertImage
	colormap(flipud(gray))
else
	colormap(gray)
end

for rIdx = ROIvector
    hold on
	if ~isempty(obj.ROI(rIdx).position)
		% get ROI position
		xPts = obj.ROI(rIdx).position(:,1);
		xPts = [xPts; xPts(1)]; % close the ends of the ROI for drawing 
		yPts = obj.ROI(rIdx).position(:,2);
		yPts = [yPts; yPts(1)];
		
		plot(xPts,yPts,'Color', ROIcolor((rIdx)),'LineWidth',2)		
	end
end
addExportFigToolbar(gcf)
function saveROIs(objarray)
%SAVEROIS Save ROI structures to disk in their own .mat file
% saveROIs(objarray)

for oidx = 1:length(objarray)
   filename = [objarray(oidx).DateStr objarray(oidx).TimeStr 'ObjROIs.mat'];
   folder = [objarray(oidx).Folder];
   ROI = objarray(oidx).ROI;
   save( fullfile(folder,filename), 'ROI' );
end
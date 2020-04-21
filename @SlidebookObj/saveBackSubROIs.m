function saveBackSubROIs(objarray)
%SAVEBACKSUBROIS Save ROI structures to disk in their own .mat file
% saveBackSubROIs(objarray)

for oidx = 1:length(objarray)
   filename = [objarray(oidx).DateStr objarray(oidx).TimeStr 'ObjBackSubROIs.mat'];
   folder = [objarray(oidx).Folder];
   ROI = objarray(oidx).ROI;
   save( fullfile(folder,filename), 'ROI' );
end
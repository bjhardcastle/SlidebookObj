function loadBackSubROIs(objarray)
%SAVEBACKSUBROIS Load ROI structures from disk 
% loadBackSubROIs(objarray)

for oidx = 1:length(objarray)
   filename = [objarray(oidx).DateStr objarray(oidx).TimeStr 'ObjBackSubROIs.mat'];
   folder = [objarray(oidx).Folder];  
   if exist(fullfile(folder,filename),'file')
   load( fullfile(folder,filename), 'ROI' );
   objarray(oidx).ROI = ROI;
   end
end
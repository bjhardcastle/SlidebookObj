function getTifRegPath(obj)
% With the naming convention used by ca_RegSeries.. we can guess what the
% associated _reg.tif file should be called (regardless of tiff ending .tif
% or .tiff). If the registered tiff file doesn't already exist, it will be
% given this name if ca_Reg.. is run. 
% If TiffFile doesn't exist, the original tiff file used to load the object
% was already registered.

if ~isempty(obj.TiffFile)
    obj.TifRegFile = [obj.TiffFile(1:end-4) '_reg.tif'];
end

if isempty(obj.TiffFile) && ~isempty(obj.TifRegFile)
    tiffTry = [obj.File '.tiff'];
    if exist(fullfile(obj.Folder, tiffTry),'file')
        obj.TiffFile = tiffTry;
    end 
    
    tiffTry = [obj.File '.tif'];
    if exist(fullfile(obj.Folder, tiffTry),'file')
        obj.TiffFile = tiffTry;
    end 
    
end
function obj = getTiffPath(obj,pathIN)
% Extracts file name, extension, and folder path on object construction
if isa(pathIN,'char')
    
    tifPath = [pathIN];
    
    % Cut extension from file path
    tifExpr = '.*?(?=\.?_reg.tif\>|.tiff?\>)';
    PathExtCut = char(regexpi(tifPath,tifExpr,'match','once'));
    fileExpr = '\\';
    fileChar = cellstr(char(regexpi(PathExtCut,fileExpr,'split')));
    
    % Save filename (no extension) and folder path
    obj.File = fileChar{end,:};
    obj.Folder = [ fileparts(tifPath) '\' ];
    
    % Depending on whether file is registered or not
    pathExpr = '(\.?_reg.tif\>|.tiff?\>)';
    PathExt = char(regexpi(tifPath,pathExpr,'match'));
    % .. add .tiff or reg.tif path to object:
    if strcmp(PathExt,'_reg.tif') || strcmp(PathExt,'._reg.tif')
        obj.TifRegFile = [obj.File PathExt];
    else
        obj.TiffFile = [obj.File PathExt];
    end
else
    
    error('Please input path to tiff file as a string, or leave empty')
    
end
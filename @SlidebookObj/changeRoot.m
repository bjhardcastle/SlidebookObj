function changeRoot(objarray,oldroot,newroot)
%CHANGEPATH Redefines the common root folder for an object's Tiff files 
% objarray = changePath(objarray,oldroot,newroot)
%
% Change part of an object's folder path, but keep the relative folder
% structure the same. For example, an object's Tiff files are stored in two
% folders:
%     C:\ben\experiments\T4T5\monday\ C:\ben\experiments\T4T5\tuesday\
% If the folder \T4T5\ is moved to another location, but an object was
% already made, we can update the paths in the object with this function.
% 
% Enter the part of the path which has changed as 'oldroot'. In this case:
% 'C:\ben\experiments\'
% 
% Enter the new root path as 'newroot': 'Y:\ben\2p_data\'
% 
% As long as the subfolder have the same organisation and relative path to
% the files after the 'root' is the same, we simply swap 'newroot' for
% 'oldroot' in the object.
%

assert(nargin == 3, 'Old root and new root must be specified as inputs: changeRoot(a,oldroot,newroot)')

assert(ischar(oldroot),'Input old root path as a string')

assert(ischar(newroot),'Input new root path as a string')

if ~strcmp(oldroot(end),'\')
    oldroot(end+1) = '\';
end
if ~strcmp(newroot(end),'\')
    newroot(end+1) = '\';
end

if exist(newroot) ~= 7
    disp('New root path does not yet exist. Changes were applied anyway.')
end

for oidx = 1:length(objarray)
    if isempty( strfind(objarray(oidx).Folder, oldroot) ) 
        disp (['Object(' num2str(oidx) ')''s path does not contain ' oldroot ])     
    else
        objarray(oidx).Folder = strrep(objarray(oidx).Folder, oldroot, newroot );
    end

end
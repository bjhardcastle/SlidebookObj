function varargout = sort(objarray,direction)
%SORT Sorts the objects in an object array into chronological order, first to last. 
% sort(objarray)
%
% Must be called as follows:  
%   objarray = sort(objarray)
% in order to overwrite the existing object array.
%
% If no dates/times are available because of a lack .log files, or if some
% are are missing, no sorting takes place. 
%
% 
assert(nargout==1, 'Output must be requested: a = sort(a)')

if nargin < 2 || isempty(direction)
	direction = 'ascend';
else
	assert((strcmp(direction,'ascend')||strcmp(direction,'descend')),'Enter direction as a string: either ''ascend'' (default) or ''descend''')
end

Dates = {objarray.DateStr};
Times = {objarray.TimeStr};

% Check DateStr and TimeStr exist for every object
if 0.5*( length(Dates) + length(Times) ) ~= length(objarray)
    disp('Some objects missing DateStr or TimeStr')
    disp('Objects were not sorted.')
    return
end

% Concat dates and times to give yymmddhhss
DateTimes = strcat( Dates(:) , Times(:) );
sortMe = str2double(DateTimes);
% Get correct chronological order
[~,Idx] = sort(sortMe,direction);

% Reorder object and output
varargout{1} = objarray(Idx);

if all(~diff(Idx,2))
    disp('Already sorted')
end


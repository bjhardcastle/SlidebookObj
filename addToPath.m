function addToPath()
%ADDTOPATH Adds folders required for SlidebookObj class to Matlab path
%  addToPath()
%
if exist(fullfile(cd,'@SlidebookObj'),'dir')
    addpath(cd);
    addpath(fullfile(cd,'additionalfuncs'));
    % addpath(fullfile(cd,'thirdpartyfuncs'));
    addpath(fullfile(cd,'icons'));

else
    disp('@SlidebookObj folder not found in current directory.')
    return
end

% Prompt before saving path permanently
disp('SlidebookObj class added to path temporarily.')
disp('Save path to make it available next time Matlab opens?')
response = '';
while ~( strcmpi(response,'y') || strcmpi(response,'n') )
    if ~isempty(response)
        disp('Please enter ''y'' or ''n'' to choose yes or no.')
    end
    [response] = input('[y/n]: ','s');
end

if strcmpi(response,'y')
    savepath
    disp('Path saved.')
else
    disp('Path not saved. Run ''addToPath'' to use SlidebookObj class again.')
end

function addExportFigToolbar(fig)
%ADDEXPORTFIGTOOLBAR Add a toolbar with shortcuts for exporting a figure in
%different formats
%                                                                  BJH 2017
%
% If no input argument is provided just use the current figure
if nargin<1 || isempty(fig)
    fig = gcf;
end

% Check whether this function has already created a toolbar in this figure
for idx = 0:length(fig.Children)
    if idx
        if strcmp(fig.Children(idx).Tag, 'exportFigToolbar')
            % Toolbar already exists so don't draw another
            return
        end
    end
end

% Create toolbar with an identifying tag
tbar = uitoolbar(fig,'Tag','exportFigToolbar');

% Fetch a built-in save file icon (blue):
try
    saveimg = im2uint8(imread(fullfile(matlabroot,'toolbox/matlab/icons/file_save.png'),'png','BackgroundColor' ,'none'));
catch
    % If it's not available just make a soild blue square instead
    saveimg = cat(3,0.2.*ones(16,16),0.2.*ones(16,16),ones(16,16));
end

% Make some colorized icons:
iconBlue = cat(3,saveimg(:,:,2), saveimg(:,:,1), saveimg(:,:,3));
iconRed = cat(3,saveimg(:,:,3), saveimg(:,:,2), saveimg(:,:,1));
iconGreen = cat(3,saveimg(:,:,1), saveimg(:,:,3), saveimg(:,:,2));
iconYellow = cat(3,saveimg(:,:,3), saveimg(:,:,3), saveimg(:,:,2));

% Add toggle buttons to toolbar for saving to each format
% Note: Tag should be file extension w/out leading "." -
% it can contain number identifiers though (png1, png2, etc.) which will be
% stripped later
%png
png_button = uitoggletool(tbar, ...
    'CData', iconRed, ...
    'TooltipString', 'Export .png', ...
    'Tag', 'png1' ); %file extension w/optional number
%svg
svg_button = uitoggletool(tbar, ...
    'CData', iconGreen, ...
    'TooltipString', 'Export .svg', ...
    'Tag', 'svg1' ); %file extension w/optional number
%pdf
pdf_button = uitoggletool(tbar, ...
    'CData', iconBlue, ...
    'TooltipString', 'Export .pdf', ...
    'Tag', 'pdf1' ); %file extension w/optional number

%{
%eps
eps_button = uitoggletool(tbar, ...
    'CData', iconYellow, ...
    'TooltipString', 'Export .eps', ...
    'Tag', 'eps1' ); %file extension w/optional number
    %}
    
    % Set a common callback for all buttons (which is where customized
    % export settings should be added)
    set( [...
        png_button, ...
        svg_button, ...
        pdf_button ...
        ], ...
        'ClickedCallback', @(src, evt) buttonCallback(fig, src, evt),...
        'HandleVisibility', 'off', ...
        'Interruptible', 'off', ...
        'BusyAction', 'cancel' );
    
    % Assign buttons to gui's user data so we can retrieve it in callback function:
    udata.([png_button.Tag '_button']) = png_button;
    udata.([svg_button.Tag '_button']) = svg_button;
    udata.([pdf_button.Tag '_button']) = pdf_button;
    % udata.([eps_button.Tag 'button']) = eps_button;
    
    % Set the userdata
    set(fig, 'UserData', udata);
    
end

function buttonCallback(fig,src,~)
% Customize export settings for shortcuts

% Fetch figure user data
udata = get(fig,'UserData');

% Get save location (defaults to what should be a unique filename)
fileExt = src.Tag(isletter(src.Tag));
[filename, pathname] = uiputfile(['.',fileExt],'Save image as...', char(datetime('now','Format','yyMMddHHmmss')) );
assert(ischar(filename),'Bad filename type. Should be a string of characters')

% Get current figure color in case we change it:
originalColor = get(fig,'color');

% Apply some common settings for all formats:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(fig, 'InvertHardCopy', 'off'); % keeps fig/ax bkground colors on screen

switch src.Tag
    % Export with desired settings for each format
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 'png1'
        % Transparent background with export_fig:
        %{
        set(fig,'color','none');
        export_fig(fullSavePath , '-dpng','-r400','-q100','-opengl',gcf);
        %}
        print(fig, fullfile(pathname,filename) , '-dpng','-r400');
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 'svg1'
        d = msgbox('Hang on, this may take a minute..','Saving .svg','help');
        print(fig, fullfile(pathname,filename) , '-dsvg','-painters');
        close(d)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 'pdf1'
        d = msgbox('Hang on, this may take a minute..','Saving .pdf','help');
        % export_fig(fullSavePath , '-dpdf','-painters','-transparent',gcf);
        print(fig, fullfile(pathname,filename) , '-dpdf','-painters');
        close(d)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 'eps1'
        d = msgbox('Hang on, this may take a minute..','Saving eps','help');
        print(fig, fullfile(pathname,filename) , '-depsc','-painters');
        %epsclean(fullfile(pathname,filename));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% Reapply figure color in case it was removed
if exist('originalColor','var')
    set(fig,'color',originalColor);
end

% Reset button to be used again
udata.([src.Tag '_button']).State = 'off';

% Update figure user data
set(fig, 'UserData', udata);

end

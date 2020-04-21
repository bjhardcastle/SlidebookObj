function addExportFigToolbar(fig)
% Add a toolbar with shortcuts for common plot-related functions, such as
% exporting to .png or .svg via export_fig or plot2svg.
% Tool bar appears at the top of the specified figure 'fig'
if nargin<1 || isempty(fig)
    fig = gcf;
end
for idx = 0:length(fig.Children)
    if idx
        if strcmp(fig.Children(idx).Tag, 'export_fig')
            % Toolbar already exists: don't draw another 
           return
        end
    end
end
    
tbar = uitoolbar(fig,'Tag','export_fig');

% Add a button for saving to .png
saveimg = im2uint8(imread(fullfile(matlabroot,'toolbox/matlab/icons/file_save.png'),'png','BackgroundColor' ,'none'));
png_button = uitoggletool(tbar, ...
    'CData', cat(3,saveimg(:,:,3), saveimg(:,:,2), saveimg(:,:,1)), ... % Colorized red
    'TooltipString', 'Export .png', ...
    'HandleVisibility', 'off', ...
    'Interruptible', 'off', ...
    'BusyAction', 'cancel');

% Make a button for saving to .svg
svg_button = uitoggletool(tbar, ...
    'CData', cat(3,saveimg(:,:,1), saveimg(:,:,3), saveimg(:,:,2)), ... % colorized green
    'TooltipString', 'Export .svg', ...
    'HandleVisibility', 'off', ...
    'Interruptible', 'off', ...
    'BusyAction', 'cancel');

% % Make a button for saving to .eps
% eps_button = uitoggletool(tbar, ...
%     'CData', saveimg, ...
%     'TooltipString', 'Export .eps', ...
%     'HandleVisibility', 'off', ...
%     'Interruptible', 'off', ...
%     'BusyAction', 'cancel');

% Make a button for saving to .pdf
pdf_button = uitoggletool(tbar, ...
    'CData', cat(3,saveimg(:,:,2), saveimg(:,:,1), saveimg(:,:,3)), ... % colorized blue
    'TooltipString', 'Export .pdf', ...
    'HandleVisibility', 'off', ...
    'Interruptible', 'off', ...
    'BusyAction', 'cancel');

udata.png_button = png_button;
udata.svg_button = svg_button;
% udata.eps_button = eps_button;
udata.pdf_button = pdf_button;

set(fig, 'UserData', udata);


% Set callbacks
set(png_button, ...
    'ClickedCallback', @(src, evt) pngCallback(fig, src, evt));
set(svg_button, ...
    'ClickedCallback', @(src, evt) svgCallback(fig, src, evt));
% set(eps_button, ...
%     'ClickedCallback', @(src, evt) epsCallback(fig, src, evt));
set(pdf_button, ...
    'ClickedCallback', @(src, evt) pdfCallback(fig, src, evt));
end

function pngCallback(fig,~,~)
udata = get(fig,'UserData');

[filename, pathname] = uiputfile('.png','Save image as...', char(datetime('now','Format','yyMMddHHmmss')) );

if ischar( filename )
    
    % Old method using export_fig (started giving crap results)
    %     export_fig( fullfile(pathname,filename), ...
    %         '-png', '-m4', fig);

    % New method with built-in Matlab function
    set(fig, 'InvertHardCopy', 'on');
    print(fig, fullfile(pathname,filename) , '-dpng','-r400');

end

udata.png_button.State = 'off';
set(fig, 'UserData', udata);

end

function svgCallback(fig,~,~)
udata = get(fig,'UserData');

[filename, pathname] = uiputfile('.svg','Save image as...', char(datetime('now','Format','yyMMddHHmmss')) );
if ischar( filename )
    d = msgbox('Hang on, this may take a minute..','Saving .svg','help');
    set(fig, 'InvertHardCopy', 'off');
    print(fig, fullfile(pathname,filename) , '-dsvg','-painters');
    close(d)
end

udata.svg_button.State = 'off';
set(fig, 'UserData', udata);

end

function epsCallback(fig,~,~)
udata = get(fig,'UserData');

[filename, pathname] = uiputfile('.eps','Save image as...', char(datetime('now','Format','yyMMddHHmmss')) );
if ischar( filename )
    d = msgbox('Hang on, this may take a minute..','Saving .eps','help');
    set(fig, 'InvertHardCopy', 'off');
     print(fig, fullfile(pathname,filename) , '-depsc','-painters');
    epsclean(fullfile(pathname,filename));
    close(d)
end

udata.eps_button.State = 'off';
set(fig, 'UserData', udata);

end

function pdfCallback(fig,~,~)
udata = get(fig,'UserData');

[filename, pathname] = uiputfile('.pdf','Save image as...', char(datetime('now','Format','yyMMddHHmmss')) );
if ischar( filename )
    d = msgbox('Hang on, this may take a minute..','Saving .pdf','help');
    set(fig, 'InvertHardCopy', 'off');
    set(fig,'color','none');
    print(fig, fullfile(pathname,filename) , '-dpdf','-painters');
    close(d)
end

udata.pdf_button.State = 'off';
set(fig, 'UserData', udata);

end

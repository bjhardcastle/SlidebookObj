function varargout = findROIs(obj, numROIs, fields, detrend)
%FINDROIS Quick function to auto-find some number of ROIs and bring up a GUI to check them before adding to object
% 
% A function which has since been expanded and improved in other Slidebook object subclasses.
% 
%  numROIs - number of unique ROIs to find. The image background is often detected as one ROI (and is discarded) so number of ROIs returned may be fewer than this number
%  fields  - as per 'findTrials'. Specifying specific fields will create an activity frame from them, which will then be used as a guide for creating the ROIs 
%  detrend - detrends frames before running clustering (no longer used)

if nargin < 4
    detrend = 1;
end
if nargin < 2
    numROIs = 5;
end
if numROIs > 16
    numROIs = 16;
    disp('Using maximum numROIs: 16')
end
if isempty(obj.Frames)
    getFrames(obj)
end

% Get an activity frame. We'll use the intensities in this image to decide which pixels are likely the background or don't respond, so they can be ignored 
if nargin >=3 && ~isempty(fields)
    
    if isempty(obj.TrialPatNum)
        getParameters(obj);
    end
    f = getActivityFrame(obj,fields);
    
elseif ~isempty(obj.ActivityFrame)
    
    f = obj.ActivityFrame;
    
elseif isempty(obj.ActivityFrame) && ~isempty(obj.DaqFile)
    
    getActivityFrame(obj)
    f = obj.ActivityFrame;
    
else
    
    f = obj.AverageFrame;
    
end

% Keep pixels above the median intensity in the image. Find their location
[row2,col2] = find(f>-9999); % All pixels
[row1,col1] = find(f>median(f(:))); % Above threshold pixels
inds2 = sub2ind ( size(f), row2, col2 );
inds1 = sub2ind ( size(f), row1, col1 );
inds = setdiff(inds2,inds1);

% Detrend Frames:
if detrend
    detrendedFrames = detrendFrames(obj);
else
    detrendedFrames = obj.Frames;
end

% Get the 1D time-series of each included pixel
resp = reshape(detrendedFrames, length(f(:)),size(obj.Frames,3));
detrendedFrames = [];
kblank = zeros(size(resp,1),1);
resp = resp(inds1,:);

% Run kmeans on raw time-series
kidx = kmeans(resp,numROIs);
kblank(inds1) = kidx;

% Reshape vector into image array for displaying masks
k = reshape(kblank,size(f));



% Open up a figure to display some data from each cluster we find 
mFig = figure('Color',[0.5 0.5 0.5],'SizeChangedFcn',@resetAxes);
subplot(2,2,3)
avgAx = gca;
imagesc(f)
axis off

subplot(2,2,1)
maskAx = gca;
axis off
maskAx.Color = [0 0 0];

subplot(2,2,[2,4])
mAx = gca;
hold on


% Add listener to keep images at max size
% addlistener(mAx, 'Resize', @(obj,event)resetAxes(maskAx,avgAx));

% Now run through each cluster and keep if they have an average brightness above some brightness and are above some minimum size
ridx = 0;
u = unique(k);
r = zeros( size(f,1),size(f,2),length(u) );
masks = zeros( size(f,1),size(f,2));
masksbw = zeros( size(f,1),size(f,2));
maskscale = masksbw;
f=double(f);
for l = 1:length(u)
    rk_scale =  mean(mean(f(k==u(l))))./max(f(:));
    if rk_scale*max(f(:)) > mean(f(:)) +std(f(:))
        ridx = ridx+1;
        rk = k==u(l);
        col = ROIcolor(ridx);
        maskcol = cat(3,col(1)*rk,col(2)*rk,col(3)*rk);
        masks = masks + maskcol;
        masksbw = u(l).*rk + masksbw;
        maskscale = rk_scale.*rk + maskscale;
        r(:,:,ridx) = rk;
        plot(mAx,scanROI(obj,rk),'Color',col)
        hold on
    end
    
end
ylim = mAx.YLim(2);
if ~isempty(obj.TrialStartFrame)
    for t = 1:length(obj.TrialStartFrame)
        plotStimPatch(obj,mAx,[obj.TrialStartFrame(t) obj.TrialEndFrame(t)])
        xpos = obj.TrialStartFrame(t) + 0.5*(obj.TrialEndFrame(t) - obj.TrialStartFrame(t));
        if ~isempty(obj.TrialPatNum)
            text(mAx,xpos,ylim,[num2str(obj.TrialPatNum(t))],'HorizontalAlignment','center');
        end
    end
end

% Start interactive ROI assignment
roiIdx = 0;
addflag = 1;
addedmasks = zeros( size(f,1),size(f,2)); % store ROIs as they're added
autoROI = struct('mask',[],'color',[],'position',[]);
try
    while addflag == 1
        
        roiIdx = roiIdx + 1;
        
        continueflag = 1;
        while continueflag == 1
            
            %%% pick contiguous mask area as an ROI
            
            imshow(masks + cat(3,addedmasks*0.3,addedmasks*0.3,addedmasks*0.3) ,'Parent',maskAx)
            
            title(maskAx,'Select neighboring areas to join to make a single ROI, then press return');
            
            % Add any existing ROIs
            
            
            
            W = [];
            
            getptsflag = 1;
            while getptsflag == 1
                [x,y] = getpts(maskAx);
                
                
                
                % only accept if within bounds of image
                if any(any( [round(y) round(x)] > [size(f)] ))
                    h = warndlg('Select pixels within top-left image only.','Out of bounds') ;
                    uiwait(h)
                    continue
                end
                
                
                % only accept if within a non-zero area of masks ( above threshold, not background )
                % and only accept if not-previously selected for an ROI
                clear inds
                inds(:,1) = sub2ind( size(masks) , round(y), round(x) , 1*ones(length(x),1) );
                inds(:,2) = sub2ind( size(masks) , round(y), round(x) , 2*ones(length(x),1) );
                inds(:,3) = sub2ind( size(masks) , round(y), round(x) , 3*ones(length(x),1) );
                masksinds = masks(inds);
                maskInt = sum(masksinds,2);
                addInt = addedmasks(inds(:,1));
                if any( ~maskInt  ) || any( addInt )
                    
                    h = warndlg('Select colored areas only','Out of bounds') ;
                    uiwait(h)
                    continue
                end
                
                
                
                if ~isempty(x) && ~isempty(y)
                    getptsflag = 0;
                end
            end
            
            
            
            for pidx = 1:length(x)
                W(:,:,pidx) = grayconnected(masksbw,round(y(pidx)),round(x(pidx)));
            end
            
            mask = logical(sum(W,3));
            
            BW2 = imfill(mask,'holes');
            %%% Make ROI a bit smaller
            %     BW = bwmorph(bwconvhull(BW2), 'erode', 2);
            B = bwboundaries(BW2);
            
            cla(maskAx)
            
            currentMask = addedmasks + 2*BW2;
            imshowpair(currentMask,obj.AverageFrame,'Parent',maskAx)
            title(maskAx,'New ROI')
            
            if ~isempty(B)
                roix = [];
                roiy = [];
                for b = 1:length(B)
                    roix = [roix B{b}(:,2)'];
                    roiy = [roiy B{b}(:,1)'];
                end
                skipPts = 5;
                roiPos = [ roix([1:skipPts:end])' roiy([1:skipPts:end])'];
            end
            
            % Confirm ROI
            qstring = 'Happy with this ROI?';
            wintitle = 'Accept new ROI?';
            str2 = 'Choose again';
            str3 = 'Accept';
            str1 = 'Reject and finish';
            default = str3;
            button = questdlg(qstring,wintitle,str1,str2,str3,default);
            if strcmp(button,str3)
                continueflag = 0;
            elseif strcmp(button,str1)
                continueflag = 0;
                addflag = 0;
            end
            
            
        end
        
        if addflag
            % remove just-selected ROI from masks
            masks = masks.*~mask;
            masksbw = masksbw.*~mask;
            
            % and add it to the 'addedmasks'
            addedmasks = addedmasks + mask;
            
            [bw] = impoly(maskAx,roiPos);
            
            autoROI(roiIdx).mask = bw.createMask;
            autoROI(roiIdx).color = [1 1 1];
            autoROI(roiIdx).position = roiPos;
            
            
            % Confirm ROI
            qstring = 'Continue adding?';
            
            wintitle = 'Add more ROIs?';
            str1 = 'Finish';
            str2 = 'Add more';
            default = str2;
            button = questdlg(qstring,wintitle,str1,str2,default);
            if strcmp(button,str1)
                addflag = 0;
            end
            
        end
        
    end
    
catch
    disp('No ROIs added to object.')
end

if ~isempty( [autoROI.mask] )
    if nargout
        varargout{1} = autoROI;
    else
        
        % assign to object
        objROIidx = length(obj.ROI);
        if objROIidx == 0
            obj.ROI = struct('mask',[],'color',[],'position',[]);
        end
        for roiIdx = 1:length(autoROI)
            objROIidx = objROIidx + 1;
            obj.ROI(objROIidx) = autoROI(roiIdx);
            obj.ROI(objROIidx).color = ROIcolor(objROIidx);
            disp(['ROI assigned to object as ROI index ' ROIcolor(objROIidx,1) ])
        end
        
    end
end

delete(mFig)

end

function resetAxes(src,~)

for n = 1:length( src.Children )
    if  strcmp( src.Children(n).Visible, 'off' )
        g = src.Children(n);
        axis(g,'equal');
        g = [];
    end
end
end



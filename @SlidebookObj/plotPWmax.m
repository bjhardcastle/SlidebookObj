function [pwFig, pwAxes, pwMaxData] = plotPWmax(objarray, ROImaskidx, fields, before, after, pwFig)
%PLOTPWMAX Plot pairwise comparison of maximum response for two sets of trial parameters
% [pwFig, pwAxes, pwMaxData] = plotPWmax(objarray, ROImaskidx, fields, before, after, pwFig)
%
% Get a processed, nicely plot pairwise comparison easily. This function works in a
% similar way to 'findTrials' - see its documentation for help on
% specifying the 'fields', 'before' and 'after' input arguments. 
%
% This function relies on individual fly numbers (obj.Fly) - without these there is no information on which objects belong to which animal. 
% Individual fly means are plot in grey and connected across a before and after
% condition. If data doesn't exist for a particular fly for both conditions, it isn't added to
% the plot. 
% 
% The pairwise comparison of the mean of all flies is also added in black. 
% 
% This function accepts the following input:
%
%   objarray                          - [1xN] array of SlidebookObj objects
%
%   ROImaskidx                        - a single numerical value to specify
%                                       which ROI to use::
%                                       ' obj.ROI(ROImaskidx).mask '
%                                       will be scanned.
%
%   fields                            - use as described in 'findTrials'.
%                                       These are the parameters that both
%                                       datasets have in common.
%
%   before                            - A structure similar to fields,
%                                       specifying the parameters that
%                                       define the first dataset
%
%   after                             - A structure similar to fields,
%                                       specifying the parameters that
%                                       define the second dataset
%
%   pwFig                             - handle to figure to plot in
%
% See also findTrials


assert( nargin >= 5 , 'Please provide an ROI number and a fields structure as arguments.'  );

fcell = fieldnames(fields);
assert( ~isempty(fcell) , 'The input to the ''fields'' argument is empty.');
bcell = fieldnames(before);
assert( ~isempty(bcell) , 'The input to the ''before'' argument is empty.');
acell = fieldnames(after);
assert( ~isempty(acell) , 'The input to the ''after'' argument is empty.');

flynums = [objarray.Fly];
assert( ~isempty(flynums) && length(flynums) == length(objarray) , ...
    'Some obj.Fly numbers are missing: pairwise comparison relies on these' )

% Setup the figure for plotting traces:
if nargin == 6 && ishghandle(pwFig)
    set(pwFig, 'color', [1 1 1] )
    if isempty( pwFig.CurrentAxes )
        pwAxes = axes(pwFig);
    else
        pwAxes = pwFig.CurrentAxes;
    end
else
    % If pwFig doesn't exist, is invalid or has been deleted, make a new one,
    pwFig = figure('color',[1 1 1]);
    pwAxes = axes(pwFig);
end

% Add buttons for easy export
addExportFigToolbar(pwFig)

hold(pwAxes, 'on');


%Combine fields with before and after parameters
fields_Before = fields;
for bidx = 1:length(bcell)
    beforeVal{bidx,1} = before.( bcell{bidx} );
    fields_Before.( bcell{bidx} ) = beforeVal{bidx};
end
fields_After = fields;
for aidx = 1:length(acell)
    afterVal{aidx,1} = after.( acell{aidx} );
    fields_After.( acell{aidx} ) = afterVal{aidx};
end

% Get the intensity time-series for the requested BEFORE trials
[respArray_Before, ~ , F0Array_Before, ObjIdx_Before] = findRespArray(objarray, ROImaskidx, fields_Before);
% And the AFTER trials
[respArray_After, ~ , F0Array_After, ObjIdx_After] = findRespArray(objarray, ROImaskidx, fields_After);


if ~isempty(F0Array_Before) && ~isempty(F0Array_After)
    % Only start analysing if some trials and their F0 values were returned
    
    % Get the numbers of flies from which we obtained trials with matching
    % parameters (every fly should have before and after trials)
    % Convert ObjIndex for each trial into its corresponding Fly number
    beforeFlies = [objarray( ObjIdx_Before ).Fly];
    afterFlies = [objarray( ObjIdx_After ).Fly];
    
    if any (abs ( sort( unique(beforeFlies) ) - sort( unique(afterFlies) ) ) )
        % Some flies are missing a before or after condidion. We must discard
        % trials from that fly
        
        for nidx = unique( [beforeFlies afterFlies ] )
            
            if ~any( beforeFlies == nidx)
                % No trials from this fly num in Before group
                
                % Delete trials in After group
                deleteIdx = find( afterFlies == nidx );
                
                afterFlies( deleteIdx ) = [];
                ObjIdx_After( deleteIdx ) = [];
                respArray_After( deleteIdx, : ) = [];
                F0Array_After( deleteIdx ) = [];
                
            elseif ~any( afterFlies == nidx )
                % No trials from this fly num in After group
                
                % Delete trials in Before group
                deleteIdx = find( beforeFlies == nidx );
                
                beforeFlies( deleteIdx ) = [];
                ObjIdx_Before( deleteIdx ) = [];
                respArray_Before( deleteIdx, :  ) = [];
                F0Array_Before( deleteIdx ) = [];
                
            end
            
        end
        
    end
    assert( isequal( sort( unique(beforeFlies) ), sort( unique(afterFlies) ) ), ...
        'Still some flies which are only in Before or After group' )
    
    % Now we have equal groups, find the mean response for each fly,
    % for before and after:
    flies = sort( unique(beforeFlies) );
    
    % Normalize trial data to get dF/F0
    dFtrials_Before = respArray_Before ./ F0Array_Before - 1 ;
    dFtrials_After = respArray_After ./ F0Array_After - 1 ;
    
    % Make NaN array into which maximum for each fly will be stored:
    beforeMax = nan(1, length(flies) );
    afterMax = nan(1, length(flies) );
    
    pwMax = {};
    for fidx = 1:length(flies)
        % Find matching trials ([Nx1] logic array of hits)
        bHits = find( beforeFlies == flies(fidx) )' ;
        aHits = find( afterFlies == flies(fidx) )';
        
        % Find the mean response of these trials
        beforeMean = nanmean( dFtrials_Before( bHits,:) , 1 );
        afterMean = nanmean( dFtrials_After( aHits,:) , 1 );
        
        % Find the maximum value in the mean response
        % - IMPROVE with time bounds to give max while stim ON
        beforeMax(fidx) = nanmax(beforeMean);
        afterMax(fidx) = nanmax(afterMean);
        
        pwMaxData(fidx).before = beforeMax(fidx);
        pwMaxData(fidx).after = afterMax(fidx);
		pwMaxData(fidx).fly = flies(fidx);
        
    end
    
    % Now begin plotting
    ncol(1,:) = [0,0,0];
    ncol(2,:) = 0.5*[1,1,1];
    % boxplot([r_norms,t_norms],'Labels',{'Rotation','Translation'},...
    %     'colors','k')
    
    h(1)=plot(ones(size(beforeMax)),beforeMax,'o');
    h(2)=plot(2*ones(size(afterMax)),afterMax,'o');
    set(h,'Color',ncol(2,:),'MarkerFaceColor',ncol(2,:),'Markersize',3);
    for lineIdx = 1:length(beforeMax)
        plot([1,2],[beforeMax(lineIdx),afterMax(lineIdx)],'Color',ncol(2,:))
    end
    
    plot([1,2],[nanmean(beforeMax),nanmean(afterMax)],'ko','MarkerFaceColor','k','Markersize',5)
    plot([1,2],[nanmean(beforeMax),nanmean(afterMax)],'k','LineWidth',1.5)
    
    cohens_d = nanmean( afterMax - beforeMax ) / nanstd( afterMax - beforeMax );
    
    pwAxes.FontSize = 14;
    pwAxes.LineWidth = 1;
    
    %             axis tight
    
    % Add Cohen's d value
    % text(2,3,[num2str(round(cohens_d,1))]);
    
    
    offsetAxesXoff(pwAxes);
    offsetAxesXoff(pwAxes);
    offsetAxesXoff(pwAxes);
    
    ylabel('Max \Delta F/F');
    
    % Create multi-line x-labels with fields parameters and
    % values: fields.param1 = x
    
    if isempty( [ setdiff(acell,bcell), setdiff(bcell,acell) ])
        % If before/after fields compared are the same then
        % put fields in the same order (alphabetically)
        [bcell, bix] = sort(bcell);
        beforeVal = beforeVal(bix);
        [acell, aix] = sort(acell);
        afterVal = afterVal(aix);
        
    else
        % Otherwise, find the fields which are dissimilar -
        % sort the rest and put these at the end
        [~,exclbIdx] = setdiff(bcell,acell);
        [~, bix] = sort(bcell);
        moveIdx = find(ismember(bix,exclbIdx));
        bmix = bix(moveIdx);
        bix(moveIdx) = [];
        bix = [bix; bmix];
        bcell = bcell(bix);
        beforeVal = beforeVal(bix);
        
        [~,exclaIdx] = setdiff(acell,bcell);
        [~, aix] = sort(acell);
        moveaIdx = find(ismember(aix,exclaIdx));
        amix = aix(moveaIdx);
        aix(moveaIdx) = [];
        aix = [aix; amix];
        acell = acell(aix);
        afterVal = afterVal(aix);
    end
    
    bvalcell = cellstr( cellfun(@(x) num2str(x), beforeVal ,'Un',0) );
    avalcell = cellstr( cellfun(@(x) num2str(x), afterVal ,'Un',0) );
    % Cat label names with = and value, and %, which will
    % be a new line
    bstr1 = cellfun(@(x,y) strcat(x,{' = '},y,{'%'}), bcell, bvalcell ,'UniformOutput',true);
    astr1 = cellfun(@(x,y) strcat(x,{' = '},y,{'%'}), acell, avalcell ,'UniformOutput',true);
    bstr2  = [bstr1{:}];
    astr2  = [astr1{:}];
    % Get rid of last %:
    bstr = bstr2(1:end-1);
    astr = astr2(1:end-1);
    labels = {bstr, astr};
    labels = cellfun(@(x) strrep(x,'%','\newline'), labels,'UniformOutput',false);
    
    % Apply to axes:
    pwAxes.XTick = [1,2];
    pwAxes.XTickLabel = labels;
    pwAxes.XAxis.FontSize = 8;
    pwAxes.XTickLabelRotation = 30;
    
    % Increase length of x/yticks
    pwAxes.XAxis.TickLength =  2*pwAxes.XAxis.TickLength;
    pwAxes.YAxis.TickLength = 2*pwAxes.YAxis.TickLength;
    
    pwAxes.Color = pwFig.Color;
    % Turn off x axis ruler and ticks, but keep labels
    % pwAxes.XAxis.TickLength = [0 0];
    
    
    
end
end


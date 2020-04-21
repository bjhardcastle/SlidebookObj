function assignPatternActivityFrames(objarray)
%ASSIGNPATTERNACTIVITYFRAMES Make average activity images for all patterns used and make available in 'play' GUI
% assignPatternActivityFrames(objarray)
%
% A basic function for making an average activity image for all the patterns run during an experiment.
% For each pattern number found on the DAQ, 'getActivityFrame' is run, which finds all frames 
% captured during trials which used that pattern. The resulting average intensity image is 
% then assigned to the object in a property which can be found by the 'play' GUI upon opening, 
% then becomes available with a toggle button to overlay on the playback frames, to be used 
% for drawing ROIs etc. 
%
% See getActivityFrame.
%
for oidx = 1:length(objarray)
    if isempty(objarray(oidx).TrialPatNum)
        getParameters(objarray(oidx))
    end
    
	% fetch all tiff frames 
	clearFrames = 0;
    if isempty(objarray(oidx).Frames)
		clearFrames = 1;
        getFrames(objarray(oidx))
    end
    
	% find all pattern numbers available in the experiment
    patnum = unique([objarray(oidx).TrialPatNum]);
    
	% warn if we won't be able to store activity frames for all (25 limit is arbitrary - just write in 'ActivityFrame26' etc. as a property in SlidebookObj if more are needed)
    if length(patnum)>25
        disp(['Number of Patterns used is ' num2str(length(patnum)) '. Only room for 25 activity frames.'])
    end
    
            
	% create each pattern's activity frame and store as 'ActivityFrameN'
    frameName = 'ActivityFrame';
	for pidx = 1:length(patnum)
        if pidx > 25
            break
        end
        fields = [];
        fields.TrialPatNum = patnum(pidx);
        objarray(oidx).([frameName num2str(patnum(pidx))]) = getActivityFrame(objarray(oidx),fields);

    end
    
	% clear up if we fetched all tiff frames
	if clearFrames
		objarray(oidx).Frames = [];
	end
end
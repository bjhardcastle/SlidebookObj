function updateROIs(objarray)
%UPDATEROIS Update the fixed response stored for each ROI 

for oidx = 1:length(objarray)
    
	if isempty(objarray(oidx).Frames)
		% Get object's frames 
		getFrames(objarray(oidx)) % Careful of the setting objarray(oidx).UseBackSubFrames   
		CLEAR_FRAMES_FLAG = 1;
	else 
		CLEAR_FRAMES_FLAG = 0;
	end
   
   % Store the current setting for using fixed resp, as we will have to
   % turn it off temporarily
   FIXED_RESP_FLAG = objarray(oidx).UseFixedResp;
   
   objarray(oidx).UseFixedResp = 0;
   
    for ridx = 1:length(objarray(oidx).ROI)
       scanROI(objarray(oidx),objarray(oidx).ROI(ridx).mask);
    end
    
    % Restore fixed resp setting 
    objarray(oidx).UseFixedResp = FIXED_RESP_FLAG;
    
	if CLEAR_FRAMES_FLAG
		% Clear frames from memory
		objarray(oidx).Frames = [];
	end
end
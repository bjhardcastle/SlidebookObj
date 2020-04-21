function [detrendedFrames] = detrendFrames(obj)
if isempty(obj.Frames)
    if ~obj.Unattended 
        undoflag = 1;
    else
        undoflag = 0;
    end
    obj.Unattended = 1;
    disp('Fetching frames')
    getFrames(obj);
    if undoflag
        obj.Unattended = 0;
    end
end

% Detrend Frames:
resp = reshape(obj.Frames, size(obj.Frames,1)*size(obj.Frames,2) ,size(obj.Frames,3));
respDetrended = detrend(resp');
respDetrended(respDetrended < 0 ) = 0;
detrendedFrames = reshape(respDetrended',size(obj.Frames,1),size(obj.Frames,2),size(obj.Frames,3));
    
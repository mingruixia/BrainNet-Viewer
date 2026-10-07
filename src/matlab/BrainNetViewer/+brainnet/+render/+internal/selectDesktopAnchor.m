function point=selectDesktopAnchor(framePoint,pointer,monitors)
%SELECTDESKTOPANCHOR Prefer a valid active desktop location, with DPI fallback.
point=framePoint;
if ~isnumeric(pointer) || numel(pointer)~=2 || ~all(isfinite(pointer))
    return;
end
pointer=double(pointer(:).');
pointerMonitor=monitorFor(pointer,monitors);
frameMonitor=monitorFor(framePoint,monitors);
if ~isempty(pointerMonitor) && (isempty(frameMonitor) || ...
        (frameMonitor==1 && pointerMonitor>1))
    point=pointer;
end
end

function index=monitorFor(point,monitors)
index=[];
if ~isnumeric(point) || numel(point)~=2 || ~all(isfinite(point))
    return;
end
point=double(point(:).');
index=find(point(1)>=monitors(:,1) & point(1)<monitors(:,1)+monitors(:,3) & ...
    point(2)>=monitors(:,2) & point(2)<monitors(:,2)+monitors(:,4),1);
end

function updateNodeLabels(a)
%UPDATENODELABELS Refresh lightweight text anchors after native camera changes.
if ~isgraphics(a) || ~isappdata(a,'brainnet_label_layout'), return; end
data=getappdata(a,'brainnet_label_layout');
if isempty(data.handles) || any(~isgraphics(data.handles)), return; end
camera=a.CameraPosition; target=a.CameraTarget; up=a.CameraUpVector;
direction=camera-target;
if norm(direction)<=eps || norm(cross(up,direction))<=eps, return; end
[positions,applied]=brainnet.render.internal.nodeLabelPositions(data.coordinates,data.radii, ...
    data.low,data.high,camera,target,up,a.Projection,data.front);
for index=1:numel(data.handles), data.handles(index).Position=positions(index,:); end
setappdata(a,'brainnet_labels_front_applied',applied);
brainnet.render.internal.boundNodeLabels(a);
end

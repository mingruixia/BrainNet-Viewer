function [positions, frontApplied] = nodeLabelPositions(coordinates,radii,low,high,camera,target,up,projection,front)
%NODELABELPOSITIONS Camera-relative label anchors without changing scientific data.
direction=camera-target; direction=direction/norm(direction);
up=up-dot(up,direction)*direction; up=up/norm(up);
positions=coordinates+(radii(:)+1).*up;
frontApplied=false;
if ~front || isempty(positions), return; end
% Support of the geometry bounding box along the viewing direction.
corner=low; corner(direction>=0)=high(direction>=0);
depth=dot(corner,direction); cameraDepth=dot(camera,direction);
gap=cameraDepth-depth;
% An inside-geometry camera has no valid plane between the viewer and all geometry.
if gap<=eps(max(1,abs(cameraDepth))), return; end
plane=depth+min(max(1,norm(high-low)*.01),gap/2);
if string(projection)=="perspective"
    rays=positions-camera; denominators=rays*direction.';
    if any(denominators>=-eps), return; end
    positions=camera+rays.*((plane-cameraDepth)./denominators);
else
    positions=positions+(plane-positions*direction.').*direction;
end
frontApplied=true;
end

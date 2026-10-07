function boundNodeLabels(a)
%BOUNDNODELABELS Hide complete glyph boxes that would leave this pane.
if ~isgraphics(a) || ~isappdata(a,'brainnet_label_layout'), return; end
data=getappdata(a,'brainnet_label_layout'); pixel=getpixelposition(a);
if isempty(data.handles) || any(~isgraphics(data.handles)) || any(pixel(3:4)<=4), return; end
direction=a.CameraPosition-a.CameraTarget; distance=norm(direction);
if distance<=eps, return; end
direction=direction/distance; right=cross(a.CameraUpVector,direction); right=right/norm(right); up=cross(direction,right);
hidden=0;
for label=reshape(data.handles,1,[])
    position=label.Position; units=label.Units;
    % Measure rendered glyph dimensions, not string length; retain the 3-D anchor.
    label.Units='pixels'; extent=label.Extent; label.Units=units; label.Position=position;
    offset=position-a.CameraTarget; depth=distance;
    if strcmp(a.Projection,'perspective'), depth=dot(a.CameraPosition-position,direction); end
    halfHeight=depth*tand(a.CameraViewAngle/2)/min(1,pixel(3)/pixel(4));
    center=[.5+.5*dot(offset,right)/(halfHeight*pixel(3)/pixel(4)), ...
        .5+.5*dot(offset,up)/halfHeight].*pixel(3:4);
    % Renderer-owned labels have center/bottom alignment and zero text rotation.
    low=center-[extent(3)/2 0]; high=low+extent(3:4);
    inside=depth>0 && all(isfinite([low high])) && all(low>=2) && all(high<=pixel(3:4)-2);
    label.Visible=inside; hidden=hidden+double(~inside);
end
setappdata(a,'brainnet_label_boundary_hidden',hidden);
end

function point = figureAnchorPoint(source)
%FIGUREANCHORPOINT Return the center of a live parent figure in screen pixels.

point = [NaN NaN];
if isempty(source) || ~isgraphics(source)
    return;
end
if isgraphics(source, 'figure')
    figureHandle = source;
else
    figureHandle = ancestor(source, 'figure');
end
if isempty(figureHandle) || ~isgraphics(figureHandle)
    return;
end
position = figureHandle.Position;
if numel(position) == 4 && all(isfinite(position))
    point = position(1:2) + position(3:4) / 2;
end
end

function colors = brainMapColormap(count)
%BRAINMAPCOLORMAP Green-to-red map for nonnegative anatomical labels.

arguments
    count (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(count, 2)} = 256
end

anchors = [0.10 0.62 0.28; 0.70 0.88 0.18; 1.00 0.88 0.05; ...
    1.00 0.42 0.02; 0.72 0.00 0.00];
source = linspace(0, 1, size(anchors, 1));
target = linspace(0, 1, count);
colors = interp1(source, anchors, target, 'linear');
end

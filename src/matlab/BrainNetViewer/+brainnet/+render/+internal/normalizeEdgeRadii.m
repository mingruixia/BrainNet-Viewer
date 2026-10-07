function radii = normalizeEdgeRadii(values, valueMode)
%NORMALIZEEDGERADII Reproduce the legacy weighted-edge normalization.

arguments
    values double
    valueMode (1,1) string {mustBeMember(valueMode,["signed","absolute"])} = "absolute"
end

radii = double(values(:));
if valueMode=="absolute", radii=abs(radii); end
if isempty(radii)
    return;
end
if ~isreal(radii) || any(~isfinite(radii))
    error('BNV:Render:InvalidEdgeValues', 'Edge values must be finite.');
end
if max(radii) ~= min(radii)
    scale = 5.6 / (max(radii) - min(radii));
    if ~isfinite(max(radii)-min(radii)) || ~isfinite(scale)
        error('BNV:Render:InvalidEdgeValues','Edge normalization overflowed; rescale input values.');
    end
    offset = 6 - scale * max(radii);
    radii = radii * scale + offset;
else
    radii(:) = 2;
end
if any(~isfinite(radii))
    error('BNV:Render:InvalidEdgeValues','Edge normalization overflowed; rescale input values.');
end
end

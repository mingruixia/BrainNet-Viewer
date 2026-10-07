function radii = normalizeNodeRadii(values)
%NORMALIZENODERADII Reproduce the legacy node-size normalization.

arguments
    values double
end

radii = double(values(:));
if isempty(radii)
    return;
end
if any(~isfinite(radii))
    error('BNV:Render:InvalidNodeSizes', 'Node sizes must be finite.');
end
if min(radii) < 0
    radii = radii - min(radii);
end
if min(radii) < 1
    radii = radii + 1;
end
if any(~isfinite(radii))
    error('BNV:Render:InvalidNodeSizes','Node size normalization overflowed; rescale the input values.');
end
while max(radii) / min(radii) > 10
    radii = log(radii);
    if min(radii) < 1
        radii = radii + 1;
    end
end
if max(radii) ~= min(radii)
    scale = 5 / (max(radii) - min(radii));
    offset = 7 - scale * max(radii);
    radii = radii * scale + offset;
else
    radii(:) = 4;
end
end

function radii = nodeRadii(values, settings)
%NODERADII Node radii in coordinate units; legacy order, without edge changes.
values=double(values(:));
if any(~isfinite(values)) || ~isreal(values)
    error('BNV:Render:InvalidNodeSizes','Node size values must be real and finite.');
end
switch string(settings.size_mode)
    case "uniform"
        radii=repmat(settings.size,size(values));
    case "raw"
        radii=values;
    case "mapped"
        radii=brainnet.render.internal.normalizeNodeRadii(values);
    case "threshold"
        if string(settings.size_threshold_basis)=="mapped"
            radii=brainnet.render.internal.normalizeNodeRadii(values);
        else
            radii=values;
        end
        radii(radii<settings.size_threshold)=1;
    otherwise
        error('BNV:Render:InvalidNodeSizeMode','Unsupported node size mode.');
end
radii=radii*settings.size_scale;
if any(~isfinite(radii) | radii<0)
    error('BNV:Render:InvalidNodeRadii', ...
        'Final node radii must be finite and nonnegative. Review Raw values, threshold and scale.');
end
end

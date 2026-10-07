function radii = edgeRadii(values, settings)
%EDGERADII Legacy edge-radius order, independent of selection/color signs.
values=double(values(:));
if ~isreal(values) || any(~isfinite(values))
    error('BNV:Render:InvalidEdgeValues','Edge size values must be real and finite.');
end
if string(settings.size_value_mode)=="absolute", values=abs(values); end
switch string(settings.size_mode)
    case "uniform"
        radii=repmat(settings.size,size(values));
    case "mapped"
        radii=brainnet.render.internal.normalizeEdgeRadii(values,"signed");
    case "raw"
        radii=min(max(values,.2),6);
    case "threshold"
        keep=values>=settings.size_threshold;
        if string(settings.size_threshold_basis)=="mapped"
            radii=repmat(.4,size(values));
            radii(keep)=brainnet.render.internal.normalizeEdgeRadii(values(keep),"signed");
        else
            radii=values;
            radii(~keep)=.4;
            radii=min(radii,6);
        end
    otherwise
        error('BNV:Render:InvalidEdgeSizeMode','Unsupported edge size mode.');
end
radii=radii*settings.size_scale;
if any(~isfinite(radii) | radii<0)
    error('BNV:Render:InvalidEdgeRadii', ...
        'Final edge radii must be finite and nonnegative. Review Signed Raw threshold values and scale.');
end
end

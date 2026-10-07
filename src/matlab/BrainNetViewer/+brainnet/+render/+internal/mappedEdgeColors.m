function colors=mappedEdgeColors(values,settings)
%MAPPEDEDGECOLORS Legacy 64-bin mapping after independent sign handling.
values=double(values(:));
if ~isreal(values) || any(~isfinite(values))
    error('BNV:EdgeColor:InvalidValues','Mapped edge weights must be real and finite.');
end
if isempty(values), colors=zeros(0,3); return; end
if string(settings.mapped_value_mode)=="absolute", values=abs(values); end
limits=settings.color_limits;
if isempty(limits), limits=[min(values) max(values)]; end
if ~isreal(limits) || numel(limits)~=2 || any(~isfinite(limits)) || limits(1)>limits(2)
    error('BNV:EdgeColor:InvalidRange','Edge color limits must be finite and ordered.');
end
if limits(1)==limits(2)
    indices=repmat(64,size(values));
else
    k=63/(limits(2)-limits(1)); b=64-k*limits(2);
    bounded=min(max(values,limits(1)),limits(2));
    indices=round(bounded*k+b);
    if ~isfinite(limits(2)-limits(1)) || ~isfinite(k) || ~isfinite(b) || any(~isfinite(indices))
        error('BNV:EdgeColor:InvalidRange','Edge color mapping overflowed; rescale weights and limits.');
    end
    indices=min(max(indices,1),64);
end
map=brainnet.core.Colormap.sample(settings.colormap,64);
colors=map(indices,:);
end

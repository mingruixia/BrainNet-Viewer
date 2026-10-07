function alpha=edgeOpacity(values,settings)
%EDGEOPACITY Independent signed/absolute opacity; constants use upper alpha.
values=double(values(:));
if ~isreal(values) || any(~isfinite(values))
    error('BNV:EdgeOpacity:InvalidValues','Edge opacity weights must be real and finite.');
end
if isempty(values), alpha=zeros(0,1); return; end
if string(settings.opacity_mode)=="uniform"
    alpha=repmat(settings.opacity,size(values)); return;
end
if string(settings.opacity_value_mode)=="absolute", values=abs(values); end
low=settings.opacity_range(1); high=settings.opacity_range(2);
span=max(values)-min(values);
if ~isfinite(span)
    error('BNV:EdgeOpacity:Overflow','Edge opacity weight range overflowed; rescale input weights.');
end
if span==0
    alpha=repmat(high,size(values));
else
    alpha=low+(values-min(values))/span*(high-low);
    alpha=min(max(alpha,low),high);
end
end

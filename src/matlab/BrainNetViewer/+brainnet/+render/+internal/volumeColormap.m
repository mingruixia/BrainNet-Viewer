function [map, limits] = volumeColormap(values, settings)
%VOLUMECOLORMAP Split one palette at its midpoint for signed values.
values=double(values(isfinite(values)));
base=brainnet.core.Colormap.sample(settings.colormap,256);
negativeHalf=base(1:128,:);
positiveHalf=base(129:256,:);
if isempty(values), limits=[0 1]; else, limits=[min(values) max(values)]; end
if ~isempty(settings.negative_minimum), limits(1)=settings.negative_minimum; end
if ~isempty(settings.positive_maximum), limits(2)=settings.positive_maximum; end
if limits(2)<=limits(1), limits(2)=limits(1)+1; end
mode=string(settings.display_mode);
if mode=="positive"
    limits=[0 1]; positive=values(values>0);
    if ~isempty(positive), limits(2)=max(positive); end
    if ~isempty(settings.positive_minimum), limits(1)=settings.positive_minimum; end
    if ~isempty(settings.positive_maximum), limits(2)=settings.positive_maximum; end
    if limits(2)<=limits(1), limits(2)=limits(1)+1; end
    map=brainnet.core.Colormap.sample(positiveHalf,256);
    if settings.adjust_null, map(1,:)=settings.null_color; end
    return;
elseif mode=="negative"
    limits=[-1 0]; negative=values(values<0);
    if ~isempty(negative), limits(1)=min(negative); end
    if ~isempty(settings.negative_minimum), limits(1)=settings.negative_minimum; end
    if ~isempty(settings.negative_maximum), limits(2)=settings.negative_maximum; end
    if limits(2)<=limits(1), limits(2)=limits(1)+1; end
    map=brainnet.core.Colormap.sample(negativeHalf,256);
    if settings.adjust_null, map(end,:)=settings.null_color; end
    return;
end
% A single linear MATLAB color axis can split a diverging palette by sign
% only when zero is the axis midpoint. Preserve raw vertex values and use
% symmetric limits; otherwise small positive values could appear blue.
if limits(1)<0 || limits(2)>0
    extent=max(abs(limits));
    limits=[-extent extent];
end
if ~settings.adjust_null
    map=base;
    return;
end
negativeMaximum=0; positiveMinimum=0;
if ~isempty(settings.negative_maximum), negativeMaximum=settings.negative_maximum; end
if ~isempty(settings.positive_minimum), positiveMinimum=settings.positive_minimum; end
samples=linspace(limits(1),limits(2),256).';
map=repmat(settings.null_color,numel(samples),1);
negative=samples<negativeMaximum;
if any(negative)
    indices=1+round(127*(samples(negative)-limits(1))/ ...
        max(negativeMaximum-limits(1),eps));
    indices=min(max(indices,1),128);
    map(negative,:)=negativeHalf(indices,:);
end
positive=samples>positiveMinimum;
if any(positive)
    indices=1+round(127*(samples(positive)-positiveMinimum)/ ...
        max(limits(2)-positiveMinimum,eps));
    indices=min(max(indices,1),128);
    map(positive,:)=positiveHalf(indices,:);
end
% Reserve both central bins so exact zero uses the surface color.
map(128:129,:)=repmat(settings.null_color,2,1);
end

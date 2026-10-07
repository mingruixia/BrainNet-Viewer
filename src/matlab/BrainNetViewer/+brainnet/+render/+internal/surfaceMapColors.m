function [rgb, map] = surfaceMapColors(values, map, limits, surfaceColor)
%SURFACEMAPCOLORS Zero/missing scalars retain the original surface color.
values=values(:);
count=size(map,1);
span=limits(2)-limits(1);
indices=floor(count*(values-limits(1))/span)+1;
indices(~isfinite(indices))=1;
indices=max(1,min(count,indices));
rgb=map(indices,:);
null=values==0 | isnan(values);
rgb(null,:)=repmat(surfaceColor,nnz(null),1);
if limits(1)<=0 && limits(2)>=0
    zeroIndex=max(1,min(count,floor(count*(0-limits(1))/span)+1));
    map(zeroIndex,:)=surfaceColor;
end
end

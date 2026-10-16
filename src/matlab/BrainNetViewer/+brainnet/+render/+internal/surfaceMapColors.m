function [rgb, map] = surfaceMapColors(values, map, limits, surfaceColor)
%SURFACEMAPCOLORS Zero/missing scalars retain the original surface color.
values=values(:);
count=size(map,1);
span=limits(2)-limits(1);
indices=floor(count*(values-limits(1))/span)+1;
indices(~isfinite(indices))=1;
indices=max(1,min(count,indices));
rgb=map(indices,:);
null=values==0 | ~isfinite(values);
rgb(null,:)=repmat(surfaceColor,nnz(null),1);
% Do not recolor a whole legend bin: it also represents nonzero values.
end

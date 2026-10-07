function colors=moduleEdgeColors(modules,pairs,settings,nodeColormap)
%MODULEEDGECOLORS Whole-node module ranks; explicit inter-module RGB, no sentinel.
if nargin<4, nodeColormap=settings.colormap; end
modules=double(modules(:));
if ~isreal(modules) || any(~isfinite(modules))
    error('BNV:EdgeModule:InvalidModules','Node module values must be real and finite.');
end
if isempty(pairs), colors=zeros(0,3); return; end
if ~isnumeric(pairs) || ~isreal(pairs) || size(pairs,2)~=2 || ...
        any(~isfinite(pairs) | pairs<1 | pairs>numel(modules) | pairs~=fix(pairs),'all')
    error('BNV:EdgeModule:InvalidPairs','Edge endpoints must be valid node indices.');
end
[labels,~,ranks]=unique(modules,'sorted');
if numel(labels)>20
    error('BNV:EdgeModule:TooManyModules','Node Module edge coloring supports up to 20 modules in this version.');
end
if isnumeric(nodeColormap)
    map=brainnet.core.Colormap.validate(nodeColormap);
    colorRanks=1+mod(ranks-1,size(map,1));
else
    map=brainnet.core.Colormap.sample(nodeColormap,max(2,numel(labels)));
    colorRanks=ranks;
end
same=modules(pairs(:,1))==modules(pairs(:,2));
colors=repmat(settings.inter_module_color,size(pairs,1),1);
colors(same,:)=map(colorRanks(pairs(same,1)),:);
end

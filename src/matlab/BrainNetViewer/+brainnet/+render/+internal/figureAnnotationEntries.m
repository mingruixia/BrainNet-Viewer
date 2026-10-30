function entries=figureAnnotationEntries(prepared,options)
%FIGUREANNOTATIONENTRIES Describe Node/Edge bars without touching geometry.
% Surface retains its own switch and bottom strip, as in Desktop/Web.
entries=struct('name',{},'map',{},'limits',{},'labels',{});
image=options.section('image');
if image.show_colorbar && prepared.NodeCount>0
node=options.section('node'); edge=options.section('edge');
switch string(node.color_mode)
    case "mapped"
        add('Node',brainnet.core.Colormap.sample(node.colormap,256), ...
            range(prepared.NodeModules,node.color_limits),strings(0,1));
    case {"modular","custom"}
        labels=unique(prepared.NodeModules,'sorted');
        add('Module',moduleMap(labels,node.colormap),[0 max(1,numel(labels)-1)],compose('%g',labels));
    case "threshold"
        add('Node',[node.color_low;node.color_high],[0 1], ...
            [string(sprintf('Module <= %g',node.color_threshold));string(sprintf('Module > %g',node.color_threshold))]);
end
if prepared.EdgeCount>0
switch string(edge.color_mode)
    case "mapped"
        values=prepared.EdgeValues;
        if string(edge.mapped_value_mode)=="absolute", values=abs(values); end
        [map,limits]=edgeRange(values,edge);
        add('Edge',map,limits,strings(0,1));
    case "threshold"
        basis='Value';if string(edge.threshold_value_mode)=="absolute",basis='Absolute value';end
        add('Edge',[edge.color_low;edge.color_high],[0 1], ...
            [string(sprintf('%s <= %g',basis,edge.color_threshold));string(sprintf('%s > %g',basis,edge.color_threshold))]);
    case "length"
        add('Edge',[edge.color_low;edge.color_high],[0 1], ...
            [string(sprintf('Length < %g',edge.length_threshold));string(sprintf('Length >= %g',edge.length_threshold))]);
    case "node-module"
        labels=unique(prepared.NodeModules,'sorted');
        add('Edge',[moduleMap(labels,node.colormap);edge.inter_module_color], ...
            [0 numel(labels)],[compose('Module %g',labels);"Between modules"]);
    case "custom"
        labels=edge.custom_color.indices(:);
        add('Edge',brainnet.core.CustomEdgeColors.palette(edge.colormap,numel(labels)), ...
            [0 max(1,numel(labels)-1)],compose('%g',labels));
end
end
end
roi=options.section('roi');
if roi.show_legend && ~isempty(prepared.RoiMeshes)
    meshes=prepared.RoiMeshes;
    add('ROI',vertcat(meshes.color),[0 max(1,numel(meshes)-1)],compose('ROI %g',[meshes.label].'));
end
    function add(name,map,limits,labels)
        entries(end+1)=struct('name',name,'map',map,'limits',limits,'labels',{string(labels(:))});
    end
end

function [map,limits]=edgeRange(values,settings)
map=brainnet.core.Colormap.sample(settings.colormap,64);
limits=settings.color_limits;
if isempty(limits),limits=[min(values) max(values)];end
if limits(1)==limits(2)
    % mappedEdgeColors assigns a degenerate domain to LUT entry 64.
    % Keep the value at the high endpoint; do not change Node's low-end rule.
    value=limits(1);step=max(1,eps(value));lower=value-step;
    if isfinite(lower)&&lower<value
        limits=[lower value];
    else
        % At -realmax no lower finite endpoint exists. A single-color scale
        % preserves the actual mapped color without an infinite axis range.
        limits=[value value+step];map=repmat(map(end,:),64,1);
    end
end
end

function limits=range(values,requested)
limits=requested;
if isempty(limits),limits=[min(values) max(values)];end
if limits(2)<=limits(1),limits(2)=limits(1)+1;end
end

function colors=moduleMap(labels,map)
if isnumeric(map)
    colors=map(1+mod((0:numel(labels)-1),size(map,1)),:);
else
    colors=brainnet.core.Colormap.sample(map,max(2,numel(labels)));
    colors=colors(1:numel(labels),:);
end
end

function packLegacyMontage(axesHandles, layout)
%PACKLEGACYMONTAGE Fit legacy view order into disjoint, tightly bounded panes.
% GenerateView8/6/4/4v/5 in legacy BrainNet.m define the composition.
% Their 4:3 reference canvas is retained, but negative/overlapping rectangles
% are replaced by projected geometry bounds at one common scientific scale.
if layout == 1, return; end
n = numel(axesHandles);
sizes = zeros(n,2);
for i = 1:n
    a = axesHandles(i);
    vertices = zeros(0,3);
    for p = reshape(findall(a,'Type','patch'),1,[])
        vertices = [vertices; double(p.Vertices)]; %#ok<AGROW>
    end
    if isempty(vertices), continue; end
    direction = a.CameraPosition-a.CameraTarget;
    direction = direction/norm(direction);
    right = cross(a.CameraUpVector,direction); right = right/norm(right);
    up = cross(direction,right);
    projected = vertices*[right.' up.'];
    sizes(i,:) = max(projected,[],1)-min(projected,[],1);
end
% Leave 8% framing space, consistently with CameraState.fit. Widths are
% expressed in the same normalized units as heights on the legacy 4:3 canvas.
sizes = 1.08*sizes;
sizes(:,1) = sizes(:,1)/(4/3);
sizes = max(sizes, max([sizes(:);1])*1e-6);
gap = 0.022;
margin = 0.025;
bottom = 0.065; % Keep the bottom strip available for the shared colourbar.
available = [1-2*margin 1-margin-bottom];

if (layout==2 && n==8) || layout==5
    if n==8
        columns = {[1 4 7],[2 5],[3 6 8]};
    else
        columns = {[1 4],2,[3 5]};
    end
    left = columns{1}; right = columns{3};
    % Symmetric columns and paired row sizes, even for asymmetric anatomy.
    sizes([left right],1) = max(sizes([left right],1));
    for row = 1:numel(left)
        pair = [left(row) right(row)];
        sizes(pair,2) = max(sizes(pair,2));
    end
    widths = cellfun(@(ids) max(sizes(ids,1)),columns);
    heights = cellfun(@(ids) sum(sizes(ids,2)),columns);
    gaps = cellfun(@(ids) numel(ids)-1,columns)*gap;
    scale = min([(available(1)-2*gap)/sum(widths), ...
        (available(2)-gaps)./heights]);
    totalWidth = scale*sum(widths)+2*gap;
    totalHeight = max(scale*heights+gaps);
    x = (1-totalWidth)/2;
    top = bottom+(available(2)+totalHeight)/2;
    for col = 1:3
        ids = columns{col};
        y = top;
        if layout==5 && col==2
            y = top-(totalHeight-scale*heights(col))/2;
        end
        for id = ids
            w = scale*widths(col); h = scale*sizes(id,2);
            axesHandles(id).Position = [x y-h w h];
            y = y-h-gap;
        end
        x = x+scale*widths(col)+gap;
    end
else
    if layout==2
        rows = [1 2 3;4 5 6];
    elseif layout==3
        rows = [1 2;3 4];
    else
        rows = [1 2;3 4;5 6];
    end
    widths = max(reshape(sizes(rows(:),1),size(rows)),[],1);
    heights = max(reshape(sizes(rows(:),2),size(rows)),[],2);
    [nr,nc] = size(rows);
    if nc==2, widths(:) = max(widths); end
    scale = min((available-[(nc-1)*gap (nr-1)*gap])./ ...
        [sum(widths) sum(heights)]);
    total = scale*[sum(widths) sum(heights)]+[(nc-1)*gap (nr-1)*gap];
    y = bottom+(available(2)+total(2))/2;
    for row = 1:nr
        x = (1-total(1))/2;
        for col = 1:nc
            w = scale*widths(col); h = scale*heights(row);
            axesHandles(rows(row,col)).Position = [x y-h w h];
            x = x+w+gap;
        end
        y = y-scale*heights(row)-gap;
    end
end
end

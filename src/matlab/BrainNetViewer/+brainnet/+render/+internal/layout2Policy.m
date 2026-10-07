function [policy, negative] = layout2Policy(prepared)
%LAYOUT2POLICY Conservative coordinate-partition check, not anatomy inference.
policy = struct('mode','six-full','reason','no-surface');
faces = prepared.SurfaceFaces;
negative = false(size(faces,1),1);
if isempty(faces), return; end
x = prepared.SurfaceCoordinates(1,:);
negative = mean(reshape(x(faces),size(faces)),2) <= 0;
if ~any(negative) || all(negative)
    policy.reason = 'empty-coordinate-half';
    return;
end
% A connected mesh must not be presented as two independent hemispheres.
% This check is invariant to vertex/face order and matches renderer scopes.
if ~isempty(intersect(faces(negative,:),faces(~negative,:)))
    policy.reason = 'connected-across-coordinate-halves';
    % FreeSurfer hemispheres can cross X=0 locally around the medial wall.
    % Never cut those triangles: accept exactly two connected components,
    % each predominantly on an opposite coordinate side. A continuous or
    % ambiguous mesh still falls back to complete-surface views.
    edges = [faces(:,[1 2]); faces(:,[2 3]); faces(:,[3 1])];
    components = conncomp(graph(edges(:,1),edges(:,2),[],numel(x)));
    used = unique(faces(:));
    ids = unique(components(used));
    if numel(ids) ~= 2, return; end
    first = used(components(used)==ids(1));
    second = used(components(used)==ids(2));
    leftFirst = mean(x(first)<=0) >= 0.95 && mean(x(second)>0) >= 0.95;
    leftSecond = mean(x(second)<=0) >= 0.95 && mean(x(first)>0) >= 0.95;
    if ~leftFirst && ~leftSecond, return; end
    leftId = ids(1+double(leftSecond));
    negative = reshape(components(faces(:,1))==leftId,[],1);
    policy.mode = 'eight-split';
    policy.reason = 'two-disjoint-opposite-side-components';
    return;
end
policy.mode = 'eight-split';
policy.reason = 'disjoint-nonempty-coordinate-halves';
end

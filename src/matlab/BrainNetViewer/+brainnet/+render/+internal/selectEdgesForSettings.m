function [pairs, values] = selectEdgesForSettings(matrix, settings, coordinates)
%SELECTEDGESFORSETTINGS Apply the visualization-settings edge selection contract.

arguments
    matrix double
    settings (1, 1) struct
    coordinates double = zeros(0,3)
end

if isempty(matrix) || size(matrix, 1) ~= size(matrix, 2)
    error('BNV:Render:InvalidEdgeMatrix', 'Edge data must be a square matrix.');
end

count = size(matrix, 1);
candidate = matrix ~= 0;
candidate(1:count + 1:end) = false;
if ~settings.directed
    candidate = triu(candidate, 1);
end
measure = matrix;
if string(settings.value_mode) == "absolute"
    measure = abs(measure);
end

switch string(settings.selection_mode)
    case "all"
        selected = candidate;
    case "threshold"
        selected = candidate & measure >= settings.threshold;
    case "legacy-sparsity"
        threshold=brainnet.core.legacySparsityThreshold(matrix,settings.sparsity,string(settings.value_mode));
        selected=candidate & measure>=threshold;
    case "sparsity"
        indices = find(candidate);
        selected = false(size(candidate));
        if ~isempty(indices) && settings.sparsity > 0
            keepCount = min(numel(indices), max(1, ceil(settings.sparsity * numel(indices))));
            % Explicit tie break: ascending MATLAB linear index (column-major).
            [~, order] = sortrows([-measure(indices),double(indices)],[1 2]);
            selected(indices(order(1:keepCount))) = true;
        end
    otherwise
        error('BNV:Render:UnsupportedEdgeSelection', ...
            'Unsupported edge selection mode: %s.', settings.selection_mode);
end

[row, column] = find(selected);
pairs = [row, column];
values = matrix(sub2ind(size(matrix), row, column));
if settings.inter_hemisphere_only
    if ~isreal(coordinates) || ~isequal(size(coordinates),[count 3]) || any(~isfinite(coordinates(:)))
        error('BNV:EdgeSelection:NodeCoordinates','Inter-hemisphere filtering requires finite real N-by-3 node coordinates.');
    end
    % Select first, then remove strictly same-side pairs, retaining x=0 endpoints.
    % Sign comparisons avoid coordinate-product underflow.
    x=coordinates(:,1);
    sameSide=(x(row)>0 & x(column)>0) | (x(row)<0 & x(column)<0);
    pairs(sameSide,:)=[]; values(sameSide)=[];
end
end

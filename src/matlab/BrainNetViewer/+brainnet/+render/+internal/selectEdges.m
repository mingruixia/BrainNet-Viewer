function [pairs, values] = selectEdges(matrix, drawMode, threshold)
%SELECTEDGES Vectorized undirected edge selection matching legacy Nettrans.

arguments
    matrix double
    drawMode (1, 1) double
    threshold (1, 1) double
end

if isempty(matrix) || size(matrix, 1) ~= size(matrix, 2)
    error('BNV:Render:InvalidEdgeMatrix', 'Edge data must be a square matrix.');
end
selection = abs(matrix);
selection(1:size(selection, 1) + 1:end) = 0;
if drawMode == 2
    selection(selection < threshold) = 0;
elseif drawMode ~= 1
    error('BNV:Render:UnsupportedEdgeDrawMode', ...
        'Render preparation supports edge draw modes 1 and 2.');
end
[row, column] = find(triu(selection) ~= 0);
pairs = [row, column];
values = matrix(sub2ind(size(matrix), row, column));
end

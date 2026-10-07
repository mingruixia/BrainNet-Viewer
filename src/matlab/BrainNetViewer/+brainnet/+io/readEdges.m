function edges = readEdges(reference, rootPath, options)
%READEDGES Read and validate a BrainNet ASCII .edge matrix.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
    options.RequireSymmetric (1, 1) logical = false
    options.SymmetryTolerance (1, 1) double = 0
end

pathValue = brainnet.io.internal.resolveAndVerify(reference, rootPath, "edge");
fileId = fopen(pathValue, 'r', 'n', 'UTF-8');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open edge input: %s', reference.RelativePath);
end
cleanup = onCleanup(@() fclose(fileId));

rows = cell(0, 1);
columnCount = [];
lineNumber = 0;
while true
    line = fgetl(fileId);
    if ~ischar(line)
        break;
    end
    lineNumber = lineNumber + 1;
    commentAt = strfind(line, '#');
    if ~isempty(commentAt)
        line = line(1:commentAt(1) - 1);
    end
    line = strtrim(line);
    if isempty(line)
        continue;
    end
    row = str2double(string(regexp(line, '\s+', 'split')));
    if any(~isfinite(row))
        error('BNV:IO:NonFiniteValue', 'Edge row %d contains a non-finite numeric value.', lineNumber);
    end
    if isempty(columnCount)
        columnCount = numel(row);
    elseif numel(row) ~= columnCount
        error('BNV:IO:InconsistentEdgeColumns', ...
            'Edge row %d has %d values; expected %d.', lineNumber, numel(row), columnCount);
    end
    rows{end + 1, 1} = row; %#ok<AGROW>
end
if isempty(rows)
    error('BNV:IO:EmptyEdgeFile', 'Edge input contains no data rows: %s', reference.RelativePath);
end
matrix = vertcat(rows{:});
edges = brainnet.io.EdgeData(matrix, reference, ...
    RequireSymmetric=options.RequireSymmetric, ...
    SymmetryTolerance=options.SymmetryTolerance);
end

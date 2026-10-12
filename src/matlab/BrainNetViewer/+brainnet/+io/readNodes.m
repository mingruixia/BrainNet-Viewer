function nodes = readNodes(reference, rootPath)
%READNODES Read and validate a BrainNet ASCII .node file.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
end

pathValue = brainnet.io.internal.resolveAndVerify(reference, rootPath, "node");
fileId = fopen(pathValue, 'r', 'n', 'UTF-8');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open node input: %s', reference.RelativePath);
end
cleanup = onCleanup(@() fclose(fileId));

values = zeros(0, 5);
labels = strings(0, 1);
lineNumber = 0;
while true
    line = fgetl(fileId);
    if ~ischar(line)
        break;
    end
    lineNumber = lineNumber + 1;
    commentAt = regexp(line, '(?<!\S)#', 'once');
    if ~isempty(commentAt)
        line = line(1:commentAt(1) - 1);
    end
    if isempty(strtrim(line))
        continue;
    end
    match = regexp(line, '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+?)\s*$', ...
        'tokens', 'once');
    if isempty(match)
        error('BNV:IO:InvalidNodeColumns', ...
            'Node row %d must contain five numeric values and a label.', lineNumber);
    end
    row = str2double(string(match(1:5)));
    if any(~isfinite(row))
        error('BNV:IO:NonFiniteValue', 'Node row %d contains a non-finite numeric value.', lineNumber);
    end
    values(end + 1, :) = row; %#ok<AGROW>
    labels(end + 1, 1) = string(strtrim(match{6})); %#ok<AGROW>
end
if isempty(values)
    error('BNV:IO:EmptyNodeFile', 'Node input contains no data rows: %s', reference.RelativePath);
end
nodes = brainnet.io.NodeData(values, labels, reference);
end

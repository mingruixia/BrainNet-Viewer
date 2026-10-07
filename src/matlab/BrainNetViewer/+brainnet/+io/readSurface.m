function surface = readSurface(reference, rootPath)
%READSURFACE Read and validate a BrainNet ASCII .nv surface.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
end

pathValue = brainnet.io.internal.resolveAndVerify(reference, rootPath, "surface");
fileId = fopen(pathValue, 'r', 'n', 'UTF-8');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open surface input: %s', reference.RelativePath);
end
cleanup = onCleanup(@() fclose(fileId));
tokens = textscan(fileId, '%f', 'CommentStyle', '#', 'CollectOutput', true);
values = tokens{1};
if isempty(values)
    error('BNV:IO:EmptySurface', 'Surface input contains no numeric data: %s', reference.RelativePath);
end

vertexCount = values(1);
if ~isfinite(vertexCount) || vertexCount < 1 || vertexCount ~= fix(vertexCount)
    error('BNV:IO:InvalidVertexCount', 'Surface vertex count must be a positive integer.');
end
faceCountIndex = 2 + 3 * vertexCount;
if numel(values) < faceCountIndex
    error('BNV:IO:SurfaceTokenCountMismatch', 'Surface input ends before its face count.');
end
faceCount = values(faceCountIndex);
if ~isfinite(faceCount) || faceCount < 1 || faceCount ~= fix(faceCount)
    error('BNV:IO:InvalidFaceCount', 'Surface face count must be a positive integer.');
end
expectedCount = 2 + 3 * vertexCount + 3 * faceCount;
if numel(values) ~= expectedCount
    error('BNV:IO:SurfaceTokenCountMismatch', ...
        'Surface input contains %d numeric values; %d are required by its counts.', ...
        numel(values), expectedCount);
end

coordinates = reshape(values(2:faceCountIndex - 1), 3, vertexCount);
faces = reshape(values(faceCountIndex + 1:end), 3, faceCount).';
surface = brainnet.io.SurfaceData(coordinates, faces, reference);
end

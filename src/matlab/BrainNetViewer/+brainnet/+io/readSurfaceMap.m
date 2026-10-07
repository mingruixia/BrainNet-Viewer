function values = readSurfaceMap(reference, rootPath)
%READSURFACEMAP Read per-vertex scalars; NaN represents missing data.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
end

pathValue = brainnet.io.internal.resolveAndVerify(reference, rootPath, "surface_map");
fileId = fopen(pathValue, 'r', 'n', 'UTF-8');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open surface-map input: %s', reference.RelativePath);
end
cleanup = onCleanup(@() fclose(fileId));
parsed = textscan(fileId, '%f', 'CommentStyle', '#', 'CollectOutput', true);
values = double(parsed{1}(:));
if isempty(values)
    error('BNV:IO:EmptySurfaceMap', 'Surface-map input contains no numeric values.');
end
if any(isinf(values))
    error('BNV:IO:NonFiniteValue', 'Surface-map scalars may contain NaN, but not infinity.');
end
end

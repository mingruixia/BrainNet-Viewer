function [vertices, faces, information] = buildNodeMesh(coordinates, radii, nodeIndices, detail, options)
%BUILDNODEMESH Merge spheres with vectorized CPU or optional GPU transforms.

arguments
    coordinates (:, 3) double
    radii (:, 1) double
    nodeIndices (:, 1) double
    detail (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(detail, 4)} = 12
    options.Backend (1, 1) string = "auto"
end

nodeIndices = nodeIndices(:);
requestedBackend = options.Backend;
if ~any(requestedBackend == ["auto", "cpu", "gpu"])
    error('BNV:Render:UnsupportedComputeBackend', ...
        'Compute backend must be auto, cpu, or gpu.');
end
if isempty(nodeIndices)
    vertices = zeros(0, 3);
    faces = zeros(0, 3);
    information = backendInformation(requestedBackend, "cpu", "empty-input", 0);
    return;
end
if numel(radii) ~= size(coordinates, 1)
    error('BNV:Render:NodeRadiusCountMismatch', ...
        'Every node must have one normalized radius.');
end
if any(nodeIndices < 1 | nodeIndices > size(coordinates, 1) | nodeIndices ~= fix(nodeIndices))
    error('BNV:Render:InvalidNodeIndices', 'Node indices are outside the coordinate array.');
end

[x, y, z] = sphere(detail);
baseVertices = [x(:), y(:), z(:)];
side = detail + 1;
grid = reshape(1:(side * side), side, side);
baseFaces = zeros(detail * detail * 2, 3, 'uint32');
writeIndex = 1;
for column = 1:detail
    for row = 1:detail
        a = grid(row, column);
        b = grid(row + 1, column);
        c = grid(row + 1, column + 1);
        d = grid(row, column + 1);
        baseFaces(writeIndex, :) = [a b c];
        baseFaces(writeIndex + 1, :) = [a c d];
        writeIndex = writeIndex + 2;
    end
end

vertexCount = size(baseVertices, 1);
faceCount = size(baseFaces, 1);
capabilities = brainnet.render.internal.accelerationCapabilities();
[backend, reason] = chooseBackend(requestedBackend, numel(nodeIndices), capabilities);
timer = tic;
centers = coordinates(nodeIndices, :);
scales = radii(nodeIndices);
if backend == "gpu"
    baseVertices = gpuArray(baseVertices);
    centers = gpuArray(centers);
    scales = gpuArray(scales);
end
vertices = repmat(baseVertices, numel(nodeIndices), 1) .* ...
    repelem(scales, vertexCount, 1) + repelem(centers, vertexCount, 1);
if backend == "gpu"
    vertices = gather(vertices);
end
offsets = repelem(uint32((0:(numel(nodeIndices) - 1)).') * uint32(vertexCount), ...
    faceCount, 1);
faces = repmat(baseFaces, numel(nodeIndices), 1) + offsets;
information = backendInformation(requestedBackend, backend, reason, toc(timer));
end


function [backend, reason] = chooseBackend(requested, itemCount, capabilities)
if requested == "cpu"
    backend = "cpu";
    reason = "explicit-cpu";
elseif requested == "gpu"
    if capabilities.available_gpu_count < 1
        error('BNV:Render:GpuUnavailable', ...
            'GPU computation was requested, but no supported GPU is available.');
    end
    backend = "gpu";
    reason = "explicit-gpu";
elseif capabilities.available_gpu_count > 0 && itemCount >= 50000
    backend = "gpu";
    reason = "auto-large-node-transform";
else
    backend = "cpu";
    reason = "auto-vectorized-cpu";
end
end


function value = backendInformation(requested, used, reason, seconds)
value = struct('requested', char(requested), 'used', char(used), ...
    'reason', char(reason), 'seconds', seconds, ...
    'vectorized', true, 'explicit_parallel_pool', false);
end

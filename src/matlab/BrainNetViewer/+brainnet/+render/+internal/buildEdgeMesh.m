function [vertices, faces, information] = buildEdgeMesh(coordinates, pairs, edgeRadii, nodeRadii, edgeIndices, sides, options)
%BUILDEDGEMESH Merge tubes with vectorized CPU or optional GPU transforms.

arguments
    coordinates (:, 3) double
    pairs (:, 2) double
    edgeRadii (:, 1) double
    nodeRadii (:, 1) double
    edgeIndices (:, 1) double
    sides (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(sides, 3)} = 8
    options.Backend (1, 1) string = "auto"
    options.ArrowLengthScale (1, 1) double {mustBeNonnegative} = 0
end

edgeIndices = edgeIndices(:);
requestedBackend = options.Backend;
if ~any(requestedBackend == ["auto", "cpu", "gpu"])
    error('BNV:Render:UnsupportedComputeBackend', ...
        'Compute backend must be auto, cpu, or gpu.');
end
if isempty(edgeIndices)
    vertices = zeros(0, 3);
    faces = zeros(0, 4, 'uint32');
    information = backendInformation(requestedBackend, "cpu", "empty-input", 0);
    return;
end
if numel(edgeRadii) ~= size(pairs, 1)
    error('BNV:Render:EdgeRadiusCountMismatch', ...
        'Every edge must have one normalized radius.');
end
if numel(nodeRadii) ~= size(coordinates, 1)
    error('BNV:Render:NodeRadiusCountMismatch', ...
        'Every node must have one normalized radius.');
end
if any(pairs(:) < 1 | pairs(:) > size(coordinates, 1) | pairs(:) ~= fix(pairs(:)))
    error('BNV:Render:InvalidEdgePairs', 'Edge pairs are outside the node coordinate array.');
end

selectedPairs = pairs(edgeIndices, :);
pointA = coordinates(selectedPairs(:, 1), :);
pointB = coordinates(selectedPairs(:, 2), :);
selectedRadii = edgeRadii(edgeIndices);
trimA = nodeRadii(selectedPairs(:, 1));
trimB = nodeRadii(selectedPairs(:, 2));
capabilities = brainnet.render.internal.accelerationCapabilities();
[backend, reason] = chooseBackend(requestedBackend, numel(edgeIndices), capabilities);
timer = tic;
if backend == "gpu"
    pointA = gpuArray(pointA);
    pointB = gpuArray(pointB);
    selectedRadii = gpuArray(selectedRadii);
    trimA = gpuArray(trimA);
    trimB = gpuArray(trimB);
end
direction = pointB - pointA;
lengthValue = sqrt(sum(direction .^ 2, 2));
if any(gather(lengthValue <= eps))
    error('BNV:Render:ZeroLengthEdge', 'Edge endpoints must not be coincident.');
end
unitDirection = direction ./ lengthValue;
reference = repmat([0 0 1], numel(edgeIndices), 1);
reference(abs(gather(unitDirection(:, 3))) >= 0.9, :) = repmat( ...
    [0 1 0], nnz(abs(gather(unitDirection(:, 3))) >= 0.9), 1);
if backend == "gpu"
    reference = gpuArray(reference);
end
axisU = cross(unitDirection, reference, 2);
axisU = axisU ./ sqrt(sum(axisU .^ 2, 2));
axisV = cross(unitDirection, axisU, 2);
[trimA,trimB,arrowLength]=brainnet.render.internal.edgeArrowTrims( ...
    lengthValue,trimA,trimB,selectedRadii,options.ArrowLengthScale);
startPoint = pointA + trimA .* unitDirection;
endPoint = pointB - (trimB+arrowLength) .* unitDirection;
theta = (0:(sides - 1)) * (2 * pi / sides);
circleCos = reshape(cos(theta), 1, sides, 1);
circleSin = reshape(sin(theta), 1, sides, 1);
if backend == "gpu"
    circleCos = gpuArray(circleCos);
    circleSin = gpuArray(circleSin);
end
offsets = reshape(selectedRadii, [], 1, 1) .* ( ...
    reshape(axisU, [], 1, 3) .* circleCos + ...
    reshape(axisV, [], 1, 3) .* circleSin);
rings = cat(2, reshape(startPoint, [], 1, 3) + offsets, ...
    reshape(endPoint, [], 1, 3) + offsets);
vertices = reshape(permute(rings, [2 1 3]), [], 3);
if backend == "gpu"
    vertices = gather(vertices);
end
first = uint32((1:sides).');
next = circshift(first, -1);
baseFaces = [first next next + uint32(sides) first + uint32(sides)];
offsets = repelem(uint32((0:(numel(edgeIndices) - 1)).') * ...
    uint32(2 * sides), sides, 1);
faces = repmat(baseFaces, numel(edgeIndices), 1) + offsets;
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
elseif capabilities.available_gpu_count > 0 && itemCount >= 100000
    backend = "gpu";
    reason = "auto-large-edge-transform";
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

function [values, information] = mapVolumeToSurface(volume, surfaceCoordinates, algorithm, options)
%MAPVOLUMETOSURFACE Map volume data with automatic CPU/GPU selection.

arguments
    volume (1, 1) brainnet.io.VolumeData
    surfaceCoordinates double
    algorithm (1, 1) double
    options.ComputeBackend (1, 1) string = "auto"
    options.SurfaceFaces double = zeros(0, 3)
end

if size(surfaceCoordinates, 1) ~= 3
    error('BNV:Render:InvalidSurfaceCoordinates', ...
        'Surface coordinates must be a 3-by-N array.');
end
if ndims(volume.Data) ~= 3
    error('BNV:Render:UnsupportedVolumeDimensions', ...
        'Surface mapping currently requires a three-dimensional NIfTI volume.');
end

requestedBackend = options.ComputeBackend;
if ~any(requestedBackend == ["auto", "cpu", "gpu"])
    error('BNV:Render:UnsupportedComputeBackend', ...
        'Compute backend must be auto, cpu, or gpu.');
end
capabilities = brainnet.render.internal.accelerationCapabilities();
[backend, reason] = chooseBackend(requestedBackend, algorithm, ...
    size(surfaceCoordinates, 2), capabilities);
timer = tic;
if backend == "gpu"
    values = gpuMap(volume, surfaceCoordinates, algorithm);
    information = backendInformation(requestedBackend, backend, reason, ...
        toc(timer), capabilities);
    return;
end

positions = volume.Affine \ [surfaceCoordinates; ones(1, size(surfaceCoordinates, 2))];
positions = positions(1:3, :);
dimensions = size(volume.Data);
values = zeros(1, size(surfaceCoordinates, 2));

switch algorithm
    case 1
        values = nearestSample(volume.Data, positions, false);
    case 2
        values = nearestSample(volume.Data, positions, false);
        values = averageSurfaceNeighbors(values, options.SurfaceFaces);
    case 3
        filtered = convn(double(volume.Data), ones(3, 3, 3) / 27, 'same');
        values = nearestSample(filtered, positions, false);
    case 4
        filtered = smooth3(double(volume.Data), 'gaussian');
        values = nearestSample(filtered, positions, false);
    case 5
        rounded = round(positions);
        valid = rounded(1, :) > 1 & rounded(1, :) < dimensions(1) & ...
            rounded(2, :) > 1 & rounded(2, :) < dimensions(2) & ...
            rounded(3, :) > 1 & rounded(3, :) < dimensions(3);
        point = positions(:, valid);
        lower = floor(point);
        fraction = point - lower;
        upper = ceil(point);
        upper(fraction == 0) = upper(fraction == 0) + 1;
        x0 = lower(1, :); x1 = upper(1, :);
        y0 = lower(2, :); y1 = upper(2, :);
        z0 = lower(3, :); z1 = upper(3, :);
        fx = fraction(1, :); fy = fraction(2, :); fz = fraction(3, :);
        data = volume.Data;
        c000 = data(sub2ind(dimensions, x0, y0, z0));
        c100 = data(sub2ind(dimensions, x1, y0, z0));
        c010 = data(sub2ind(dimensions, x0, y1, z0));
        c110 = data(sub2ind(dimensions, x1, y1, z0));
        c001 = data(sub2ind(dimensions, x0, y0, z1));
        c101 = data(sub2ind(dimensions, x1, y0, z1));
        c011 = data(sub2ind(dimensions, x0, y1, z1));
        c111 = data(sub2ind(dimensions, x1, y1, z1));
        z00 = (c001 - c000) .* fz + c000;
        z10 = (c101 - c100) .* fz + c100;
        z01 = (c011 - c010) .* fz + c010;
        z11 = (c111 - c110) .* fz + c110;
        y0Value = (z01 - z00) .* fy + z00;
        y1Value = (z11 - z10) .* fy + z10;
        values(valid) = (y1Value - y0Value) .* fx + y0Value;
    case {6, 7, 8}
        values = neighborhoodSample(volume.Data, positions, algorithm);
    otherwise
        error('BNV:Render:UnsupportedMapAlgorithm', ...
            'Volume mapping supports algorithms 1 through 8.');
end
information = backendInformation(requestedBackend, backend, reason, ...
    toc(timer), capabilities);
end


function [backend, reason] = chooseBackend(requested, algorithm, vertexCount, capabilities)
if requested == "cpu"
    backend = "cpu";
    reason = "explicit-cpu";
elseif requested == "gpu"
    if ~any(algorithm == [1 5])
        backend = "cpu";
        reason = "requested-gpu-algorithm-cpu-only";
        return;
    end
    if capabilities.available_gpu_count < 1
        error('BNV:Render:GpuUnavailable', ...
            'GPU computation was requested, but no supported GPU is available.');
    end
    backend = "gpu";
    reason = "explicit-gpu";
elseif algorithm == 5 && vertexCount >= 50000 && ...
        capabilities.available_gpu_count > 0
    backend = "gpu";
    reason = "auto-trilinear-large-surface";
else
    backend = "cpu";
    reason = "auto-vectorized-cpu";
end
end


function values = nearestSample(data, positions, requireInterior)
dimensions = size(data);
index = round(positions);
margin = double(requireInterior);
valid = index(1, :) >= 1 + margin & index(1, :) <= dimensions(1) - margin & ...
    index(2, :) >= 1 + margin & index(2, :) <= dimensions(2) - margin & ...
    index(3, :) >= 1 + margin & index(3, :) <= dimensions(3) - margin;
values = zeros(1, size(positions, 2));
linear = sub2ind(dimensions, index(1, valid), index(2, valid), index(3, valid));
notSentinel = linear ~= 1;
target = find(valid);
values(target(notSentinel)) = data(linear(notSentinel));
end


function values = averageSurfaceNeighbors(values, faces)
if isempty(faces)
    return;
end
vertexCount = numel(values);
rows = [faces(:, 1); faces(:, 1); faces(:, 2); faces(:, 2); faces(:, 3); faces(:, 3)];
columns = [faces(:, 2); faces(:, 3); faces(:, 1); faces(:, 3); faces(:, 1); faces(:, 2)];
adjacency = sparse(rows, columns, 1, vertexCount, vertexCount);
adjacency = spones(adjacency + speye(vertexCount));
values = (adjacency * values(:) ./ sum(adjacency, 2)).';
end


function values = neighborhoodSample(data, positions, algorithm)
dimensions = size(data);
index = round(positions);
valid = index(1, :) > 1 & index(1, :) < dimensions(1) & ...
    index(2, :) > 1 & index(2, :) < dimensions(2) & ...
    index(3, :) > 1 & index(3, :) < dimensions(3);
target = find(valid);
values = zeros(1, size(positions, 2));
if isempty(target)
    return;
end
center = index(:, valid);
samples = zeros(27, numel(target));
sampleIndex = 0;
for di = -1:1
    for dj = -1:1
        for dk = -1:1
            sampleIndex = sampleIndex + 1;
            linear = sub2ind(dimensions, center(1, :) + di, ...
                center(2, :) + dj, center(3, :) + dk);
            samples(sampleIndex, :) = double(data(linear));
        end
    end
end
if algorithm == 6
    selected = max(samples, [], 1);
elseif algorithm == 7
    selected = min(samples, [], 1);
else
    [~, location] = max(abs(samples), [], 1);
    selected = samples(sub2ind(size(samples), location, 1:numel(target)));
end
values(target) = selected;
end


function values = gpuMap(volume, coordinates, algorithm)
positions = volume.Affine \ [coordinates; ones(1, size(coordinates, 2))];
positions = gpuArray(positions(1:3, :));
data = gpuArray(volume.Data);
dimensions = size(volume.Data);
values = zeros(1, size(coordinates, 2), 'gpuArray');
if algorithm == 1
    index = round(positions);
    valid = index(1, :) >= 1 & index(1, :) <= dimensions(1) & ...
        index(2, :) >= 1 & index(2, :) <= dimensions(2) & ...
        index(3, :) >= 1 & index(3, :) <= dimensions(3);
    linear = sub2ind(dimensions, index(1, valid), index(2, valid), index(3, valid));
    notSentinel = linear ~= 1;
    target = find(valid);
    values(target(notSentinel)) = data(linear(notSentinel));
elseif algorithm == 5
    rounded = round(positions);
    valid = rounded(1, :) > 1 & rounded(1, :) < dimensions(1) & ...
        rounded(2, :) > 1 & rounded(2, :) < dimensions(2) & ...
        rounded(3, :) > 1 & rounded(3, :) < dimensions(3);
    point = positions(:, valid);
    lower = floor(point);
    fraction = point - lower;
    upper = ceil(point);
    upper(fraction == 0) = upper(fraction == 0) + 1;
    x0 = lower(1, :); x1 = upper(1, :);
    y0 = lower(2, :); y1 = upper(2, :);
    z0 = lower(3, :); z1 = upper(3, :);
    fx = fraction(1, :); fy = fraction(2, :); fz = fraction(3, :);
    c000 = data(sub2ind(dimensions, x0, y0, z0));
    c100 = data(sub2ind(dimensions, x1, y0, z0));
    c010 = data(sub2ind(dimensions, x0, y1, z0));
    c110 = data(sub2ind(dimensions, x1, y1, z0));
    c001 = data(sub2ind(dimensions, x0, y0, z1));
    c101 = data(sub2ind(dimensions, x1, y0, z1));
    c011 = data(sub2ind(dimensions, x0, y1, z1));
    c111 = data(sub2ind(dimensions, x1, y1, z1));
    z00 = (c001 - c000) .* fz + c000;
    z10 = (c101 - c100) .* fz + c100;
    z01 = (c011 - c010) .* fz + c010;
    z11 = (c111 - c110) .* fz + c110;
    y0Value = (z01 - z00) .* fy + z00;
    y1Value = (z11 - z10) .* fy + z10;
    values(valid) = (y1Value - y0Value) .* fx + y0Value;
else
    error('BNV:Render:UnsupportedMapAlgorithm', ...
        'GPU mapping supports map algorithms 1 and 5.');
end
values = gather(values);
end


function value = backendInformation(requested, used, reason, seconds, capabilities)
value = struct( ...
    'requested', char(requested), ...
    'used', char(used), ...
    'reason', char(reason), ...
    'seconds', seconds, ...
    'available_gpu_count', capabilities.available_gpu_count, ...
    'mandatory_gpu_dependency', false);
end

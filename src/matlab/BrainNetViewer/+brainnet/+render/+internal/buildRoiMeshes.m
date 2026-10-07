function [meshes, information] = buildRoiMeshes(volume, settings)
%BUILDROIMESHES Extract compact atlas-label isosurfaces in world space.

arguments
    volume (1, 1) brainnet.io.VolumeData
    settings (1, 1) struct
end

timer = tic;
data = double(volume.Data);
if ndims(data) > 3 || ~isreal(data)
    error('BNV:Render:UnsupportedVolumeDimensions', ...
        'Atlas ROI rendering requires a three-dimensional label volume.');
end
finiteValues = data(isfinite(data));
labels = unique(finiteValues(finiteValues > 0 & ...
    abs(finiteValues - round(finiteValues)) < 1e-8));
labels = labels(:).';
if ~settings.draw_all
    labels = intersect(labels, double(settings.selection(:).'), 'stable');
end
customColors=zeros(0,3);
if string(settings.color_mode)=="custom"
    customColors=brainnet.core.RoiColors.lookup(settings.custom_colors,labels);
end

emptyMesh = struct('label', 0, 'vertices', zeros(0, 3), ...
    'faces', zeros(0, 3), 'color', zeros(1, 3));
meshes = repmat(emptyMesh, 1, numel(labels));
meshCount = 0;
palette = brainnet.core.Colormap.sample(settings.palette,256);
skipped = zeros(1, 0);
fallbackLabels = zeros(1, 0);
componentChecks = struct('label',{},'component_count',{}, ...
    'at_risk_components',{},'at_risk_voxel_counts',{});
kernel = 1;
if string(settings.smoothing) ~= "none" && settings.smoothing_kernel > 1
    kernel = max(3, 2 * floor(settings.smoothing_kernel / 2) + 1);
end
for labelIndex = 1:numel(labels)
    label = labels(labelIndex);
    linear = find(data == label);
    if isempty(linear)
        skipped(end + 1) = label; %#ok<AGROW>
        continue;
    end
    [i, j, k] = ind2sub(size(data), linear);
    % A virtual zero halo closes ROIs touching any volume face. Keep the
    % virtual origin (possibly <= 0) when mapping back to voxel coordinates.
    padding = max(2, floor(kernel / 2) + 1);
    lower = [min(i), min(j), min(k)] - padding;
    upper = [max(i), max(j), max(k)] + padding;
    mask = zeros(upper - lower + 1, 'single');
    indices = sub2ind(size(mask), i-lower(1)+1, j-lower(2)+1, k-lower(3)+1);
    mask(indices) = 1;
    originalMask = mask;
    if kernel > 1
        if exist('bwconncomp','file') ~= 2
            error('BNV:ROI:ComponentGuardUnavailable', ...
                'ROI smoothing protection requires bwconncomp (Image Processing Toolbox). Use Smoothing None to render without it.');
        end
        mask = smooth3(mask, char(settings.smoothing), [kernel kernel kernel]);
        components = bwconncomp(originalMask ~= 0,26);
        atRisk = find(cellfun(@(ids) ~any(mask(ids)>0.5),components.PixelIdxList));
        componentChecks(end+1) = struct('label',label, ...
            'component_count',components.NumObjects, ...
            'at_risk_components',reshape(atRisk,1,[]), ...
            'at_risk_voxel_counts',reshape(cellfun(@numel,components.PixelIdxList(atRisk)),1,[])); %#ok<AGROW>
        if ~isempty(atRisk)
            mask = originalMask;
            fallbackLabels(end+1) = label; %#ok<AGROW>
        end
    end
    % Conservative whole-label fallback: never dilate or mix smoothed large
    % components with separately reconstructed small islands.
    if max(mask, [], 'all') <= 0.5
        mask = originalMask;
        fallbackLabels(end+1) = label; %#ok<AGROW>
    end
    extracted = isosurface(mask, 0.5);
    if isempty(extracted.faces) && kernel > 1 && ~ismember(label,fallbackLabels)
        extracted = isosurface(originalMask, 0.5);
        fallbackLabels(end+1) = label; %#ok<AGROW>
    end
    if isempty(extracted.faces)
        skipped(end + 1) = label; %#ok<AGROW>
        continue;
    end
    % isosurface returns [column,row,page]; VolumeData.Affine maps
    % MATLAB's one-based [row,column,page] voxel coordinates.
    voxel = [extracted.vertices(:, 2) + lower(1) - 1, ...
        extracted.vertices(:, 1) + lower(2) - 1, ...
        extracted.vertices(:, 3) + lower(3) - 1];
    world = volume.Affine * [voxel.'; ones(1, size(voxel, 1))];
    color = settings.color;
    if string(settings.color_mode) == "custom"
        color = customColors(labelIndex,:);
    elseif string(settings.color_mode) == "index"
        color = palette(mod(round(label) - 1, size(palette, 1)) + 1, :);
    end
    meshCount = meshCount + 1;
    meshes(meshCount) = struct( ...
        'label', label, 'vertices', world(1:3, :).', ...
        'faces', double(extracted.faces), 'color', color);
end
meshes = meshes(1:meshCount);

information = struct( ...
    'requested_label_count', numel(labels), ...
    'generated_mesh_count', numel(meshes), ...
    'skipped_labels', skipped, ...
    'boundary_policy', 'virtual-zero-halo', ...
    'isosurface_level', 0.5, ...
    'effective_smoothing_kernel', kernel, ...
    'unsmoothed_fallback_labels', fallbackLabels, ...
    'small_roi_policy', 'whole-roi-unsmoothed-if-component-lost', ...
    'component_guard_connectivity', 26, ...
    'component_guard_rule', 'each-input-component-must-retain-a-voxel-above-0.5', ...
    'component_checks', componentChecks, ...
    'color_mode_requested', char(string(settings.color_mode)), ...
    'color_mode_used', char(string(settings.color_mode)), ...
    'palette', char(string(settings.palette)), ...
    'color_id_basis', 'roi-label-id', ...
    'seconds', toc(timer));
end

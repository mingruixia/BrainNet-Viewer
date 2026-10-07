function [filtered, information] = thresholdVolume(volume, settings)
%THRESHOLDVOLUME Apply auditable statistic and cluster filtering before display.

arguments
    volume (1, 1) brainnet.io.VolumeData
    settings (1, 1) struct
end

brainnet.core.VolumeThresholdPolicy.requireSupported(settings);
timer = tic;
mode = string(settings.threshold_mode);
data = volume.Data;
nonzeroBefore = nnz(data);
removedClusterCount = 0;
excludedNonfiniteCount = 0;
statistic = struct('statistic', '', 'degrees_of_freedom', [], ...
    'cutoff', NaN, 'tail', '', 'source', '', 'p_value', NaN);
threshold = settings.statistical_threshold;
if mode == "p-value"
    statistic = brainnet.core.VolumePValueThreshold.fromHeader(volume.Header, settings.p_value);
    threshold = statistic.cutoff;
end
if any(mode == ["value", "cluster", "p-value"])
    excludedNonfiniteCount = nnz(~isfinite(data));
    data(~isfinite(data)) = 0;
    if mode == "p-value" && strcmp(statistic.statistic, 'F')
        data(data < threshold) = 0;
    else
        threshold = abs(threshold);
        data(data < threshold & data > -threshold) = 0;
    end
end
clusterFilter = mode == "cluster" || ...
    (mode == "p-value" && string(settings.type) == "roi");
if clusterFilter && settings.cluster_size > 1
    components = bwconncomp(data ~= 0, settings.voxel_connectivity);
    sizes = cellfun(@numel, components.PixelIdxList);
    remove = find(sizes < settings.cluster_size);
    for index = reshape(remove, 1, [])
        data(components.PixelIdxList{index}) = 0;
    end
    removedClusterCount = numel(remove);
end
filtered = brainnet.io.VolumeData(data, volume.Header, volume.Affine, ...
    volume.AffineZeroBased, volume.Source);
information = struct( ...
    'mode', char(mode), ...
    'threshold', threshold, ...
    'p_value', settings.p_value, ...
    'cluster_size', settings.cluster_size, ...
    'voxel_connectivity', settings.voxel_connectivity, ...
    'nonzero_before', nonzeroBefore, ...
    'nonzero_after', nnz(data), ...
    'removed_cluster_count', removedClusterCount, ...
    'excluded_nonfinite_count', excludedNonfiniteCount, ...
    'p_value_applied', mode == "p-value", ...
    'statistic', statistic.statistic, ...
    'degrees_of_freedom', statistic.degrees_of_freedom, ...
    'statistic_tail', statistic.tail, ...
    'statistic_metadata_source', statistic.source, ...
    'seconds', toc(timer));
end

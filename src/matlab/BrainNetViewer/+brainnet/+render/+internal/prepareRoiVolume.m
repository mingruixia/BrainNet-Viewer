function [roiVolume, information] = prepareRoiVolume(volume, settings)
%PREPAREROIVOLUME Keep atlas IDs or explicitly generate statistical cluster IDs.
brainnet.core.VolumeThresholdPolicy.requireSupported(settings);
mode = string(settings.threshold_mode);
if mode == "none"
    roiVolume = volume;
    information = struct('representation', 'atlas-labels');
    return;
end
if ndims(volume.Data) ~= 3 || ~isreal(volume.Data)
    error('BNV:Render:InvalidStatisticalVolume', ...
        'Statistical ROIs require a real three-dimensional volume.');
end
settings.type = 'roi'; % This entry always constructs statistical ROI IDs.
[filtered, information] = brainnet.render.internal.thresholdVolume(volume, settings);
% bwlabeln matches the legacy nonzero-mask order; positive and negative
% neighbours belong to the same component. Removed clusters leave no ID gaps.
[labels, count] = bwlabeln(filtered.Data ~= 0, settings.voxel_connectivity);
roiVolume = brainnet.io.VolumeData(labels, volume.Header, volume.Affine, ...
    volume.AffineZeroBased, volume.Source);
information.representation = 'statistical-clusters';
information.cluster_count = count;
information.sign_policy = 'combined-nonzero';
information.numbering = 'bwlabeln-order-after-filtering';
information.cluster_voxel_counts = zeros(1, count);
if count > 0
    information.cluster_voxel_counts = reshape(accumarray( ...
        labels(labels > 0), 1, [count 1]), 1, []);
end
end

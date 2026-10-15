# SPDX-License-Identifier: GPL-3.0-or-later
"""CPU mapping and threshold rules ported from the current MATLAB core."""
from dataclasses import replace
import re
import numpy as np
from scipy import ndimage, sparse, stats


def gaussian_kernel(size=3, sigma=.65):
    axis = np.arange(size) - (size - 1) / 2
    grid = np.meshgrid(axis, axis, axis, indexing="ij")
    kernel = np.exp(-sum(a*a for a in grid) / (2*sigma*sigma))
    return kernel / kernel.sum()


def p_cutoff(volume, p):
    if not 0 < p < 1: raise ValueError("P value must be strictly between zero and one.")
    declarations = re.findall(r"\{([TtFfRrZz])_\[([^\]]*)\]\}", volume.description)
    if len(declarations) > 1: raise ValueError("Ambiguous statistic declarations.")
    intent_name, intent_params, _ = volume.intent
    intent_kind = {"t test":"T", "f test":"F", "correlation":"R", "z score":"Z"}.get(intent_name)
    kind, degrees = intent_kind, list(intent_params)
    source = "NIfTI intent"
    if declarations and re.search("SPM|REST|DPABI", volume.description, re.I):
        kind, raw = declarations[0]; kind = kind.upper()
        degrees = [] if kind == "Z" else [float(x) for x in re.split(r"[,;\s]+", raw.strip())]
        source = "NIfTI description"
        if intent_kind and intent_kind != kind: raise ValueError("Description and intent statistic mismatch.")
        if intent_kind and kind != "Z" and len(intent_params) == len(degrees):
            params = np.asarray(intent_params)
            if np.isfinite(params).all() and (params > 0).all() and np.any(np.abs(params-degrees)>1e-4*np.maximum(1,degrees)):
                raise ValueError("Description and intent degrees of freedom mismatch.")
    count = {"T":1, "R":1, "F":2, "Z":0}.get(kind)
    if count is None or len(degrees) != count or any(not np.isfinite(d) or d <= 0 for d in degrees):
        raise ValueError("P value needs valid SPM/REST/DPABI statistical metadata or a supported intent.")
    if kind in ("T", "R"):
        cutoff = stats.t.isf(p/2, degrees[0])
        if kind == "R": cutoff = np.sqrt(cutoff**2 / (degrees[0] + cutoff**2))
    elif kind == "F": cutoff = stats.f.isf(p, *degrees)
    else: cutoff = stats.norm.isf(p/2)
    if not np.isfinite(cutoff) or cutoff <= 0: raise ValueError("Invalid statistical cutoff.")
    return {"statistic":kind, "degrees_of_freedom":degrees, "cutoff":float(cutoff),
            "tail":"upper" if kind == "F" else "two-sided", "source":source, "p_value":p}


def connectivity(value):
    if value not in (6, 18, 26): raise ValueError("Voxel connectivity must be 6, 18 or 26.")
    return ndimage.generate_binary_structure(3, {6:1,18:2,26:3}[value])


def threshold_volume(volume, settings):
    data = volume.data.copy()
    mode = settings["threshold_mode"]
    information = {"mode":mode, "statistic":{}, "removed_cluster_count":0}
    cluster_eligible = mode == 'cluster' or mode == 'p-value' and settings['type'] == 'roi'
    information.update(cluster_size_ignored=settings['cluster_size'] > 1 and not cluster_eligible,
                       cluster_size_applied=settings['cluster_size'] > 1 and cluster_eligible,
                       voxel_connectivity=settings['voxel_connectivity'], cluster_sign_policy='combined-nonzero')
    if mode not in ("none", "value", "cluster", "p-value"): raise ValueError("Unsupported threshold mode.")
    threshold = settings["statistical_threshold"]
    if mode == "p-value":
        information["statistic"] = p_cutoff(volume, settings["p_value"])
        threshold = information["statistic"]["cutoff"]
    if mode != "none":
        data[~np.isfinite(data)] = 0
        if information["statistic"].get("statistic") == "F": data[data < threshold] = 0
        else:
            threshold=abs(threshold)
            data[np.abs(data) < threshold] = 0
    if (mode == "cluster" or (mode == "p-value" and settings["type"] == "roi")) and settings["cluster_size"] > 1:
        components, _ = ndimage.label(data != 0, connectivity(settings["voxel_connectivity"]))
        sizes = np.bincount(components.ravel())
        remove = sizes < settings["cluster_size"]; remove[0] = False
        data[remove[components]] = 0
        information["removed_cluster_count"] = int(remove.sum())
    information["threshold"] = float(threshold)
    return replace(volume, data=data), information


def roi_labels(volume, settings):
    if settings["threshold_mode"] == "none": return volume
    settings = dict(settings, type="roi")
    filtered, _ = threshold_volume(volume, settings)
    labels, count = ndimage.label(filtered.data != 0, connectivity(settings["voxel_connectivity"]))
    # MATLAB labels by first occurrence in column-major order, not SciPy's C order.
    first = np.full(count + 1, labels.size, dtype=np.int64)
    np.minimum.at(first, labels.ravel(order="F"), np.arange(labels.size))
    ordered = np.argsort(first[1:]) + 1
    lookup = np.zeros(count + 1, dtype=np.int64); lookup[ordered] = np.arange(1, count + 1)
    return replace(volume, data=lookup[labels])


def map_volume(volume, points, faces, algorithm):
    points = np.asarray(points)
    # Solve the one-based system, matching MATLAB's affine backslash order.
    # Inverting the zero-based affine and adding 1 changes rounding at half voxels.
    affine_one = volume.affine.copy()
    affine_one[:3, 3] -= affine_one[:3, :3] @ np.ones(3)
    one = np.linalg.solve(affine_one, np.column_stack((points, np.ones(len(points)))).T)[:3].T
    positions = one - 1
    # MATLAB round is half-away-from-zero on ONE-based positions.
    rounded = np.sign(one) * np.floor(np.abs(one) + .5)
    index = rounded.astype(np.int64) - 1
    shape = np.asarray(volume.data.shape)
    valid = ((index >= 0) & (index < shape)).all(axis=1)
    values = np.zeros(len(points))
    data = volume.data
    if algorithm in (1, 2, 3, 4):
        valid &= (index != 0).any(axis=1)  # old sampler excludes the first linear voxel
        if algorithm == 3: data = ndimage.convolve(data, np.ones((3,3,3))/27, mode="constant", cval=0)
        if algorithm == 4: data = ndimage.convolve(data, gaussian_kernel(), mode="nearest")
        values[valid] = data[tuple(index[valid].T)]
        if algorithm == 2 and len(faces):
            rows = np.concatenate([faces[:,0], faces[:,0], faces[:,1], faces[:,1], faces[:,2], faces[:,2], np.arange(len(points))])
            cols = np.concatenate([faces[:,1], faces[:,2], faces[:,0], faces[:,2], faces[:,0], faces[:,1], np.arange(len(points))])
            adjacency = sparse.coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(len(points),len(points))).tocsr()
            adjacency.data[:] = 1
            values = adjacency @ values / np.asarray(adjacency.sum(axis=1)).ravel()
    elif algorithm in (5,6,7,8):
        valid &= ((index > 0) & (index < shape - 1)).all(axis=1)
        if algorithm == 5:
            values[valid] = ndimage.map_coordinates(data, positions[valid].T, order=1, mode="constant", cval=0, prefilter=False)
        else:
            center = index[valid]
            samples = np.asarray([data[tuple((center + [di,dj,dk]).T)]
                                  for di in (-1,0,1) for dj in (-1,0,1) for dk in (-1,0,1)])
            if algorithm == 6: chosen = samples.max(axis=0)
            elif algorithm == 7: chosen = samples.min(axis=0)
            else: chosen = samples[np.abs(samples).argmax(axis=0), np.arange(samples.shape[1])]
            values[valid] = chosen
    else: raise ValueError("Surface mapping algorithm must be 1 through 8.")
    return values

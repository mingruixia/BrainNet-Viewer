# SPDX-License-Identifier: GPL-3.0-or-later
"""Ported node/edge numerical rules, preserving MATLAB column-major ordering."""
import numpy as np
import warnings


def edge_diagnostics(matrix, settings):
    if not settings['directed'] and not np.allclose(matrix, np.asarray(matrix).T):
        return ['Undirected edge matrix is asymmetric; only the upper triangle is used.']
    return []


def select_edges(matrix, settings, positions=None):
    matrix = np.asarray(matrix, dtype=float)
    if matrix.ndim != 2 or not len(matrix) or matrix.shape[0] != matrix.shape[1] or not np.isfinite(matrix).all():
        raise ValueError("Edge data must be a finite nonempty square matrix.")
    candidate = matrix != 0
    for message in edge_diagnostics(matrix, settings):
        warnings.warn(message, UserWarning, stacklevel=2)
    np.fill_diagonal(candidate, False)
    if not settings["directed"]: candidate = np.triu(candidate, 1)
    measure = np.abs(matrix) if settings["value_mode"] == "absolute" else matrix
    indices = np.flatnonzero(candidate.ravel(order="F"))
    weights = measure.ravel(order="F")[indices]
    mode = settings["selection_mode"]
    if mode == "threshold":
        indices = indices[weights >= settings["threshold"]]
    elif mode == "sparsity":
        fraction = settings["sparsity"]
        if not 0 <= fraction <= 1: raise ValueError("Sparsity must be in [0,1].")
        count = min(len(indices), max(1, int(np.ceil(fraction * len(indices))))) if fraction > 0 else 0
        order = np.lexsort((indices, -weights))
        indices = np.sort(indices[order[:count]])
    elif mode == "legacy-sparsity":
        fraction = settings["sparsity"]
        if not 0 <= fraction <= 1: raise ValueError("Sparsity must be in [0,1].")
        ordered = np.sort(measure.ravel())[::-1]
        # MATLAB int32 rounds positive halves away from zero.
        index = max(1, min(len(ordered), int(np.floor(fraction * matrix.size + .5))))
        threshold = float(f"{ordered[index - 1]:.6f}")
        indices = indices[weights >= threshold]
    elif mode != "all":
        raise ValueError(f"Unsupported edge selection: {mode}")
    rows, cols = np.unravel_index(indices, matrix.shape, order="F")
    pairs = np.column_stack((rows, cols)).astype(int)
    values = matrix[rows, cols]
    if settings.get("inter_hemisphere_only"):
        positions = np.asarray(positions)
        if positions.shape != (len(matrix), 3) or not np.isfinite(positions).all():
            raise ValueError("Inter-hemisphere filtering requires finite N-by-3 positions.")
        x = positions[:, 0]
        same = ((x[rows] > 0) & (x[cols] > 0)) | ((x[rows] < 0) & (x[cols] < 0))
        pairs, values = pairs[~same], values[~same]
    return pairs, values


def normalize_node_radii(values):
    radii = np.asarray(values, dtype=float).copy()
    if not len(radii): return radii
    if not np.isfinite(radii).all(): raise ValueError("Node values must be finite.")
    if radii.min() < 0: radii -= radii.min()
    if radii.min() < 1: radii += 1
    if not np.isfinite(radii).all(): raise ValueError("Node normalization overflow.")
    while radii.max() / radii.min() > 10:
        radii = np.log(radii)
        if radii.min() < 1: radii += 1
    return 2 + 5 * (radii - radii.min()) / np.ptp(radii) if np.ptp(radii) else np.full_like(radii, 4)


def node_radii(nodes, settings):
    values = nodes.modules if settings["size_basis"] == "module" else nodes.values
    mode = settings["size_mode"]
    if mode == "uniform": radii = np.full_like(values, settings["size"])
    elif mode == "raw": radii = values.copy()
    elif mode == "mapped": radii = normalize_node_radii(values)
    elif mode == "threshold":
        radii = normalize_node_radii(values) if settings["size_threshold_basis"] == "mapped" else values.copy()
        radii[radii < settings["size_threshold"]] = 1
    else: raise ValueError("Unsupported node size mode.")
    radii *= settings["size_scale"]
    if not np.isfinite(radii).all() or (radii < 0).any(): raise ValueError("Node radii must be finite and nonnegative.")
    return radii


def edge_radii(values, settings):
    values = np.asarray(values, dtype=float)
    if settings["size_value_mode"] == "absolute": values = np.abs(values)
    def mapped(v):
        return .4 + 5.6 * (v - v.min()) / np.ptp(v) if np.ptp(v) else np.full_like(v, 2)
    mode = settings["size_mode"]
    if not len(values): return values.copy()
    if mode == "uniform": result = np.full_like(values, settings["size"])
    elif mode == "raw": result = np.clip(values, .2, 6)
    elif mode == "mapped": result = mapped(values)
    elif mode == "threshold":
        keep = values >= settings["size_threshold"]
        if settings["size_threshold_basis"] == "mapped":
            result = np.full_like(values, .4)
            if keep.any(): result[keep] = mapped(values[keep])
        else: result = np.minimum(np.where(keep, values, .4), 6)
    else: raise ValueError("Unsupported edge size mode.")
    result *= settings["size_scale"]
    if not np.isfinite(result).all() or (result < 0).any(): raise ValueError("Edge radii must be finite and nonnegative.")
    return result

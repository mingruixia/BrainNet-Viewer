"""Ordered numeric-array fingerprints matching MATLAB's double-array contract."""
import hashlib
import numpy as np


def array_digest(value):
    value=np.asarray(value,dtype=np.float64)
    if value.ndim!=2 or not np.isfinite(value).all(): raise ValueError("Binding requires a finite double matrix.")
    digest=hashlib.sha256(("double:"+"".join(f"{n}x" for n in value.shape)).encode("utf-8"))
    digest.update(value.tobytes(order="F"))
    return digest.hexdigest()


def geometry_signature(points,faces):
    return hashlib.sha256((array_digest(np.asarray(points).T)+":"+array_digest(np.asarray(faces,dtype=float)+1)).encode("utf-8")).hexdigest()


def node_signature(points):
    return hashlib.sha256((array_digest(np.asarray(points).T)+":"+array_digest(np.empty((0,3)))).encode("utf-8")).hexdigest()


def custom_edge_colors(descriptor, colormap, points, pairs):
    from .rendering import palette
    matrix=np.asarray(descriptor["matrix"],dtype=float); categories=np.asarray(descriptor["indices"],dtype=float)
    if matrix.shape!=(len(points),len(points)) or matrix.size>4_000_000 or not np.isfinite(matrix).all(): raise ValueError("Custom edge colors need a finite color matrix matching nodes.")
    if categories.ndim!=1 or not 1<=len(categories)<=4096 or not np.isfinite(categories).all() or len(np.unique(categories))!=len(categories): raise ValueError("Custom edge categories must be unique finite values.")
    if descriptor["node_sha256"]!=node_signature(points): raise ValueError("Custom edge colors are unbound or belong to different ordered nodes.")
    values=matrix[pairs[:,0],pairs[:,1]]; matches=values[:,None]==categories
    if not matches.any(axis=1).all(): raise ValueError("A displayed edge has no custom color category.")
    if isinstance(colormap,str): colors=palette(colormap,max(2,len(categories)))
    else:
        if len(colormap)<len(categories): raise ValueError("The RGB table needs one row per custom category.")
        colors=palette(colormap,len(colormap))
    return colors[np.argmax(matches,axis=1)]

"""Numerical inputs, independent of either user interface or renderer."""
from dataclasses import dataclass
from pathlib import Path, PureWindowsPath
import hashlib
import xml.etree.ElementTree as ET
import numpy as np


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def resolve_asset(root, relative):
    """Scene references cannot escape their explicitly supplied data root."""
    if not isinstance(relative, str) or not relative or "\\" in relative:
        raise ValueError("Scene paths must be nonempty relative paths using '/'.")
    path = Path(relative)
    if path.is_absolute() or PureWindowsPath(relative).drive or ".." in path.parts:
        raise ValueError("Absolute paths and parent traversal are not allowed in a Scene.")
    root = Path(root).resolve()
    result = (root / path).resolve()
    if not result.is_relative_to(root):
        raise ValueError("Scene asset escapes the data root.")
    return result


def data_lines(path):
    with Path(path).open(encoding="utf-8-sig") as stream:
        for number, line in enumerate(stream, 1):
            line = line.split("#", 1)[0].strip()
            if line:
                yield number, line


@dataclass
class Surface:
    points: np.ndarray
    faces: np.ndarray
    path: Path

    def __post_init__(self):
        self.points = np.asarray(self.points, dtype=float)
        raw = np.asarray(self.faces)
        if self.points.ndim != 2 or self.points.shape[1] != 3 or not len(self.points):
            raise ValueError("Surface requires nonempty N-by-3 vertices.")
        if raw.ndim != 2 or raw.shape[1] != 3 or not len(raw):
            raise ValueError("Surface requires nonempty triangular faces.")
        if not np.isfinite(self.points).all() or not np.isfinite(raw).all():
            raise ValueError("Surface coordinates and faces must be finite.")
        if not np.equal(raw, np.floor(raw)).all() or raw.min() < 0 or raw.max() >= len(self.points):
            raise ValueError("Face indices must be zero-based integers within the vertex array.")
        self.faces = raw.astype(np.int64)
        self.path = Path(self.path)


@dataclass
class Nodes:
    positions: np.ndarray
    modules: np.ndarray
    values: np.ndarray
    labels: list[str]
    path: Path


@dataclass
class Volume:
    data: np.ndarray
    affine: np.ndarray  # zero-based voxel to world, no implicit RAS reorientation
    description: str
    intent: tuple
    path: Path
    affine_source: str


def gifti_dependencies(path):
    path = Path(path).resolve()
    if path.stat().st_size > 128 * 1024 * 1024:
        raise ValueError("GIfTI XML exceeds the current input limit.")
    tree = ET.parse(path)
    dependencies = []
    for array in tree.iter():
        external = array.attrib.get("ExternalFileName", "")
        if external:
            asset = resolve_asset(path.parent, external)
            if not asset.is_file():
                raise ValueError(f"Missing external GIfTI array: {external}")
            dependencies.append(asset)
    return dependencies


def read_surface(path):
    path = Path(path).resolve()
    if path.suffix.lower() in (".mesh",".byu",".g",".obj",".mz3"):
        from .surface_formats import read_legacy
        return read_legacy(path)
    if path.suffix.lower() == ".nv":
        tokens = " ".join(line for _, line in data_lines(path)).split()
        try:
            values = np.asarray(tokens, dtype=float)
        except ValueError as error:
            raise ValueError("NV contains invalid numeric tokens.") from error
        if not len(values) or not np.isfinite(values).all():
            raise ValueError("NV must contain finite values.")
        n = int(values[0])
        offset = 1 + 3 * n
        if n < 1 or values[0] != n or offset >= len(values):
            raise ValueError("Invalid NV vertex count.")
        f = int(values[offset])
        if f < 1 or values[offset] != f or len(values) != offset + 1 + 3 * f:
            raise ValueError("Invalid NV face count or trailing data.")
        return Surface(values[1:offset].reshape(n, 3), values[offset + 1:].reshape(f, 3) - 1, path)
    import nibabel as nib
    if path.suffix.lower() == ".gii":
        gifti_dependencies(path)
        image = nib.load(path,mmap=False)
        points = [a.data for a in image.darrays if a.intent == 1008]
        faces = [a.data for a in image.darrays if a.intent == 1009]
        if len(points) != 1 or len(faces) != 1:
            raise ValueError("Surface GIfTI must contain one pointset and one triangle array.")
        return Surface(points[0], faces[0], path)
    if path.suffix.lower() in (".pial", ".white", ".inflated", ".sphere", ".orig", ".surf"):
        points, faces = nib.freesurfer.read_geometry(str(path))
        return Surface(points, faces, path)
    raise ValueError(f"Surface format not yet implemented: {path.suffix}")


def read_nodes(path):
    rows, labels = [], []
    for number, line in data_lines(path):
        fields = line.split(maxsplit=5)
        if len(fields) != 6:
            raise ValueError(f"Node row {number} needs five numbers and a label.")
        try:
            row = [float(x) for x in fields[:5]]
        except ValueError as error:
            raise ValueError(f"Invalid numeric value at node row {number}.") from error
        if not np.isfinite(row).all():
            raise ValueError(f"Nonfinite node row {number}.")
        rows.append(row)
        labels.append(fields[5].strip())
    if not rows:
        raise ValueError("Empty node file.")
    values = np.asarray(rows)
    return Nodes(values[:, :3], values[:, 3], values[:, 4], labels, Path(path).resolve())


def read_edges(path, node_count=None):
    rows = [[float(x) for x in line.split()] for _, line in data_lines(path)]
    if not rows or any(len(row) != len(rows) for row in rows):
        raise ValueError("Edges require a nonempty square matrix.")
    matrix = np.asarray(rows, dtype=float)
    if not np.isfinite(matrix).all():
        raise ValueError("Edge values must be finite.")
    if node_count is not None and len(matrix) != node_count:
        raise ValueError("Edge matrix dimensions do not match the node count.")
    return matrix


def read_surface_map(path, count):
    path = Path(path)
    if path.suffix.lower() == ".gii":
        import nibabel as nib
        gifti_dependencies(path)
        arrays = nib.load(path,mmap=False).darrays
        if len(arrays) != 1:
            raise ValueError("Surface map GIfTI must contain one scalar/RGB array.")
        values = arrays[0].data
    else:
        rows = [[float(x) for x in line.split()] for _, line in data_lines(path)]
        values = np.asarray(rows)
    values = np.asarray(values, dtype=float)
    if values.size == count:
        values = values.reshape(count)
    elif values.shape != (count, 3):
        raise ValueError("Surface map must contain one scalar or RGB triplet per original vertex.")
    if np.isinf(values).any() or (values.ndim==2 and not np.isfinite(values).all()):
        raise ValueError("Scalar surface maps may contain NaN for missing vertices, but not infinity. RGB values must be finite.")
    if values.ndim == 2 and ((values < 0).any() or (values > 1).any()):
        raise ValueError("Vertex RGB values must be in [0,1].")
    return values


def read_volume(path, *, allow_singleton=False):
    import nibabel as nib
    image = nib.load(str(path), mmap=False)
    if not isinstance(image, (nib.Nifti1Image, nib.Nifti2Image, nib.Nifti1Pair, nib.Nifti2Pair)):
        raise ValueError("Only NIfTI-1/2 volumes are currently supported.")
    tool_shape = allow_singleton and 2 <= len(image.shape) and all(n == 1 for n in image.shape[3:])
    if len(image.shape) != 3 and not tool_shape:
        raise ValueError("Volume visualization currently requires a three-dimensional NIfTI.")
    affine, code = image.get_sform(coded=True)
    source = "sform"
    if not code:
        affine, code = image.get_qform(coded=True)
        source = "qform"
    if not code:
        # MATLAB uses pixdim and zero translation, not nibabel's centered fallback.
        affine = np.diag([*np.abs(image.header.get_zooms()[:3]), 1.0])
        source = "pixdim"
    if not np.isfinite(affine).all() or np.linalg.matrix_rank(affine) != 4:
        raise ValueError("NIfTI affine is not finite and invertible.")
    description = bytes(image.header["descrip"]).rstrip(b"\x00").decode("utf-8", errors="replace")
    data=image.get_fdata(dtype=np.float64)
    if tool_shape: data=data.reshape((*image.shape[:3], *([1] * max(0,3-len(image.shape)))))
    return Volume(data, affine, description,
                  image.header.get_intent(), Path(path).resolve(), source)

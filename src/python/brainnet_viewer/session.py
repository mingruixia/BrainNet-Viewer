"""Python camera sessions. Deliberately distinct from MATLAB session signatures."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import numpy as np
from .io import sha256, gifti_dependencies
from .settings import normalize, finite_json
from .export_size import figure_size

KEY = "python_session_state"


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False, allow_nan=False,
                                     separators=(",", ":")).encode("utf-8")).hexdigest()


def content_hash(path):
    path = Path(path).resolve()
    dependencies = gifti_dependencies(path) if path.suffix.lower() == ".gii" else []
    if path.suffix.lower() in (".hdr", ".img"):
        dependencies.append(path.with_suffix(".img" if path.suffix.lower() == ".hdr" else ".hdr"))
    files = sorted(set([path, *dependencies]), key=lambda p: p.relative_to(path.parent).as_posix())
    return digest([{ "name": p.relative_to(path.parent).as_posix(), "sha256": sha256(p)} for p in files])


def content_hashes(paths): return {role: content_hash(path) for role, path in paths.items()}


def signature(hashes, settings):
    settings = normalize({"visualization_settings": settings})
    # Output size does not affect the interactive camera or its montage.
    for key in ("width", "height", "dpi"): settings["image"].pop(key)
    return digest({"assets": hashes, "settings": settings})


def document_signature(document):
    hashes = {role: reference.get("metadata", {}).get("python_bundle_sha256", reference["sha256"])
              for role, reference in document["inputs"].items()}
    return signature(hashes, normalize(document.get("options", {})))


def validate_session(state):
    if not isinstance(state, dict) or state.get("version") != "1.0" or state.get("producer") != "python-vtk":
        raise ValueError("Unsupported Python camera session.")
    key=state.get("scene_signature", "")
    if not isinstance(key,str) or not re.fullmatch(r"[0-9a-f]{64}", key):
        raise ValueError("Invalid Python session signature.")
    finite_json(state)
    export = state.get("export")
    if not isinstance(export, dict): raise ValueError("Session export preferences must be an object.")
    figure_size(export.get("width"), export.get("height"), export.get("dpi"), export.get("units"))
    if not isinstance(export.get("transparent"), bool) or export.get("format") not in ("png", "jpg", "tif", "bmp", "pdf", "svg"):
        raise ValueError("Invalid export preferences in Python session.")
    if export["transparent"] and export["format"] not in ("png", "tif", "pdf", "svg"):
        raise ValueError("Transparent session export requires PNG, TIFF, PDF or SVG.")
    camera = state.get("camera")
    if camera is not None:
        if not isinstance(camera, dict) or isinstance(camera.get("layout"), bool) or camera.get("layout") not in range(1, 6):
            raise ValueError("Invalid camera layout.")
        counts = {1: (1,), 2: (6, 8), 3: (4, 6), 4: (6,), 5: (5, 6)}
        views = camera.get("views")
        if not isinstance(views, list) or len(views) not in counts[camera["layout"]]: raise ValueError("Camera view count mismatch.")
        for view in views:
            if not isinstance(view, dict): raise ValueError("Invalid camera view.")
            for key in ("position", "target", "up"):
                values = np.asarray(view.get(key), dtype=float)
                if values.shape != (3,) or not np.isfinite(values).all(): raise ValueError(f"Invalid camera {key}.")
            direction = np.asarray(view["position"])-view["target"]
            if np.linalg.norm(direction) <= 0 or np.linalg.norm(np.cross(direction, view["up"])) <= 1e-10:
                raise ValueError("Degenerate camera orientation.")
            for key in ("parallel_scale", "zoom_factor", "view_angle"):
                value = view.get(key)
                if isinstance(value, bool) or not isinstance(value, (int, float)) or not np.isfinite(value) or value <= 0:
                    raise ValueError(f"Invalid camera {key}.")
            if view["view_angle"] >= 180 or view.get("projection") not in ("orthographic", "perspective"):
                raise ValueError("Invalid camera projection.")
            if camera["layout"] > 1 and view["projection"] != "orthographic": raise ValueError("Multi-view cameras must be orthographic.")
    return deepcopy(state)


def attach_session(document, camera, export):
    state = {"version": "1.0", "producer": "python-vtk", "scene_signature": document_signature(document),
             "camera": camera, "export": export}
    document.setdefault("metadata", {})[KEY] = validate_session(state)
    return state

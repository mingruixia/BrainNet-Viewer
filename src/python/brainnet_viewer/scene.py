# SPDX-License-Identifier: GPL-3.0-or-later
"""Portable Scene JSON and separate desktop asset locations."""
from copy import deepcopy
from dataclasses import dataclass, field
from pathlib import Path
import json
import shutil
import os
from tempfile import TemporaryDirectory, NamedTemporaryFile
from .io import resolve_asset, validate_asset_path, sha256, gifti_dependencies
from .settings import normalize, finite_json
from .session import KEY, content_hash, document_signature, attach_session, validate_session

ROLES = {"surface": 1, "node": 2, "edge": 4, "surface_map": 8, "volume": 8}
SCENE_JSON_LIMIT = 32 * 1024 * 1024


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


@dataclass
class Scene:
    document: dict
    data_root: Path
    paths: dict = field(default_factory=dict)
    matlab_signature_verified: bool = False

    @property
    def settings(self):
        return normalize(self.document.get("options", {}))

    def resolve(self, verify=True):
        paths = {}
        for role, reference in self.document["inputs"].items():
            path = resolve_asset(self.data_root, reference["relative_path"])
            if not path.is_file(): raise ValueError(f"Missing {role} file: {path}")
            expected = reference.get("sha256", "")
            if verify and expected and sha256(path) != expected:
                raise ValueError(f"SHA-256 mismatch for {role}.")
            bundle = reference.get("metadata", {}).get("python_bundle_sha256")
            if verify and bundle and content_hash(path) != bundle:
                raise ValueError(f"Paired/external asset SHA-256 mismatch for {role}.")
            paths[role] = path
        self.paths = paths
        if self.matlab_signature_verified:
            for role,path in paths.items():
                dependencies=gifti_dependencies(path) if path.suffix.lower()==".gii" else []
                if path.suffix.lower() in (".hdr",".img"): dependencies.append(path.with_suffix(".img" if path.suffix.lower()==".hdr" else ".hdr"))
                if dependencies and not self.document["inputs"][role].get("metadata",{}).get("python_bundle_sha256"):
                    # A main-file-only MATLAB signature cannot certify its external payload.
                    self.matlab_signature_verified=False
        return paths


def validate_document(document):
    if not isinstance(document, dict) or document.get("schema_version") != "0.1":
        raise ValueError("Unsupported Scene schema version; expected 0.1.")
    inputs = document.get("inputs")
    if not isinstance(inputs, dict) or not inputs or any(role not in ROLES for role in inputs):
        raise ValueError("Scene inputs must contain supported input roles.")
    if "edge" in inputs and "node" not in inputs:
        raise ValueError("Scene edges require nodes.")
    if "volume" in inputs and "surface_map" in inputs:
        raise ValueError("Volume and surface map cannot coexist in one Scene.")
    mask = 0
    for role, reference in inputs.items():
        if not isinstance(reference, dict) or reference.get("role") != role:
            raise ValueError("Scene input role mismatch.")
        if "local_path" in reference:
            raise ValueError(
                "This Scene uses MATLAB local-file references, which Python Desktop "
                "and Docker/Web cannot read. Open it in MATLAB where the original "
                "files are available, or select the data again in this edition "
                "and save a new Scene."
            )
        validate_asset_path(reference.get("relative_path"))
        digest = reference.get("sha256", "")
        if not isinstance(digest, str) or (digest and (len(digest) != 64 or any(c not in "0123456789abcdef" for c in digest))):
            raise ValueError("Invalid input SHA-256.")
        metadata=reference.get("metadata",{})
        if not isinstance(metadata,dict): raise ValueError("Input metadata must be an object.")
        bundle=metadata.get("python_bundle_sha256","")
        if not isinstance(bundle,str) or (bundle and (len(bundle)!=64 or any(c not in "0123456789abcdef" for c in bundle))):
            raise ValueError("Invalid paired/external content fingerprint.")
        mask |= ROLES[role]
    if document.get("loadfile") != mask:
        raise ValueError("Scene loadfile bitmask does not match its input roles.")
    map_mode = 2 if "volume" in inputs else 1 if "surface_map" in inputs else 0
    if document.get("map_mode") != map_mode:
        raise ValueError("Scene map_mode does not match its mapping input.")
    normalize(document.get("options", {}))
    metadata = document.get("metadata", {})
    if not isinstance(metadata, dict): raise ValueError("Scene metadata must be an object.")
    if KEY in metadata: validate_session(metadata[KEY])
    if "session_state" in metadata:
        from .matlab_session import validate_matlab_session
        validate_matlab_session(metadata["session_state"])
    finite_json(document)


def read_scene(path, data_root, resolve=True, *, max_bytes=SCENE_JSON_LIMIT):
    def invalid(value): raise ValueError(f"Nonfinite JSON value: {value}")
    if not isinstance(max_bytes, int) or isinstance(max_bytes, bool) or max_bytes < 1:
        raise ValueError("Scene JSON limit must be a positive integer.")
    with Path(path).open("rb") as stream:
        raw = stream.read(max_bytes + 1)
    if len(raw) > max_bytes:
        raise ValueError(f"Scene JSON exceeds the {max_bytes}-byte metadata limit.")
    text = raw.decode("utf-8-sig")
    document = json.loads(text, parse_constant=invalid, object_pairs_hook=unique_object)
    validate_document(document)
    scene = Scene(document, Path(data_root).resolve())
    if "session_state" in document.get("metadata",{}):
        from .matlab_session import source_signature_matches
        scene.matlab_signature_verified=source_signature_matches(text,document["metadata"]["session_state"]["scene_signature"])
    if resolve: scene.resolve()
    return scene


def write_scene(scene, path):
    validate_document(scene.document)
    raw = json.dumps(scene.document, ensure_ascii=False, allow_nan=False, indent=2).encode("utf-8")
    if len(raw) > SCENE_JSON_LIMIT:
        raise ValueError("Scene JSON exceeds the metadata limit.")
    path = Path(path)
    temporary = None
    try:
        with NamedTemporaryFile(dir=path.parent, prefix=".bnv-json-", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def portable_scene(paths, settings, destination, base_document=None, session=None):
    """Copy selected files into an explicit data root, never constrain original paths."""
    destination = Path(destination).absolute()
    if os.path.lexists(destination): raise ValueError("Choose a new Scene filename; existing files are not overwritten.")
    asset_dir = destination.parent / (destination.stem + "_assets")
    if os.path.lexists(asset_dir): raise ValueError("The portable asset folder already exists.")
    document = {"schema_version": "0.1", "id": "PYTHON_SCENE", "name": destination.stem,
                "loadfile": 0, "map_mode": 0, "coordinate_space": "mixed-or-unverified",
                "redistribution_status": "user-supplied", "inputs": {},
                "options": {"visualization_settings": deepcopy(settings)}, "metadata": {}}
    if base_document is not None:
        for key,value in base_document.items():
            if key not in ("inputs","loadfile","map_mode","options"): document[key]=deepcopy(value)
        document["metadata"] = deepcopy(base_document.get("metadata", {}))
        document["options"] = deepcopy(base_document.get("options", {}))
        document["options"]["visualization_settings"] = deepcopy(settings)
    document["metadata"].pop(KEY, None)  # never silently carry a stale Python camera
    for role, filename in paths.items():
        if role not in ROLES: raise ValueError("Unsupported asset role.")
        source = Path(filename).resolve()
        if not source.is_file(): raise ValueError(f"Missing asset: {source}")
        document["inputs"][role] = {"role": role, "relative_path": f"{asset_dir.name}/{role}/{source.name}",
            "sha256": sha256(source), "coordinate_space": "unknown", "source_uri": "",
            "redistribution_status": "user-supplied", "metadata": {}}
        if base_document and role in base_document.get("inputs", {}):
            old = base_document["inputs"][role]
            for key in ("coordinate_space", "source_uri", "redistribution_status", "metadata"):
                if key in old: document["inputs"][role][key] = deepcopy(old[key])
        document["inputs"][role]["metadata"]["python_bundle_sha256"] = content_hash(source)
        document["loadfile"] |= ROLES[role]
    document["map_mode"] = 2 if "volume" in paths else 1 if "surface_map" in paths else 0
    if session is not None:
        session = validate_session(session)
        camera = session["camera"] if session["scene_signature"] == document_signature(document) else None
        attach_session(document,camera,session["export"])
    validate_document(document)
    # Preflight dependencies before creating anything.
    copies = []
    for role, filename in paths.items():
        source = Path(filename).resolve()
        dependencies = gifti_dependencies(source) if source.suffix.lower() == ".gii" else []
        if source.suffix.lower() in (".hdr", ".img"):
            dependencies.append(source.with_suffix(".img" if source.suffix.lower() == ".hdr" else ".hdr"))
        for dependency in [source, *dependencies]:
            if not dependency.is_file(): raise ValueError(f"Missing paired asset: {dependency}")
            relative = dependency.relative_to(source.parent)
            copies.append((dependency, asset_dir / role / relative))
    # Stage under the destination filesystem. Reserve the final directory using
    # mkdir (no replacement), then publish the complete JSON without overwriting.
    # The two paths are not a single crash-atomic transaction; JSON is committed last.
    owned_identity = None
    committed = False
    with TemporaryDirectory(prefix=".bnv-scene-", dir=destination.parent) as temporary:
        stage = Path(temporary)
        try:
            for source, target in copies:
                staged = stage / target.relative_to(destination.parent)
                staged.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, staged)
            staged_scene = Scene(document, stage)
            staged_scene.resolve()  # Detect source changes and paired/external corruption.
            staged_json = stage / "Scene.json"
            write_scene(staged_scene, staged_json)
            asset_dir.mkdir()  # Exclusive reservation; pre-existing paths remain untouched.
            info = asset_dir.stat()
            owned_identity = (info.st_dev, info.st_ino)
            for child in (stage / asset_dir.name).iterdir():
                child.rename(asset_dir / child.name)
            scene = Scene(document, destination.parent)
            scene.resolve()
            os.link(staged_json, destination)  # Atomic, complete, no-clobber JSON commit.
            committed = True
            return scene
        finally:
            if not committed and owned_identity is not None and asset_dir.is_dir() and not asset_dir.is_symlink():
                info = asset_dir.stat()
                if (info.st_dev, info.st_ino) == owned_identity:
                    shutil.rmtree(asset_dir)

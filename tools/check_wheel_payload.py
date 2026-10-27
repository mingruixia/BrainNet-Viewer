# SPDX-License-Identifier: GPL-3.0-or-later
"""Verify packaged sources/data against build inputs without executing the wheel."""
import hashlib
from pathlib import Path
import re
import sys
from zipfile import ZipFile


def matlab_display_version(version):
    """Map supported canonical Python versions to the public MATLAB spelling."""
    number = r"(?:0|[1-9][0-9]*)"
    pattern = (rf"(?P<base>{number}\.{number}\.{number})"
               rf"(?:b(?P<beta>{number})(?:\.post(?P<post>{number}))?)?")
    match = re.fullmatch(pattern, version)
    if match is None:
        raise ValueError(
            f"Unsupported Python version {version!r}; expected X.Y.Z or X.Y.ZbN[.postN]."
        )
    display = match["base"]
    if match["beta"] is not None:
        display += "-beta." + match["beta"]
        if match["post"] is not None:
            display += "+post" + match["post"]
    return display


def verify_wheel_payload(wheel_path, source_root=None):
    root = (Path(source_root) if source_root is not None else
            Path(__file__).resolve().parents[1] / "src/python")
    with ZipFile(wheel_path) as archive:
        paths = [name for name in archive.namelist()
                 if name.startswith("brainnet_viewer/") and not name.endswith("/")]
        assert len(paths) == len(set(paths)), "Duplicate package payloads"
        assert "brainnet_viewer/web_security.py" in paths
        assert "brainnet_viewer/web_connection_client.js" in paths
        assert "brainnet_viewer/resources/Data/SurfTemplate/BrainMesh_ICBM152.nv" in paths
        for name in paths:
            assert "__pycache__" not in name and not name.endswith(".pyc")
            source = root / name
            assert source.is_file(), name
            assert (hashlib.sha256(source.read_bytes()).digest() ==
                    hashlib.sha256(archive.read(name)).digest()), name
        metadata = [name for name in archive.namelist()
                    if name.endswith(".dist-info/METADATA")]
        assert len(metadata) == 1, "Expected one wheel metadata document"
        text = archive.read(metadata[0]).decode("utf-8")
        version_match = re.search(
            r'^__version__\s*=\s*"([^"]+)"',
            (root / "brainnet_viewer/__init__.py").read_text(encoding="utf-8"),
            re.MULTILINE,
        )
        assert version_match, "Python source version is missing"
        version = version_match[1]
        project = (root / "pyproject.toml").read_text(encoding="utf-8")
        assert ('dynamic = ["version"]' in project and
                'attr = "brainnet_viewer.__version__"' in project)
        display = matlab_display_version(version)
        matlab = root.parents[1] / "src/matlab/BrainNetViewer/+brainnet/+app/productInfo.m"
        assert re.search(
            r"'version',\s*'" + re.escape(display) + "'",
            matlab.read_text(encoding="utf-8"),
        ), "MATLAB/Python version mismatch"
        assert f"Version: {version}" in text.splitlines(), "Wheel/Python version mismatch"
        assert "License-Expression: GPL-3.0-or-later" in text, "Wheel license expression mismatch"
    return len(paths)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: check_wheel_payload.py WHEEL")
    count = verify_wheel_payload(sys.argv[1])
    print(f"Wheel payloads verified: {count}")

# SPDX-License-Identifier: GPL-3.0-or-later
"""Verify packaged sources/data against build inputs without executing the wheel."""
import hashlib
from pathlib import Path
import sys
from zipfile import ZipFile
import re

root = Path(__file__).resolve().parents[1] / "src/python"
with ZipFile(sys.argv[1]) as archive:
    paths = [name for name in archive.namelist() if name.startswith("brainnet_viewer/") and not name.endswith("/")]
    assert len(paths) == len(set(paths))
    assert "brainnet_viewer/web_security.py" in paths
    assert "brainnet_viewer/resources/Data/SurfTemplate/BrainMesh_ICBM152.nv" in paths
    for name in paths:
        assert "__pycache__" not in name and not name.endswith(".pyc")
        source = root / name
        assert source.is_file(), name
        assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(archive.read(name)).digest(), name
    metadata = next(name for name in archive.namelist() if name.endswith(".dist-info/METADATA"))
    text = archive.read(metadata).decode()
    version = re.search(r'^version\s*=\s*"([^"]+)"', (root / "pyproject.toml").read_text(), re.MULTILINE).group(1)
    assert f"Version: {version}" in text.splitlines()
    assert "License-Expression: GPL-3.0-or-later" in text
print(f"Wheel payloads verified: {len(paths)}")

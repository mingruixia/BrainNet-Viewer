# SPDX-License-Identifier: GPL-3.0-or-later
"""Small public regression set; no large data, GUI or full-suite dependency."""
from copy import deepcopy
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile, ZipInfo
import numpy as np
from defusedxml.common import EntitiesForbidden
from brainnet_viewer.io import read_nodes, read_edges, read_surface, resolve_asset, gifti_dependencies
from brainnet_viewer.scene import read_scene, portable_scene, write_scene, validate_document
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.network import select_edges
from brainnet_viewer.web_security import permitted

FIX = Path(__file__).resolve().parents[1] / "fixtures/cross-platform-v0.1"


class ReviewCoreTests(unittest.TestCase):
    def test_geometry_and_labels(self):
        oracle = json.loads((FIX / "oracles.json").read_text(encoding="utf-8"))
        mesh = read_surface(FIX / "tetrahedron.nv")
        np.testing.assert_array_equal(mesh.points, oracle["surface"]["vertices"])
        np.testing.assert_array_equal(mesh.faces, oracle["surface"]["faces_zero_based"])
        self.assertEqual(read_nodes(FIX / "three.node").labels, ["Left region", "Right region", "中线 Midline"])

    def test_node_hash_comments(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "nodes.node"
            path.write_text("# comment\n0 0 0 1 2 Network#1_PFC # comment\n1 2 3 2 1 中线 Midline\n", encoding="utf-8")
            self.assertEqual(read_nodes(path).labels, ["Network#1_PFC", "中线 Midline"])

    def test_directed_oracles(self):
        oracle = json.loads((FIX / "oracles.json").read_text(encoding="utf-8"))
        for case in oracle["edge_cases"]:
            settings = deepcopy(DEFAULTS["edge"])
            settings.update(case, selection_mode=case["mode"])
            pairs, values = select_edges(oracle["matrix"], settings)
            np.testing.assert_array_equal(pairs, np.asarray(case["pairs_zero_based"]).reshape(-1, 2))
            np.testing.assert_array_equal(values, case["values"])

    def test_invalid_numerical_inputs(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "bad.edge"
            for text in ("1 2 3\n4 5 6\n", "0 NaN\n1 0\n", "0 inf\n1 0\n"):
                path.write_text(text)
                with self.assertRaises(ValueError): read_edges(path)
            with self.assertRaises(ValueError): read_edges(FIX / "directed.edge", 2)
            mesh = Path(temp) / "bad.nv"
            mesh.write_text("1\n0 0 0\n1\n1 2 3\n")
            with self.assertRaises(ValueError): read_surface(mesh)

    def test_scene_size_duplicate_nonfinite(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "scene.json"
            path.write_bytes((FIX / "scene-minimal.json").read_bytes())
            self.assertEqual(read_scene(path, FIX).document["schema_version"], "0.1")
            with self.assertRaisesRegex(ValueError, "limit"): read_scene(path, FIX, max_bytes=16)
            for bad in ('{"schema_version":"0.1","schema_version":"0.1"}', '{"x":NaN}'):
                path.write_text(bad)
                with self.assertRaises(ValueError): read_scene(path, FIX, resolve=False)

    def test_path_syntax(self):
        document = json.loads((FIX / "scene-minimal.json").read_text())
        for bad in ("../x", "/x", "C:/x", "a\\b", "\x00"):
            doc = deepcopy(document)
            doc["inputs"]["surface"]["relative_path"] = bad
            with self.assertRaises(ValueError): validate_document(doc)
    def test_real_symlink_guard_independent_of_cwd(self):
        document = json.loads((FIX / "scene-minimal.json").read_text())
        with tempfile.TemporaryDirectory() as temp, tempfile.TemporaryDirectory() as outside:
            root = Path(temp)
            link = root / "elsewhere"
            try: link.symlink_to(outside, target_is_directory=True)
            except OSError: self.skipTest("Symlink permission unavailable; Linux CI covers this.")
            document["inputs"]["surface"]["relative_path"] = "elsewhere/mesh.nv"
            previous = Path.cwd()
            try:
                os.chdir(root)
                validate_document(document)
                with self.assertRaisesRegex(ValueError, "escapes"): resolve_asset(root, "elsewhere/mesh.nv")
            finally: os.chdir(previous)

    def test_scene_save_roundtrip_and_no_clobber(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "portable.json"
            saved = portable_scene({"surface": FIX / "tetrahedron.nv", "node": FIX / "three.node"}, DEFAULTS, path)
            opened = read_scene(path, path.parent)
            self.assertEqual(saved.document, opened.document)
            before = path.read_bytes()
            with self.assertRaises(ValueError): portable_scene({"surface": FIX / "tetrahedron.nv"}, DEFAULTS, path)
            self.assertEqual(before, path.read_bytes())
            self.assertFalse(any(p.name.startswith(".bnv-") for p in path.parent.iterdir()))

    def test_copy_failure_rolls_back(self):
        import shutil
        copy = shutil.copy2
        count = 0
        def fail_second(*args, **kwargs):
            nonlocal count
            count += 1
            if count == 2: raise OSError("synthetic second-copy failure")
            return copy(*args, **kwargs)
        with tempfile.TemporaryDirectory() as temp, patch("brainnet_viewer.scene.shutil.copy2", side_effect=fail_second):
            with self.assertRaisesRegex(OSError, "second-copy"):
                portable_scene({"surface": FIX / "tetrahedron.nv", "node": FIX / "three.node"}, DEFAULTS, Path(temp) / "test.json")
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_commit_failure_preserves_existing_target(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "test.json"
            def collision(_source, target):
                Path(target).write_text("other user's file")
                raise FileExistsError("synthetic collision")
            with patch("brainnet_viewer.scene.os.link", side_effect=collision):
                with self.assertRaises(FileExistsError): portable_scene({"surface": FIX / "tetrahedron.nv"}, DEFAULTS, path)
            self.assertEqual(path.read_text(), "other user's file")
            self.assertEqual([p.name for p in Path(temp).iterdir()], ["test.json"])

    def test_atomic_json_failure_preserves_old_file(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "saved.json"
            path.write_text("existing")
            scene = read_scene(FIX / "scene-minimal.json", FIX)
            with patch("brainnet_viewer.scene.os.replace", side_effect=OSError("commit failed")):
                with self.assertRaises(OSError): write_scene(scene, path)
            self.assertEqual(path.read_text(), "existing")
            self.assertEqual([p.name for p in Path(temp).iterdir()], ["saved.json"])

    def test_xml_entities_rejected_valid_external_array_retained(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "test.gii"
            path.write_text('<!DOCTYPE GIFTI [<!ENTITY x "small">]><GIFTI>&x;</GIFTI>')
            with self.assertRaises(EntitiesForbidden): gifti_dependencies(path)
            (Path(temp) / "values.bin").write_bytes(b"1234")
            path.write_text('<!DOCTYPE GIFTI SYSTEM "http://example.invalid/gifti.dtd"><GIFTI><DataArray ExternalFileName="values.bin"/></GIFTI>')
            self.assertEqual(gifti_dependencies(path), [Path(temp) / "values.bin"])

    def test_origin_and_authority_policy(self):
        for host in ("127.0.0.1:1054", "localhost:1054", "[::1]:1054"):
            self.assertTrue(permitted(host, "http://" + host, require_origin=True))
            self.assertTrue(permitted(host, None))
            self.assertFalse(permitted(host, None, require_origin=True))
            for origin in ("null", "https://" + host, "http://evil.invalid", "http://127.0.0.1:1055"):
                self.assertFalse(permitted(host, origin, require_origin=True))
        for host in ("evil.invalid:1054", "localhost.evil.invalid:1054", "user@localhost:1054", "localhost:99999", "localhost:1054/path"):
            self.assertFalse(permitted(host, None))

    def test_zip_and_upload_guards(self):
        from brainnet_viewer.web_workspace import WebWorkspace
        from brainnet_viewer.web_assets import upload_files, open_bundle, save_bundle
        workspace = WebWorkspace()
        try:
            for names in (("A.node", "a.node"), ("../x.node",), ("x.node",) * 17):
                with self.assertRaises(ValueError): upload_files(workspace, [(name, b"x") for name in names])
                self.assertEqual(list(workspace.assets.iterdir()), [])
            for name in ("../x.json", "/x.json", "C:/x.json", "a\\x.json"):
                data = io.BytesIO()
                with ZipFile(data, "w") as archive: archive.writestr(name, "{}")
                with self.assertRaises(ValueError): open_bundle(workspace, "Scene.zip", data.getvalue())
                self.assertEqual(list(workspace.assets.iterdir()), [])
            data = io.BytesIO()
            with ZipFile(data, "w") as archive:
                entry = ZipInfo("link.json"); entry.create_system = 3; entry.external_attr = 0o120777 << 16
                archive.writestr(entry, "../file")
            with self.assertRaises(ValueError): open_bundle(workspace, "Scene.zip", data.getvalue())
            for names in (("Scene.json", "scene.json"), tuple(f"{i}.json" for i in range(65))):
                data = io.BytesIO()
                with ZipFile(data, "w") as archive:
                    for name in names: archive.writestr(name, "{}")
                with self.assertRaises(ValueError): open_bundle(workspace, "Scene.zip", data.getvalue())
                self.assertEqual(list(workspace.assets.iterdir()), [])
            with patch("brainnet_viewer.web_assets.FILE_LIMIT", 2):
                with self.assertRaises(ValueError): upload_files(workspace, [("test.node", b"123")])
            with patch("brainnet_viewer.web_assets.SESSION_LIMIT", 2):
                with self.assertRaises(ValueError): upload_files(workspace, [("test.node", b"123")])
            workspace.paths = {"surface": FIX / "tetrahedron.nv"}
            payload = save_bundle(workspace, DEFAULTS)
            open_bundle(workspace, "Scene.zip", payload)
            np.testing.assert_array_equal(read_surface(workspace.paths["surface"]).points, read_surface(FIX / "tetrahedron.nv").points)
        finally: workspace.close()


if __name__ == "__main__": unittest.main()

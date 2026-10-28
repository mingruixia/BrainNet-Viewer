"""Unsupported MATLAB host paths must not become server or desktop inputs."""
from copy import deepcopy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import uuid
from zipfile import ZipFile

from brainnet_viewer.scene import read_scene, portable_scene
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.web_assets import open_bundle
from brainnet_viewer.web_workspace import WebWorkspace

FIXTURE = Path(__file__).resolve().parents[1] / "fixtures/cross-platform-v0.1"


def local_document(path):
    document = json.loads((FIXTURE / "scene-minimal.json").read_text(encoding="utf-8"))
    document["inputs"]["surface"]["local_path"] = path
    return document


class LocalSceneReferenceTests(unittest.TestCase):
    def test_rejects_host_references_before_any_asset_lookup(self):
        for value in ("/Users/private-study/subject/mesh.nv",
                      "C:\\Users\\private-study\\mesh.nv", "\\\\server\\subject\\mesh.nv", "", None):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as folder:
                path = Path(folder) / "local.json"
                path.write_text(json.dumps(local_document(value)), encoding="utf-8")
                for resolve in (True, False):
                    with patch("brainnet_viewer.scene.resolve_asset") as lookup:
                        with self.assertRaisesRegex(ValueError, "MATLAB local-file references") as caught:
                            read_scene(path, FIXTURE, resolve=resolve)
                        lookup.assert_not_called()
                        self.assertNotIn("private-study", str(caught.exception))
                        self.assertNotIn("Missing surface", str(caught.exception))

    def test_existing_relative_and_python_portable_scenes_still_resolve(self):
        original = read_scene(FIXTURE / "scene-minimal.json", FIXTURE)
        self.assertEqual(original.paths["surface"], (FIXTURE / "tetrahedron.nv").resolve())
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / "portable.json"
            portable_scene({"surface": FIXTURE / "tetrahedron.nv"}, DEFAULTS, target)
            restored = read_scene(target, target.parent)
            self.assertEqual(restored.paths["surface"].read_bytes(), (FIXTURE / "tetrahedron.nv").read_bytes())

    def test_web_json_and_zip_rejection_preserve_current_workspace(self):
        workspace = WebWorkspace()
        try:
            surface = next(key for key in workspace.catalog["surface"] if key.endswith("BrainMesh_ICBM152.nv"))
            workspace.select({"surface": surface})
            workspace.configure({"image": {"title": "Keep current Scene"}})
            workspace.pending_session = {"unchanged": True}
            before = (dict(workspace.paths), deepcopy(workspace.settings),
                      deepcopy(workspace.catalog), deepcopy(workspace.pending_session))
            raw = json.dumps(local_document("/Users/private-study/mesh.nv")).encode()
            stream = io.BytesIO()
            with ZipFile(stream, "w") as archive:
                archive.writestr("scene.json", raw)
            for name, payload in (("local.json", raw), ("local.zip", stream.getvalue())):
                with self.subTest(name=name):
                    with self.assertRaisesRegex(ValueError, "MATLAB local-file references"):
                        open_bundle(workspace, name, payload)
                    self.assertEqual((workspace.paths, workspace.settings, workspace.catalog,
                                      workspace.pending_session), before)
                    self.assertEqual(list(workspace.assets.iterdir()), [])
        finally:
            workspace.close()

    def test_web_action_displays_error_without_replacing_scene(self):
        from trame.app import get_server
        from brainnet_viewer.web_app import create_app
        server, workspace, actions = create_app(get_server("local-ref-" + uuid.uuid4().hex, client_type="vue3"))
        try:
            server.state.scene_filename = "previous.scene.zip"
            before = deepcopy(workspace.settings)
            raw = json.dumps(local_document("/Users/private-study/mesh.nv")).encode()
            server.state.scene_files = [{"name": "local.json", "size": len(raw), "content": raw}]
            actions["open_scene"]()
            self.assertIn("MATLAB local-file references", server.state.error)
            self.assertNotIn("private-study", server.state.error)
            self.assertEqual(server.state.scene_filename, "previous.scene.zip")
            self.assertEqual(workspace.settings, before)
            self.assertEqual(list(workspace.assets.iterdir()), [])
        finally:
            actions["close"]()

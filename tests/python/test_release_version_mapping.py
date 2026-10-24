# SPDX-License-Identifier: GPL-3.0-or-later
"""Release mapping and wheel identity checks using bounded archive fixtures."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile

TOOL_PATH = Path(__file__).resolve().parents[2] / "tools/check_wheel_payload.py"
SPEC = importlib.util.spec_from_file_location("bnv_wheel_check", TOOL_PATH)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class ReleaseVersionMappingTests(unittest.TestCase):
    def make_fixture(self, folder, version="2.0.0", *, display=None,
                     metadata_version=None, tamper=False, license_expression="GPL-3.0-or-later"):
        project = Path(folder) / "project"
        root = project / "src/python"
        files = {
            "brainnet_viewer/__init__.py": (
                f'__version__ = "{version}"\n'
                'raise RuntimeError("Wheel package must never be executed by the checker")\n'
            ).encode(),
            "brainnet_viewer/web_security.py": b"# source identity fixture\n",
            "brainnet_viewer/resources/Data/SurfTemplate/BrainMesh_ICBM152.nv": b"fixture only\n",
        }
        for name, data in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        (root / "pyproject.toml").write_text(
            'dynamic = ["version"]\nattr = "brainnet_viewer.__version__"\n',
            encoding="utf-8",
        )
        matlab = project / "src/matlab/BrainNetViewer/+brainnet/+app/productInfo.m"
        matlab.parent.mkdir(parents=True, exist_ok=True)
        matlab.write_text(
            "'version', '" + (display if display is not None else
                              CHECK.matlab_display_version(version)) + "'",
            encoding="utf-8",
        )
        wheel = Path(folder) / "fixture.whl"
        with ZipFile(wheel, "w") as archive:
            for name, data in files.items():
                if tamper and name.endswith("web_security.py"):
                    data += b"# changed after build\n"
                archive.writestr(name, data)
            metadata = (
                "Metadata-Version: 2.4\nName: brainnet-viewer\n"
                f"Version: {metadata_version or version}\n"
                f"License-Expression: {license_expression}\n"
            )
            archive.writestr(f"brainnet_viewer-{version}.dist-info/METADATA", metadata)
        return root, wheel

    def test_formal_beta_and_post_display_mappings(self):
        expected = {
            "2.0.0": "2.0.0",
            "3.14.1": "3.14.1",
            "2.0.0b1": "2.0.0-beta.1",
            "2.0.0b1.post2": "2.0.0-beta.1+post2",
            "2.0.0b0.post0": "2.0.0-beta.0+post0",
        }
        for version, display in expected.items():
            with self.subTest(version=version):
                self.assertEqual(CHECK.matlab_display_version(version), display)

    def test_unknown_or_noncanonical_schemes_are_rejected(self):
        for version in ("", "v2.0.0", "2.0", "2.00.0", "2.0.0b01",
                        "2.0.0-beta.1", "2.0.0rc1", "2.0.0.dev1",
                        "2.0.0.post1", "2.0.0+custom"):
            with self.subTest(version=version):
                with self.assertRaisesRegex(ValueError, "Unsupported Python version"):
                    CHECK.matlab_display_version(version)

    def test_complete_formal_beta_and_post_archives_without_executing_package(self):
        for version in ("2.0.0", "2.0.0b1", "2.0.0b1.post2"):
            with self.subTest(version=version), tempfile.TemporaryDirectory() as folder:
                root, wheel = self.make_fixture(folder, version)
                self.assertEqual(CHECK.verify_wheel_payload(wheel, root), 3)

    def test_matlab_and_wheel_version_mismatches_fail(self):
        for kwargs, message in (
            ({"display": "2.0.0-beta.1"}, "MATLAB/Python version mismatch"),
            ({"metadata_version": "2.0.1"}, "Wheel/Python version mismatch"),
        ):
            with self.subTest(kwargs=kwargs), tempfile.TemporaryDirectory() as folder:
                root, wheel = self.make_fixture(folder, **kwargs)
                with self.assertRaisesRegex(AssertionError, message):
                    CHECK.verify_wheel_payload(wheel, root)

    def test_payload_and_license_guards_remain_active(self):
        for kwargs, message in (
            ({"tamper": True}, "web_security.py"),
            ({"license_expression": "MIT"}, "Wheel license expression mismatch"),
        ):
            with self.subTest(kwargs=kwargs), tempfile.TemporaryDirectory() as folder:
                root, wheel = self.make_fixture(folder, **kwargs)
                with self.assertRaisesRegex(AssertionError, message):
                    CHECK.verify_wheel_payload(wheel, root)

    def test_formal_fixture_through_existing_cli_entry(self):
        with tempfile.TemporaryDirectory() as folder:
            root, wheel = self.make_fixture(folder)
            tool = root.parents[1] / "tools/check_wheel_payload.py"
            tool.parent.mkdir(parents=True)
            tool.write_bytes(TOOL_PATH.read_bytes())
            result = subprocess.run(
                [sys.executable, str(tool), str(wheel)],
                capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Wheel payloads verified: 3", result.stdout)


if __name__ == "__main__":
    unittest.main()

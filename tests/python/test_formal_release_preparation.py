# SPDX-License-Identifier: GPL-3.0-or-later
"""Targeted release planning/payload guards; never build application candidates."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import warnings
from zipfile import ZipFile

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(REPO/"tools"))
SPEC=importlib.util.spec_from_file_location("formal_prepare",REPO/"tools/prepare_formal_release.py")
TOOL=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOL)

class FormalPreparationTests(unittest.TestCase):
    def test_modern_archive_allowlists_and_web_aliases(self):
        files=set(TOOL.ROOT_FILES)|set(TOOL.WEB_FILES.values())|{
            "BrainNetViewer.m","BrainNetRender.m","src/matlab/BrainNetViewer/core.m",
            "resources/atlases/AAL90/aal.nii","docs/manual/en/"+TOOL.MANUAL_STEM+".docx",
            "docs/tutorials/assets/demo.png","legacy/old.m","research/fiber.py",
            "docs/internal/private.md","docs/manual/en/Old.docx","tmp/secret.txt",
            ".server-secrets/server.key","docs/web/secret.pem","tests/python/test.py"}
        matlab=TOOL.archive_inputs(files,"MATLAB")
        self.assertIn("BrainNetViewer.m",matlab)
        self.assertIn("resources/atlases/AAL90/aal.nii",matlab)
        for key in ("legacy/old.m","research/fiber.py","docs/internal/private.md",
                    "docs/manual/en/Old.docx","tmp/secret.txt",".server-secrets/server.key","docs/web/secret.pem"):
            self.assertNotIn(key,matlab)
        web=TOOL.archive_inputs(files,"Web")
        self.assertEqual(web["start_web.sh"],"tools/start_web.sh")
        self.assertEqual(web["start_web.ps1"],"tools/manage_brainnet_web.ps1")
        self.assertIn("compose.web.server.release.yml",web)
        self.assertNotIn("BrainNetViewer.m",web)

    def test_unsafe_and_missing_inputs_fail(self):
        for value in ("../x","/tmp/x",r"docs\a.md","docs/internal/a.md",
                      ".venv-bnv/a","docs/.server-secrets/a","a:stream"):
            self.assertFalse(TOOL.safe_path(value),value)
        with self.assertRaisesRegex(ValueError,"untracked"):
            TOOL.archive_inputs(set(TOOL.ROOT_FILES),"Web")

    def fixture(self,folder,*,missing=None,extra=False,tamper=False):
        repo=Path(folder)/"repo";src=repo/"src/python"
        files={"brainnet_viewer/__init__.py":b'__version__ = "2.0.0"\n',
               "brainnet_viewer/web_security.py":b"# fixture\n",
               "brainnet_viewer/web_connection_client.js":b"// cleanup client fixture\n",
               "brainnet_viewer/resources/Data/SurfTemplate/BrainMesh_ICBM152.nv":b"mesh",
               "brainnet_viewer/resources/fonts/NOTICE.txt":b"font license fixture"}
        for name,data in files.items():
            p=src/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        (src/"pyproject.toml").write_text(
            'dynamic = ["version"]\nattr = "brainnet_viewer.__version__"\n'
            '[tool.setuptools.package-data]\nbrainnet_viewer = ["web_connection_client.js","resources/Data/SurfTemplate/*.nv","resources/fonts/*.txt"]\n',
            encoding="utf-8")
        matlab=repo/"src/matlab/BrainNetViewer/+brainnet/+app/productInfo.m"
        matlab.parent.mkdir(parents=True)
        matlab.write_text("'version', '2.0.0'",encoding="utf-8")
        wheel=Path(folder)/"brainnet_viewer-2.0.0-py3-none-any.whl"
        with ZipFile(wheel,"w") as z:
            for name,data in files.items():
                if name!=missing:z.writestr(name,data+(b"tampered" if tamper and name.endswith("NOTICE.txt") else b""))
            if extra:z.writestr("brainnet_viewer/undeclared.bin",b"extra")
            z.writestr("brainnet_viewer-2.0.0.dist-info/METADATA",
                "Metadata-Version: 2.4\nVersion: 2.0.0\nRequires-Python: >=3.11\nLicense-Expression: GPL-3.0-or-later\n")
        return repo,wheel

    def test_expected_wheel_set_catches_missing_and_extra_data(self):
        for kwargs,valid in (({},True),({"missing":"brainnet_viewer/resources/fonts/NOTICE.txt"},False),
                             ({"missing":"brainnet_viewer/web_connection_client.js"},False),
                             ({"extra":True},False),({"tamper":True},False)):
            with self.subTest(kwargs=kwargs),tempfile.TemporaryDirectory() as folder:
                repo,wheel=self.fixture(folder,**kwargs)
                if valid:self.assertEqual(TOOL.verify_complete_wheel(repo,wheel,"2.0.0"),5)
                else:
                    with self.assertRaises((ValueError,AssertionError)):
                        TOOL.verify_complete_wheel(repo,wheel,"2.0.0")

    def test_duplicate_entries_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            repo,wheel=self.fixture(folder)
            with warnings.catch_warnings():
                warnings.simplefilter("ignore",UserWarning)
                with ZipFile(wheel,"a") as z:z.writestr("brainnet_viewer-2.0.0.dist-info/METADATA","duplicate")
            with self.assertRaises((ValueError,AssertionError)):
                TOOL.verify_complete_wheel(repo,wheel,"2.0.0")

    def test_document_links_retain_local_assets_and_pin_source_references(self):
        name="docs/web/en/guide.md"
        tracked={name,"docs/web/en/figure.png","src/matlab/BrainNetViewer/Data/a.node"}
        data=b"[node](../../../src/matlab/BrainNetViewer/Data/a.node)\n![image](figure.png)\n"
        revised,changes=TOOL.release_document(data,name,{name:None,"docs/web/en/figure.png":None},tracked,"abc123")
        self.assertIn(b"/blob/abc123/src/matlab/",revised)
        self.assertIn(b"![image](figure.png)",revised)
        self.assertEqual(len(changes),1)
        for data in (b"![image](missing.png)",b"[missing](missing.md)",b"[escape](../../../../x)"):
            with self.assertRaises(ValueError):
                TOOL.release_document(data,name,{name:None},tracked,"abc123")

    def test_plan_only_cli_leaves_output_untouched_and_missing_build_inputs_fail(self):
        with tempfile.TemporaryDirectory() as folder:
            dest=Path(folder)/"no-candidate"
            base=[sys.executable,str(REPO/"tools/prepare_formal_release.py"),
                  "--repo",str(REPO),"--version","2.0.0","--revision","preparation-only",
                  "--output",str(dest)]
            result=subprocess.run(base,text=True,capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr)
            plan=json.loads(result.stdout)
            self.assertFalse(plan["archives_written"])
            self.assertIsInstance(plan["blockers"],list)
            self.assertFalse(dest.exists())
            result=subprocess.run(base+["--write-archives"],text=True,capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(dest.exists())

    def test_cli_rejects_nonformal_version_without_outputs(self):
        with tempfile.TemporaryDirectory() as folder:
            dest=Path(folder)/"absent"
            result=subprocess.run([sys.executable,str(REPO/"tools/prepare_formal_release.py"),
                "--version","2.0.0b1","--revision","test","--output",str(dest)],
                capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(dest.exists())

if __name__=="__main__":unittest.main()

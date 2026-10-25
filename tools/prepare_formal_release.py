# SPDX-License-Identifier: GPL-3.0-or-later
"""Plan a formal release; archives require an explicit --write-archives."""
import argparse
from email.parser import Parser
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tomllib
from zipfile import ZipFile, ZIP_DEFLATED

ROOT_FILES = {
    "README.md", "README.zh-CN.md", "CHANGELOG.md", "CHANGELOG.zh-CN.md",
    "CITATION.cff", "LICENSE", "LICENSE_MATPLOTLIB_COLORMAPS.txt",
    "NOTICE_ATLAS_NETWORK_EXAMPLES.md", "NOTICE_CODE.md", "NOTICE_INSPECT_ATLASES.md",
    "NOTICE_NETWORK_EXAMPLES.md", "NOTICE_SURFACE_TEMPLATES.md", "NOTICE_TUTORIAL_ASSETS.md",
    "SECURITY.md",
}
DOC_PREFIXES = ("docs/manual/", "docs/tutorials/", "docs/documentation/",
                "docs/python/", "docs/web/", "docs/compatibility/Surface_Format_Support.md")
FORBIDDEN = {"research", "legacy", "archives", "releases", "tmp", ".git", ".server-secrets",
             "__pycache__", "internal", "architecture"}
WEB_FILES = {
    "compose.web.release.yml": "src/python/compose.web.release.yml",
    "compose.web.server.release.yml": "src/python/compose.web.server.release.yml",
    "start_web.ps1": "tools/manage_brainnet_web.ps1",
    "start_web.sh": "tools/start_web.sh",
}
MANUAL_STEM = "BrainNet_Viewer_2_Unified_User_Manual_EN"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()

def safe_path(name):
    path = PurePosixPath(name)
    return (not path.is_absolute() and "\\" not in name and ":" not in name
            and ".." not in path.parts and not (set(path.parts) & FORBIDDEN)
            and not name.endswith((".pyc", ".pyo", ".server.env", ".key"))
            and not any(part.startswith(".venv") for part in path.parts))

def allowed_doc(name):
    if not safe_path(name) or not name.startswith(DOC_PREFIXES):
        return False
    if PurePosixPath(name).suffix.lower() not in {
        ".md", ".txt", ".png", ".jpg", ".jpeg", ".svg", ".json", ".csv",
        ".docx", ".pdf",
    }:
        return False
    if name.endswith((".docx", ".pdf")):
        return name in {f"docs/manual/en/{MANUAL_STEM}.docx", f"docs/manual/en/{MANUAL_STEM}.pdf"}
    return True

def archive_inputs(tracked, edition):
    """Explicit modern-package allowlist; legacy remains in the source repo."""
    common = {p: p for p in tracked if p in ROOT_FILES or allowed_doc(p)}
    if edition == "MATLAB":
        common.update({p: p for p in tracked if safe_path(p) and
                       (p.startswith(("src/matlab/BrainNetViewer/", "resources/atlases/"))
                        or p in {"BrainNetViewer.m", "BrainNetRender.m"})})
    elif edition == "Web":
        common.update(WEB_FILES)
    elif edition != "Python":
        raise ValueError("Unknown edition")
    for target, source in common.items():
        if not safe_path(target) or source not in tracked:
            raise ValueError(f"Unsafe or untracked release input: {target}")
    return common

def expected_wheel_payload(repo):
    root = repo / "src/python"
    project = tomllib.loads((root / "pyproject.toml").read_text(encoding="utf-8"))
    package = root / "brainnet_viewer"
    paths = {p.relative_to(root).as_posix() for p in package.rglob("*.py")
             if "__pycache__" not in p.parts}
    for pattern in project["tool"]["setuptools"]["package-data"]["brainnet_viewer"]:
        paths.update(p.relative_to(root).as_posix() for p in package.glob(pattern) if p.is_file())
    return paths

def verify_complete_wheel(repo, wheel, version):
    """Check expected-vs-actual package sets and bytes, not only present files."""
    from check_wheel_payload import verify_wheel_payload
    verify_wheel_payload(wheel, repo / "src/python")
    expected = expected_wheel_payload(repo)
    with ZipFile(wheel) as z:
        names = z.namelist()
        if len(names) != len(set(names)) or any(not safe_path(p.rstrip("/")) for p in names):
            raise ValueError("Duplicate or unsafe wheel entries")
        actual = {p for p in names if p.startswith("brainnet_viewer/") and not p.endswith("/")}
        if expected != actual:
            raise ValueError(f"Wheel file set differs: missing={sorted(expected-actual)} extra={sorted(actual-expected)}")
        metadata = Parser().parsestr(z.read(f"brainnet_viewer-{version}.dist-info/METADATA").decode("utf-8"))
        if metadata["Version"] != version or metadata["Requires-Python"] != ">=3.11":
            raise ValueError("Wheel version or minimum Python does not match")
        if metadata["License-Expression"] != "GPL-3.0-or-later":
            raise ValueError("Wheel license mismatch")
        for name in expected:
            if z.read(name) != (repo / "src/python" / name).read_bytes():
                raise ValueError("Wheel/source bytes differ: " + name)
    return len(expected)

def candidate_blockers(repo, version, dirty):
    problems = []
    if dirty:
        problems.append("Source worktree is not clean")
    init = (repo / "src/python/brainnet_viewer/__init__.py").read_text(encoding="utf-8")
    matlab = (repo / "src/matlab/BrainNetViewer/+brainnet/+app/productInfo.m").read_text(encoding="utf-8")
    project = (repo / "src/python/pyproject.toml").read_text(encoding="utf-8")
    if not re.search(r'__version__\s*=\s*"' + re.escape(version) + r'"', init):
        problems.append("Python source version is not the requested formal version")
    if not re.search(r"'version',\s*'" + re.escape(version) + "'", matlab):
        problems.append("MATLAB source version is not the requested formal version")
    build_date = re.search(r"'build_date',\s*'([^']*)'", matlab)
    if build_date is None or not build_date[1].strip():
        problems.append("MATLAB candidate build date is not set")
    if "Development Status :: 5 - Production/Stable" not in project:
        problems.append("Package classifier remains pre-release")
    for text in ("Public beta", "Source maintenance update"):
        if text in matlab:
            problems.append("MATLAB release metadata still contains " + text)
    web = (repo / "src/python/brainnet_viewer/web_shell.py").read_text(encoding="utf-8")
    if "Public Beta 1" in web or "Web development" in web:
        problems.append("Web UI still contains beta/development wording")
    compose = (repo / "src/python/compose.web.release.yml").read_text(encoding="utf-8")
    image = "mingruixia/brainnet-viewer:" + version
    if not re.search(r"image:\s*(?:" + re.escape(image) + r"\s*$|\$\{BNV_IMAGE:-" +
                     re.escape(image) + r"\}\s*$)", compose, re.MULTILINE):
        problems.append("Docker release image tag does not match")
    from xml.etree import ElementTree as ET
    manual = repo / f"docs/manual/en/{MANUAL_STEM}.docx"
    with ZipFile(manual) as z:
        tree = ET.fromstring(z.read("word/document.xml"))
        text = " ".join(n.text or "" for n in tree.iter(
            "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t"))
    if f"Version {version}" not in text or "py -3.10" in text or "2.0.0b1" in text:
        problems.append("Canonical manual has not been updated to the formal version")
    return problems

LINK = re.compile(r'(!?)\[([^\]]+)\]\(([^)]+)\)')
def release_document(data, name, included, tracked, commit):
    """Keep local illustrated assets; source-only links use the exact commit."""
    changes = []
    def rewrite(match):
        prefix, label, target = match.groups()
        if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith("#"):
            return match.group(0)
        from urllib.parse import unquote, quote
        plain, _, fragment = target.partition("#")
        # Normalize without using the host filesystem or accepting an escape.
        parts = list(PurePosixPath(name).parent.parts)
        for part in unquote(plain.strip("<>")).split("/"):
            if part == "..":
                if not parts:
                    raise ValueError(f"Document link escapes root: {name}: {target}")
                parts.pop()
            elif part not in ("", "."):
                parts.append(part)
        resolved = "/".join(parts)
        if resolved in included:
            return match.group(0)
        if prefix:
            raise ValueError(f"Illustrated asset not in archive: {name}: {target}")
        if resolved not in tracked:
            raise ValueError(f"Broken source link: {name}: {target}")
        url = "https://github.com/mingruixia/BrainNet-Viewer/blob/" + commit + "/" + quote(resolved)
        if fragment:
            url += "#" + fragment
        changes.append({"target":target, "release_target":url})
        return f"[{label}]({url})"
    return LINK.sub(rewrite, data.decode("utf-8")).encode("utf-8"), changes

def write_archive(destination, edition, inputs, repo, commit, version, tracked, wheel=None):
    manifest, transforms = [], []
    with ZipFile(destination, "x", compression=ZIP_DEFLATED, compresslevel=9) as z:
        for target, source in sorted(inputs.items()):
            file = wheel if source == "@wheel" else repo / source
            if file.is_symlink():
                raise ValueError("Symlink release input: " + source)
            data = file.read_bytes()
            if target.endswith(".md"):
                data, changed = release_document(data, target, inputs, tracked, commit)
                if changed:
                    transforms.append({"path":target, "links":changed})
            z.writestr(target, data)
            manifest.append({"path":target,"bytes":len(data),"sha256":digest(data)})
        z.writestr("PACKAGE_IDENTITY.json", json.dumps({
            "version":version,"edition":edition,"source_commit":commit,"files":manifest
        },indent=2))
    with ZipFile(destination) as z:
        if z.testzip() is not None:
            raise ValueError("Archive CRC failed")
        if set(z.namelist()) != set(inputs) | {"PACKAGE_IDENTITY.json"}:
            raise ValueError("Archive contains missing/extra entries")
        for item in manifest:
            if digest(z.read(item["path"])) != item["sha256"]:
                raise ValueError("Archive payload mismatch")
    return transforms

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--output", required=True, type=Path, help="New directory; untouched in plan mode")
    parser.add_argument("--wheel", type=Path)
    parser.add_argument("--release-notes", type=Path)
    parser.add_argument("--write-archives", action="store_true", help="Explicitly create archives; never builds a wheel/image")
    args = parser.parse_args(argv)
    if not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", args.version):
        parser.error("Formal version must be canonical X.Y.Z")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", args.revision):
        parser.error("Invalid revision identifier")
    repo = args.repo.resolve()
    tracked = set(git(repo, "ls-files").splitlines())
    pending = set(git(repo, "ls-files", "--others", "--exclude-standard").splitlines())
    head = git(repo, "rev-parse", "HEAD")
    dirty = git(repo, "status", "--porcelain")
    # Plan mode may inventory new, uncommitted release inputs. Writing still
    # requires a completely clean commit; no untracked file can enter a build.
    mappings = {edition:archive_inputs(tracked | pending,edition) for edition in ("MATLAB","Python","Web")}
    blockers = candidate_blockers(repo,args.version,dirty)
    link_errors = []
    for edition, mapping in mappings.items():
        for name, source in mapping.items():
            if name.endswith(".md"):
                try:
                    release_document((repo/source).read_bytes(),name,mapping,tracked | pending,head)
                except ValueError as error:
                    link_errors.append({"edition":edition,"path":name,"error":str(error)})
    if link_errors:
        blockers.append("Archive documentation has unresolved local links")
    plan = {"version":args.version,"candidate_revision":args.revision,"source_commit":head,
            "clean_worktree":not bool(dirty),"published":False,"archives_written":False,
            "blockers":blockers,"documentation_link_errors":link_errors,"untracked_inputs":sorted(pending),
            "editions":{k:{"count":len(v),"inputs":v} for k,v in mappings.items()}}
    if not args.write_archives:
        print(json.dumps(plan,indent=2))
        return 0
    if blockers:
        raise ValueError("; ".join(blockers))
    if args.output.resolve().is_relative_to(repo):
        raise ValueError("Output must be outside the source checkout")
    if not args.wheel or args.wheel.name != f"brainnet_viewer-{args.version}-py3-none-any.whl":
        raise ValueError("Supply the exact independently built formal wheel")
    if not args.release_notes or not args.release_notes.is_file():
        raise ValueError("Supply the reviewed release notes")
    if b"\r" in (repo / "tools/start_web.sh").read_bytes():
        raise ValueError("POSIX launcher must use LF line endings")
    verify_complete_wheel(repo,args.wheel,args.version)
    # Reserve a new directory only after every input and document link passes.
    mappings["Python"][args.wheel.name] = "@wheel"
    for mapping in mappings.values():
        for name,source in mapping.items():
            if name.endswith(".md"):
                release_document((repo/source).read_bytes(),name,mapping,tracked,head)
    args.output.mkdir(parents=True,exist_ok=False)
    records, transforms = [], {}
    for edition,mapping in mappings.items():
        path = args.output/f"BrainNet-Viewer-{edition}-{args.version}.zip"
        transforms[edition] = write_archive(path,edition,mapping,repo,head,args.version,tracked,args.wheel)
        records.append(path)
    wheel_copy = args.output/args.wheel.name
    wheel_copy.write_bytes(args.wheel.read_bytes())
    notes = args.output/"RELEASE_NOTES.en.md"
    notes.write_bytes(args.release_notes.read_bytes())
    records.extend([wheel_copy,notes])
    if git(repo, "rev-parse", "HEAD") != head or git(repo, "status", "--porcelain"):
        raise ValueError("Source changed during preparation; do not use partial output")
    (args.output/"SHA256SUMS").write_text("".join(f"{digest(p.read_bytes())}  {p.name}\n" for p in records),encoding="utf-8")
    plan.update(archives_written=True,assets=[{"file":p.name,"bytes":p.stat().st_size,"sha256":digest(p.read_bytes())} for p in records],
                documentation_link_transforms=transforms)
    # Internal evidence never enters the three public archives.
    (args.output/"BUILD_MANIFEST.json").write_text(json.dumps(plan,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"source_commit":head,"assets":len(records)+1,"published":False}))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

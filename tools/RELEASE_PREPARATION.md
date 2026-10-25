# Formal release preparation

The packaging tool reads a clean, reviewed source commit. It does not compile
a wheel, build a Docker image, change application versions or publish files.
Its default mode prints a plan and leaves the output directory untouched.

```sh
python tools/prepare_formal_release.py --version 2.0.0 --revision candidate-1 --output /path/to/new-candidate
```

Review every blocker. Before writing archives:

- Set the Python and MATLAB versions to the same formal version and update
  their release metadata and Web display text.
- Finish the English Word manual, then generate and verify the matching PDF.
  Replace the canonical manual and its package copy together only after review.
- Synchronize documentation contents while preserving runtime-relative links.
- Check fixed dependencies, licences and the exact expected resource file set.
- Commit the reviewed changes. The source worktree must be clean.
- Independently build the wheel from that commit; keep its build and install logs.
- Prepare the reviewed English release notes outside the output directory.

Only the following opt-in command writes the three installation ZIPs. Use an
entirely new directory outside the source checkout; an existing directory is
rejected. Keep the complete output on failure and choose another revision.

```sh
python tools/prepare_formal_release.py --version 2.0.0 --revision candidate-1 --output /path/to/new-candidate --wheel /path/to/brainnet_viewer-2.0.0-py3-none-any.whl --release-notes /path/to/RELEASE_NOTES.en.md --write-archives
```

The six public files are the MATLAB, Python and Web ZIPs, wheel, release notes
and SHA256SUMS. SHA256SUMS covers the other five files. BUILD_MANIFEST.json is
internal build evidence and is not a release asset. Each ZIP has a public
PACKAGE_IDENTITY.json containing its edition, version, source commit and payload
hashes. File membership, hashes, duplicate entries, licences and version mapping
are checked without importing the packaged application. Modern install archives
exclude legacy software; the repository retains the legacy directory.

The Python ZIP carries its wheel. The Web ZIP carries local and server image
recipes and both launchers; a full source build is not required. Documentation
links to installed illustration files stay local. References to source-only
files use the exact Git commit rather than a moving branch. Packaged application
documentation retains its own runtime-relative resource paths.

## Local image preparation

Use the same reviewed commit and actual build time for OCI metadata.
Prepare each architecture separately with a distinct local tag. For example,
on a machine with a configured builder (replace the placeholders):

```sh
docker buildx build --platform linux/amd64 --load -f src/python/Dockerfile.web --build-arg BNV_VERSION=2.0.0 --build-arg BNV_REVISION=FULL_COMMIT --build-arg BNV_CREATED=ACTUAL_UTC_TIME -t brainnet-viewer:2.0.0-candidate-1-amd64 src/python
docker image inspect brainnet-viewer:2.0.0-candidate-1-amd64
docker save --output candidate-1-amd64.tar brainnet-viewer:2.0.0-candidate-1-amd64
```

Repeat with the native arm64 platform/tag on a suitable builder and test host.
Record archive SHA-256, local image ID, platform and exact OCI version/revision.
A successful emulated build does not establish rendering support.
Supply the loaded candidate tag to the launchers or BNV_IMAGE; do not pull an
unpublished formal tag. GPU allocation, actual device rendering and CPU fallback
need separate runtime evidence. Existing beta tags must remain untouched.

Publication is a later action. After authorized publication, record per-platform
registry manifest digests and the multi-architecture index digest, then verify
external downloads and pulls. These digests are not local image IDs.

## Targeted tool checks

```sh
python -m unittest discover -s tests/python -p test_formal_release_preparation.py -v
python -m unittest discover -s tests/python -p test_web_release_launchers.py -v
```

The launcher checks use a fake Docker CLI. They verify decisions and container
protection, not actual GPU, native Linux, Mac or application rendering.

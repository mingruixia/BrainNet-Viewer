# BrainNet Viewer Python and Web

BrainNet Viewer 2.0.0-beta.1 uses Python package version 2.0.0b1.
This source tree uses version 2.0.0b1.post2 and includes newer maintenance
updates; released wheels and Docker Hub images have not been replaced.
Desktop uses Qt and VTK; Web runs in a background Docker container accessed
through a browser on port 1031. MATLAB is not required.

- [Desktop installation](../../docs/python/en/INSTALLATION.md)
- [Docker installation](../../docs/web/en/INSTALLATION.md)
- [Shared tutorials](../../docs/tutorials/unified/en/index.md)
- [Unified manual](../../docs/manual/en/index.md)
- [Changes](CHANGELOG.md)

Run python -m brainnet_viewer in the installed desktop environment.
For development, install this directory with the desktop or web extra.
The Dockerfile builds the Web edition from this source and bundled resources.
Direct dependencies are pinned in pyproject.toml.

Load data, configure, Apply, interact and export. Original surfaces, atlas
examples, tutorial data and dual-atlas Inspect tables are included.
Web supports one local shared session. Source builds select a verified GPU or
fall back to CPU at startup; GPU allocation depends on the Docker host. Save a portable
Scene before stopping/updating its container. Project code uses GPL-3.0-or-later;
bundled resources retain accompanying terms.

This requires one trusted local user; same-origin bootstrap is not OS-user
authentication. Do not use shared-user hosts or public hosting.

Developer: Mingrui Xia — mxia@bnu.edu.cn; mingruixia@gmail.com.

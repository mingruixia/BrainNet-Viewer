# BrainNet Viewer Python and Web

BrainNet Viewer 2.0.0-beta.1 uses Python package version 2.0.0b1.
This source tree uses version 2.0.0b1.post2 and includes newer maintenance
updates; released wheels and Docker Hub images have not been replaced.
Desktop uses Qt and VTK; Web runs in a background Docker container accessed
through a browser on port 1031. MATLAB is not required.

- [Desktop installation](../../docs/python/en/INSTALLATION.md)
- [Docker installation](../../docs/web/en/INSTALLATION.md)
- [Linux LAN server deployment](../../docs/web/en/SERVER_DEPLOYMENT.md)
- [Shared tutorials](../../docs/tutorials/unified/en/index.md)
- [Unified manual](../../docs/manual/en/index.md)
- [Changes](CHANGELOG.md)

Run python -m brainnet_viewer in the installed desktop environment.
For development, install this directory with the desktop or web extra.
The Dockerfile builds the Web edition from this source and bundled resources.
Direct dependencies are pinned in pyproject.toml.

Select input files, adjust the display settings and click **Apply** to render. You can then explore a view, export a figure or save a Scene. The installation includes surface templates, atlas examples, tutorial data and the AAL/Brodmann Inspect tables.
Local Web mode supports one shared session. Linux server mode uses HTTPS and a
team access password, with an independent process for each browser session.
Server mode requires a current source build. Source builds select a verified GPU or
fall back to CPU at startup; GPU allocation depends on the Docker host. Save a portable
Scene before stopping/updating its container. Project code uses GPL-3.0-or-later;
bundled resources retain accompanying terms.

Run Web on a private computer used by one trusted user. Browser-origin checks do not authenticate operating-system users, so the local server is unsuitable for shared-user computers or public hosting.

Developer: Mingrui Xia — mxia@bnu.edu.cn; mingruixia@gmail.com.

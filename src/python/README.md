# BrainNet Viewer Python and Web

BrainNet Viewer uses Python package version **2.0.0**, matching the MATLAB and
Docker/Web editions. Install the matching release assets, or use this source
tree when those assets are not yet available. Earlier beta wheels and Docker
images are separate releases and do not acquire source updates automatically.
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
Current source installations require Python 3.11 or newer on all platforms.
Direct dependencies are pinned in pyproject.toml.

Select input files, adjust the display settings and click **Apply** to render. You can then explore a view, export a figure or save a Scene. The installation includes surface templates, atlas examples, tutorial data and the AAL/Brodmann Inspect tables.
Local Web mode supports one shared session. Linux server mode uses HTTPS and a
team access password, with an independent process for each browser session.
Server mode uses the matching image or a source build. The launchers select a verified GPU or
fall back to CPU at startup; GPU allocation depends on the Docker host. Save a portable
Scene before stopping/updating its container. Project code uses GPL-3.0-or-later;
bundled resources retain accompanying terms.

Run Web on a private computer used by one trusted user. Browser-origin checks do not authenticate operating-system users, so the local server is unsuitable for shared-user computers or public hosting.

## Annotation text

Current source builds include portable fonts for Chinese and supported Unicode
titles, node labels and scalar-bar titles. ASCII node labels keep the chosen
Arial, Times or Courier family; mixed Unicode labels use the bundled fallback.
Characters outside its coverage produce an error rather than disappearing.
This is not a claim of support for every writing system.

Titles fit within the reserved heading strip without changing their text. Use a
wider canvas or a shorter title if it cannot fit legibly. PDF exports that need
the fallback use glyph outlines, so those annotations are not searchable text.
The fonts retain their [OFL notices](brainnet_viewer/resources/fonts/NOTICE.txt).

Developer: Mingrui Xia — mxia@bnu.edu.cn; mingruixia@gmail.com.

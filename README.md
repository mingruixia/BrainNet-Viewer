# BrainNet Viewer 2.0

[中文](README.zh-CN.md) · [Unified manual](docs/manual/en/index.md) · [Shared tutorials](docs/tutorials/unified/en/index.md)

BrainNet Viewer 2.0.0-beta.1 visualizes brain surfaces, nodes, connections,
surface maps and atlas ROIs. Choose MATLAB Desktop, Python Desktop, or the
Docker-hosted Web edition. Developer: Mingrui Xia.

## Install and launch

- MATLAB: install and activate MATLAB, set Current Folder to this repository
  root and run `app = BrainNetViewer;`. Do not recursively add another
  BrainNet Viewer installation. See [getting started](docs/documentation/Getting_Started.en.md).
- Python Desktop: follow [installation](docs/python/en/INSTALLATION.md), install
  the wheel with its desktop extra and run `python -m brainnet_viewer`.
  MATLAB is not required.
- Web: follow [Docker installation](docs/web/en/INSTALLATION.md). The service
  runs in the background and opens at http://127.0.0.1:1031/index.html.
  Download the Web package and run its Compose pull/start commands; no source
  build is required. Image: [mingruixia/brainnet-viewer:2.0.0-beta.1](https://hub.docker.com/r/mingruixia/brainnet-viewer).

## Workflow

Load files through Data Sources, configure Visualization Settings, Apply to
render, interact with a selected view, then save/export. Save Scene preserves
inputs and settings; presets store display settings. Follow the shared manual
and tutorials for scientific inputs, edition differences and export options.

The surface library, atlas-network examples and real tutorial inputs
are included. [AtlasNetworks](src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/README.md)
contains AAL90 and fourteen GroupFC pairs, including AAL116, Schaefer1000 and
Brainnetome246. AAL90 volume and vertex-label inputs are in
`resources/atlases/AAL90/` (source/MATLAB archive) or `atlases/AAL90/`
(Python/Docker resource library). Inspect uses AAL/Brodmann lookup in an MNI-like space; verify
registration and coordinate correspondence for your own data. The application
interface is English and is not restricted to human-brain data.

Web supports a local single-user shared session and software rendering.
Save a portable Scene before stopping or updating the container.
Desktop/Python/Web compatibility notes describe the checked environments.

## Build from source

Python packaging and Docker build files are in src/python. For an isolated
development environment install that directory with the desktop or web extra.
A local wheel can be built with `python -m pip wheel --no-deps ./src/python`.
The [Docker guide](docs/web/en/INSTALLATION.md) provides source-build commands.
The default container port is 1031.

## Citation and support

Xia M, Wang J, He Y (2013). BrainNet Viewer: A Network Visualization Tool for
Human Brain Connectomics. PLoS ONE 8: e68910.
https://doi.org/10.1371/journal.pone.0068910

[GitHub](https://github.com/mingruixia/BrainNet-Viewer) ·
[NITRC](https://www.nitrc.org/projects/bnv/) ·
[Changes](CHANGELOG.md)

Contact Mingrui Xia: mxia@bnu.edu.cn; mingruixia@gmail.com.
Project code uses [GPL-3.0](LICENSE). Retain code and bundled-resource notices.

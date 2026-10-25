# BrainNet Viewer 2.0.0

[中文](README.zh-CN.md) · [Unified manual](docs/manual/en/index.md) · [Shared tutorials](docs/tutorials/unified/en/index.md)

BrainNet Viewer displays brain surfaces, networks, surface maps and atlas ROIs
through MATLAB Desktop, Python Desktop and Docker/Web. This source tree uses
version **2.0.0** for all three editions.

Use packages and image tags from the matching GitHub or NITRC release and check
their SHA256SUMS. If the 2.0.0 assets are not yet listed, use the source-installation
instructions. The earlier 2.0.0-beta.1 downloads remain a separate release; their
Python wheel is 2.0.0b1. [Changes](CHANGELOG.md) describes the updates.
Python requires 3.11 or newer; the Docker image includes Python 3.12.

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
  build is required once the matching image is available. Image: [mingruixia/brainnet-viewer:2.0.0](https://hub.docker.com/r/mingruixia/brainnet-viewer).

## Workflow

Select your inputs in **Data Sources** and adjust their appearance in
**Visualization Settings**. Click **Apply** to render, then use the camera tools
to explore a view or **Export Figure** to save it. **Save Scene** records the
inputs and settings for later use; a preset stores display settings for reuse
with other data. The shared manual and tutorials explain the file formats,
scientific interpretation and differences between editions.

Read [display and statistical interpretation](docs/documentation/Scientific_Interpretation.en.md)
when choosing thresholds, size mappings and anatomical overlays.

The installation includes a surface library, atlas-network examples and tutorial
data. [AtlasNetworks](../Data/ExampleFiles/AtlasNetworks/README.md)
contains AAL90 and fourteen GroupFC pairs, including AAL116, Schaefer1000 and
Brainnetome246. AAL90 volume and vertex-label inputs are in
`resources/atlases/AAL90/` (source/MATLAB archive) or `atlases/AAL90/`
(Python/Docker resource library). Inspect uses AAL/Brodmann lookup in an MNI-like space; verify
registration and coordinate correspondence for your own data. The application
interface is English and is not restricted to human-brain data.

The local Web mode has one shared session and is intended for a trusted user on a
private local computer. The supplied launchers test GPU rendering and select
the GPU when available, otherwise the CPU. GPU devices must be allocated to the
container. Compose without GPU allocation runs on the CPU. Save a portable
Scene before stopping or updating the container.

For a trusted team on a Linux LAN server, use
[server mode](docs/web/en/SERVER_DEPLOYMENT.md), with HTTPS, an access password
and one application process per browser session. Use a matching 2.0.0 image or
a source build; the earlier beta image does not include server mode.

The local server checks browser requests but does not authenticate operating-system
users. Another local process can forge request headers, so this configuration is
unsuitable for shared-user computers or public hosting without a separately
configured deployment. See [security guidance](SECURITY.md).

## Build from source

Python packaging and Docker build files are in `src/python`. Create an isolated
environment and install that directory with the `desktop` or `web` extra.
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
Project code uses [GPL-3.0-or-later](LICENSE). Retain code and bundled-resource notices.

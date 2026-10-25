# BrainNet Viewer Web installation

[中文](../zh-CN/INSTALLATION.md)

BrainNet Viewer Web 2.0.0 runs in the background in Docker. Use it at
**http://127.0.0.1:1031/index.html**. MATLAB and a local Python installation are
not required. The matching image is
[mingruixia/brainnet-viewer:2.0.0](https://hub.docker.com/r/mingruixia/brainnet-viewer).

Use the image only when that version is available. Before publication, use an
identified local image supplied for testing or the source-build instructions.
Do not substitute the unchanged beta image for 2.0.0.
[Versioned installation](RELEASE_INSTALLATION.md) covers offline loading,
GPU-preferred launchers, CPU fallback and beta upgrades.

For access through a Linux server's IP, follow
[server deployment](SERVER_DEPLOYMENT.md), including HTTPS, authentication and
independent browser sessions. Do not expose the local loopback recipe on a LAN.

## 1. Install and start Docker

- **Windows:** install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/),
  use the WSL 2 backend and Linux containers, then start Docker Desktop.
  If Windows requests a restart while setting up WSL, restart before continuing.
- **macOS:** install [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)
  for your processor (Apple Silicon or Intel), then open Docker Desktop.
- **Linux:** install [Docker Engine](https://docs.docker.com/engine/install/)
  and the [Compose plugin](https://docs.docker.com/compose/install/linux/).

Wait until Docker reports that the engine is running. Open PowerShell on Windows
or Terminal on macOS/Linux and run:

```sh
docker version
docker compose version
docker info --format '{{.OSType}}/{{.Architecture}}'
```

The first command must show both Client and Server sections. The last must show
Linux. Docker selects the amd64 or arm64 image for the engine automatically; do
not force amd64 on Apple Silicon.

## 2. Download the Web package and start

Download **BrainNet-Viewer-Web-2.0.0.zip** from the matching
[GitHub release](https://github.com/mingruixia/BrainNet-Viewer/releases)
or [NITRC](https://www.nitrc.org/projects/bnv/), verify SHA256SUMS and extract it.
If the assets are not yet listed, use a supplied local image or build from source.

For GPU-preferred startup, follow the supplied Windows or Linux/macOS launcher
steps in [versioned installation](RELEASE_INSTALLATION.md). They test GPU drawing
before selecting a backend. Docker must be able to allocate the GPU.

For a CPU-compatible Compose launch, open a terminal in the extracted folder:

```sh
docker compose -f compose.web.release.yml pull
docker compose -f compose.web.release.yml up -d
docker compose -f compose.web.release.yml ps
```

Pull only after the matching image is published. For an unpublished local image,
set `BNV_IMAGE` to its verified tag and omit `pull`. Compose does not allocate GPU
devices by default. The default CPU quota is 1; set `BNV_CPUS` explicitly when needed.

Open **http://127.0.0.1:1031/index.html**. Docker Desktop must remain running;
the terminal can close. Check logs before starting another container.
The following lifecycle commands apply to Compose launches; for launcher-managed
containers use the actions described in [versioned installation](RELEASE_INSTALLATION.md).
Keep a beta installation's original recipe with its beta files.

## 3. Stop, reopen and update

Before stopping, restarting or updating, use **Save Scene**, and check that the
Scene ZIP is present in your browser's download folder.

From the extracted Web package folder:

```sh
docker compose -f compose.web.release.yml logs --tail 80
docker compose -f compose.web.release.yml stop
docker compose -f compose.web.release.yml start
```

Use `restart` in place of `start` to restart a running service. Refresh the browser
after starting it. The container restarts with Docker unless you explicitly
stopped it; the application does not restore an unsaved session automatically.

To update, save the Scene, obtain the Compose file for the desired release, then
run `pull` and `up -d` again. Open the saved Scene and select Apply. Keep the
versioned package if you need to return to that version.

## 4. Files and resources

**Add Files** uploads selected local files to the application. The bundled
surface and atlas-network libraries are available without uploading them.
**Export Figure** downloads the image and its provenance JSON separately.
If only one file appears, check the browser's multiple-download permission.
**Save Scene** downloads a portable ZIP; **Open Scene**, followed by **Apply**,
restores it.

Uploads and working data inside the container are temporary. Save exported
files and Scenes on your computer. Files already downloaded are retained when
the container stops. Opening another tab connects to the same application
session; it does not create an independent user.

## 5. Troubleshooting

| Symptom | Action |
| --- | --- |
| `docker` is not recognized | Finish installing Docker Desktop and reopen the terminal. |
| Cannot connect to Docker / only Client is shown | Start Docker Desktop, wait for the engine, and check `docker version` again. On Windows confirm WSL 2 and Linux containers. |
| `pull access denied` or `manifest unknown` | Check the exact image name and version in the Compose file against the release page. |
| Download timeout, proxy, DNS or certificate error | Check Docker Desktop's network/proxy settings and institutional network access to Docker Hub. Browser Internet access alone does not prove the Docker engine can download images. Keep the complete error when seeking help. |
| `no matching manifest` | Check the engine OS/architecture. This image uses Linux amd64 or arm64. |
| Port 1031 is already allocated | Identify the existing service. To use another port, create a file named `.env` beside the Compose file containing `BNV_PORT=1035`, run `up -d`, and open http://127.0.0.1:1035/index.html. |
| Page unavailable while container is running | Check `ps` and `logs --tail 80`, wait for initialization, and verify the URL and port. |
| Container stops or a large upload/export fails | Check logs and Docker's available memory/disk space. The recipe caps memory at 8 GiB, CPU use at 2 cores and temporary storage at 512 MiB. Reduce input/output size or adjust these limits deliberately. |
| Scene disappears after restart | Open the previously downloaded Scene ZIP and select Apply. Unsaved working data is not automatically restored. |

Use the release's checksum file to check downloaded ZIPs. The image requires no
local scientific Python dependencies. Rebuilding the source is not necessary
for normal installation.

## Deployment scope

For a trusted team accessing a Linux server by IP, use the separate
[server deployment guide](SERVER_DEPLOYMENT.md). It provides authenticated,
independent browser sessions and requires a current source build. Do not expose
the local recipe below to the LAN by changing its loopback binding.

The released-image configuration binds only to this computer, uses one shared
session and renders with the CPU. CPU quotas are limits, not the host's total
core count. The presence of a graphics card does not enable container GPU
rendering. A shared server deployment requires authentication, user isolation
and HTTPS; it is outside this local installation recipe.

## Optional source build

Use the complete current source repository, with the terminal at its root:

```sh
docker compose -f src/python/compose.web.yml up -d --build
```

This requires Internet access for build dependencies. Use either the source-build
service or the downloaded image on port 1031, not both at once.

The source image uses Python 3.12 and fixed application dependencies. Compose
does not allocate a GPU: Auto performs a real graphics probe and normally chooses
CPU without GPU access. Source Compose defaults to a 1-CPU quota, 8 GiB memory and
512 MiB temporary storage. ARM64 source rendering has not been verified; a graphics probe under emulation failed. Check rendering on the target machine before using a source-built ARM64 image.
The existing released ARM64 image has not been replaced.

### Windows GPU-preferred source launch

Use Docker Desktop with WSL 2, Linux containers and a supported NVIDIA driver.
Save your Scene and stop any other service using port 1031 first. Build a distinct
local image, then use the supplied PowerShell launcher:

```powershell
docker build -f src/python/Dockerfile.web -t brainnet-viewer:web-local src/python
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Start -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031 -Backend Auto
```

The launcher defaults to min(8, Docker engine CPUs); BNV_CPUS or -CPUs can
select a valid lower or higher quota within that engine limit. Auto first
allocates the GPU to a disposable container and verifies actual
rendering. It starts a CPU container if GPU startup is unavailable. Use `-Backend
CPU` to request software rendering, or `-Backend GPU` to require hardware rendering
and fail rather than silently fall back. Merely listing a GPU is not proof of
hardware rendering. An existing container retains its backend; Stop/Restart do not
reconfigure it. Use a new container name and a free port for a different backend.

```powershell
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Status -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Logs -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
powershell -NoProfile -File tools/manage_brainnet_web.ps1 -Action Stop -Image brainnet-viewer:web-local -ContainerName brainnet-web-source -Port 1031
```

The Windows WSL/NVIDIA path has local rendering checks. Linux GPU deployment and
other drivers require platform-specific configuration; macOS Docker does not
automatically expose the Mac GPU to this Linux image. CPU fallback applies at startup. A GPU process crash or exhausted memory during a session may require a restart.

### Source Web session and input limits

Use the exact loopback hostname and port in the browser URL consistently. The
source server rejects foreign or missing origins on its authentication/connection
endpoints and obtains a fresh key through a same-origin request. It has no user
login and is not a public multi-user server. Do not expose it on the network or
embed it in another site's iframe without a separately designed deployment.

Only one trusted local user is supported. Local processes can forge Origin and
obtain a key; this is not OS-user authentication. Do not use shared-user hosts,
JupyterHub or untrusted shared network namespaces. See [security guidance](../../../SECURITY.md).
Compose accepts `BNV_PORT` (default 1031), `BNV_CPUS` (1) and `BNV_MEM` (8g).
On WSL, `MESA_D3D12_DEFAULT_ADAPTER_NAME` optionally chooses an adapter when supplied
to the container environment; no vendor is forced by default. Do not set internal
`BNV_WEB_BOOTSTRAPPED` loader state manually. Startup allows 90 seconds for the graphics probe and service initialization. Check the reported backend to distinguish hardware rendering from software rendering.

Still frames use 2x sampling; moving frames use lower sampling/quality. CPU-only
surface detail reduction is temporary; still frames, Inspect and export restore
the original geometry. Export image dimensions are set by Export Figure.

Current source builds carry annotation fonts for Chinese and supported Unicode
characters; the host needs no additional font installation. Missing glyphs produce
an error rather than disappearing. Mixed Unicode node labels use the bundled font,
titles fit the available canvas, and PDF fallback text uses glyph outlines. The
earlier beta image is unchanged; use the matching 2.0.0 image or current source.

Scene JSON metadata is limited to 32 MiB; scientific-file uploads to 32 MiB each,
Scene ZIPs to 64 MiB compressed and session files to 128 MiB. Portable Scene saves
stage and verify assets before committing a new filename, and require a filesystem
supporting hard links. Use a local supported filesystem and a new Scene name;
existing output is not overwritten. Save downloaded files before restarting.

Continue with the [shared tutorials](../../tutorials/unified/en/index.md)
and [user manual](../../manual/en/index.md).

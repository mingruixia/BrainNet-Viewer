# BrainNet Viewer Web installation

[中文](../zh-CN/INSTALLATION.md)

BrainNet Viewer Web runs in the background in Docker. Use it in your browser at
**http://127.0.0.1:1031/index.html**. MATLAB and a local Python installation are
not required. The public-beta image is
[mingruixia/brainnet-viewer:2.0.0-beta.1](https://hub.docker.com/r/mingruixia/brainnet-viewer).

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

Download **BrainNet-Viewer-Web-2.0.0-beta.1.zip** from the
[GitHub release](https://github.com/mingruixia/BrainNet-Viewer/releases/tag/v2.0.0-beta.1)
or [NITRC](https://www.nitrc.org/projects/bnv/), then extract it.
Open a terminal in the extracted folder containing `compose.web.release.yml`.
These commands work in Windows PowerShell and macOS/Linux Terminal:

```sh
docker compose -f compose.web.release.yml pull
docker compose -f compose.web.release.yml up -d
docker compose -f compose.web.release.yml ps
```

The first command downloads the application and dependencies from Docker Hub.
It may take several minutes on the first installation. The second starts the
background service. A container should appear as running in the third command.

Open **http://127.0.0.1:1031/index.html**. Allow the first startup a short time
to initialize. Docker Desktop must remain running; closing the terminal is fine.
If the page is not ready, use the log command below instead of starting a second
container.

If you downloaded the complete source repository, the equivalent commands are:

```sh
docker compose -f src/python/compose.web.release.yml pull
docker compose -f src/python/compose.web.release.yml up -d
```

Use one of these folder layouts consistently for subsequent commands.

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

The supplied configuration binds only to this computer, uses one shared
session and renders with the CPU. CPU quotas are limits, not the host's total
core count. The presence of a graphics card does not enable container GPU
rendering. A shared server deployment requires authentication, user isolation
and HTTPS; it is outside this local installation recipe.

## Optional source build

Developers with the complete repository can build locally:

```sh
docker compose -f src/python/compose.web.yml up -d --build
```

This requires Internet access for build dependencies. Use either the source-build
service or the downloaded image on port 1031, not both at once.

Continue with the [shared tutorials](../../tutorials/unified/en/index.md)
and [user manual](../../manual/en/index.md).

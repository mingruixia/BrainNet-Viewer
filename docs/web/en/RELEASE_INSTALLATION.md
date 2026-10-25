# Versioned Docker installation

[中文](../zh-CN/RELEASE_INSTALLATION.md) · [Linux server](SERVER_DEPLOYMENT.md)

This recipe targets 2.0.0. The published 2.0.0-beta.1 image is unchanged.
Before 2.0.0 is published, load the prepared local image with
`docker load --input IMAGE_ARCHIVE.tar`. Verify its checksum, architecture and image
ID; do not substitute the beta image when validating updated software.
Set `BNV_IMAGE` to the loaded tag for Compose, or pass the same tag to the
launcher with `-Image` on Windows or `--image` on Linux/macOS.
Local image IDs and registry manifest digests identify different objects.

## Obtain and start the image

Install and start Docker with Linux containers. Check `docker version` and
`docker compose version`. Use the engine's native amd64 or arm64 image;
do not force amd64 on Apple Silicon. After 2.0.0 is published, extract its Web
ZIP and run from the folder containing `compose.web.release.yml`:

```sh
docker compose -f compose.web.release.yml pull
```

For GPU-preferred startup, on Windows PowerShell:

```powershell
powershell -NoProfile -File start_web.ps1 -Action Start -Backend Auto
powershell -NoProfile -File start_web.ps1 -Action Status
powershell -NoProfile -File start_web.ps1 -Action Logs
powershell -NoProfile -File start_web.ps1 -Action Stop
```

On Linux or macOS:

```sh
sh start_web.sh
sh start_web.sh --action status
sh start_web.sh --action logs
sh start_web.sh --action stop
```

Open **http://127.0.0.1:1031/index.html**. Allow graphics initialization to
finish; check health and logs before starting another copy. The service
continues after the terminal closes. Save Scene before stopping; working
uploads are temporary.

Auto allocates an NVIDIA GPU to a disposable probe and renders an actual
frame. If allocation or rendering fails, it starts a CPU container without
a GPU request. Windows needs Docker Desktop/WSL 2 and suitable NVIDIA support;
Linux needs compatible drivers and NVIDIA Container Toolkit already configured
by the administrator. Scripts do not install these components. Apple Silicon
Docker uses CPU; this image does not expose Metal.

Select `-Backend CPU` / `--backend cpu` for CPU, or `-Backend GPU` /
`--backend gpu` to require hardware rendering and stop on failure.
Existing containers retain their backend. To change it, use a new
`-ContainerName` / `--name` and a free `-Port` / `--port`.
Identity or binding mismatches are rejected. Launchers do not pull images
or delete containers. Startup fallback does not guarantee recovery from a
driver crash or exhausted memory during a session.

In a full source checkout, use `tools/manage_brainnet_web.ps1` or
`tools/start_web.sh`. ZIP script names are aliases of these same implementations.
Specify a source-built or offline image explicitly rather than relying on
the default `mingruixia/brainnet-viewer:2.0.0`.

The launchers read the Docker engine's available CPU count, including the
Docker Desktop virtual machine limit. Their default quota is the smaller of
8 and that count. Set `BNV_CPUS` or pass `-CPUs '1.5'` / `--cpus 1.5` to override it;
the command-line value takes precedence. Values must be decimal numbers from
0.01 through the engine's CPU count. Invalid values or failed engine queries stop
before the GPU probe. Probe and application containers use the same quota.
Changing an existing container's CPU/backend settings requires a new container;
Start/Restart preserve its original configuration.

## Upgrade from 2.0.0-beta.1

1. Keep the beta files and image. In the old application, use **Save Scene** and
   verify that the ZIP has downloaded. Extract the new Web package to a different
   directory. Do not overwrite the beta folder or discard its saved Scenes.
2. Identify the old service and its port. From the original beta package folder,
   check its project, image and binding, then stop only that verified service:

```sh
docker compose -f compose.web.release.yml -p brainnet-viewer-beta ps
docker compose -f compose.web.release.yml -p brainnet-viewer-beta stop
```

   These commands use the **old folder's** Compose file. They retain containers
   and images for rollback. If the beta was started another way, inspect
   `docker ps` and stop its exact identified container with
   `docker stop VERIFIED_OLD_CONTAINER`. Replace the placeholder; do not stop
   unrelated containers or run a global cleanup.
3. Start the new version from its own folder. Compose uses a different project
   name. A stopped container created by a launcher still owns its name: use a
   new name, such as `brainnet-web-2`, with `-ContainerName` on Windows or
   `--name` on Linux/macOS. Port 1031 is usable only after the old service stops.
   To keep both services running, also choose a free port, for example
   `-Port 1035` or `--port 1035`, and open that port in the browser.
   Changing only the container name does not release an occupied port.
4. Open the downloaded Scene, select **Apply**, and check the restored data and
   settings. For rollback, save any new work, stop only the identified new service,
   and start the beta service from its original folder. Never remove the old
   container or image just to work around an identity check.

## Compose without GPU allocation

Instead of the launcher:

```sh
docker compose -f compose.web.release.yml up -d
docker compose -f compose.web.release.yml ps
docker compose -f compose.web.release.yml logs --tail 80
docker compose -f compose.web.release.yml stop
```

Do not run both methods on the same port. Compose sets Auto inside the
application but does not allocate a GPU, so this recipe normally uses CPU.
Compose defaults to 1 CPU so it can start on small engines. Set `BNV_CPUS` to
an appropriate quota no higher than the engine's available CPU count. For a
server, increase it deliberately to match the desired concurrency. Set
`BNV_RENDER_BACKEND=cpu` for explicit CPU selection or `BNV_PORT` for a
different host port. In a source checkout, prefix Compose paths with
`src/python/`. Both local methods bind to loopback and share one workspace.
Export Figure downloads the image and JSON sidecar separately; Save Scene
downloads a portable ZIP.

## Linux server from the versioned image

Follow [server preparation](SERVER_DEPLOYMENT.md) for a trusted certificate
containing the server IP, a private key and an access-password file readable
by UID 10001. Place them in `.server-secrets/` beside the release Compose file,
or set `BNV_SERVER_SECRETS_DIR` to their private directory. Keep secrets out
of the image and repository. On the Linux server:

```sh
export BNV_SERVER_ORIGIN=https://192.168.1.10:1031
docker compose -f compose.web.server.release.yml up -d
docker compose -f compose.web.server.release.yml ps
docker compose -f compose.web.server.release.yml logs --tail 80
```

Replace the IP with the certificate's server IP. In a source checkout, use
`src/python/compose.web.server.release.yml`; its secret directory is beside
that file. This recipe uses a versioned image without a Dockerfile or source
build. For an offline candidate, set `BNV_IMAGE` first.

Each signed-in browser session has an independent process. Tabs sharing a
cookie share a session; another profile or private window provides another
workspace. The default four sessions share bounded resources. Use HTTPS on a
trusted LAN, not anonymous Internet hosting. The server recipe does not
allocate a GPU: hardware-specific device access needs separate configuration.
Auto inside a worker cannot grant access. Record CPU and actual GPU results
separately; retain the server guide's origin, credential and resource rules.

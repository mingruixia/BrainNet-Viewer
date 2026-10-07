# BrainNet Viewer Web — local Docker installation

The Web application runs in a background Docker container and is used through
a browser. The default host port is **1031**. No MATLAB or desktop Python
environment is required on the browsing computer.

This candidate supports **one user / one shared session on the local computer**.
Do not publish it on a LAN, Internet or tunnel. Authentication, isolated users,
TLS and remote-server acceptance require separate work. The initial container
uses software rendering; a host GPU does not establish Docker GPU acceleration.

## Prerequisites

- A working Docker engine configured for Linux containers.
- Docker Compose v2 if using the source-build recipe below.
- The project source including `src/python`, its Dockerfile and bundled resources.
- Internet access for the first image build. A transferred, already-built image
  can be loaded without rebuilding; image distribution is separate from this guide.

Run `docker version` before proceeding. If it cannot reach the engine, start
the engine and resolve its access permissions; do not change application pins.

## Build and start from source

From the project root, on Windows, macOS or Linux:

```sh
docker compose -f src/python/compose.web.yml config
docker compose -f src/python/compose.web.yml up -d --build
```

Open **http://127.0.0.1:1031/index.html**. The engine must remain running;
closing the terminal does not stop the background container.
Current development builds disable the browser idle-exit timer in container
mode: the background service remains available until explicitly stopped.
Earlier images may retain the library's five-minute idle-exit behavior.

```sh
docker compose -f src/python/compose.web.yml ps
docker compose -f src/python/compose.web.yml logs --tail 60
docker compose -f src/python/compose.web.yml stop
docker compose -f src/python/compose.web.yml start
docker compose -f src/python/compose.web.yml restart
```

Run these commands against the same project and Compose file. `start` reuses
existing stopped containers; it does not create or rebuild them. Refresh the
browser after start/restart. To update source, save your session first and use
`up -d --build`. Do not run this recipe alongside another service on port 1031.

## Optional Windows lifecycle helper

Build a named image once from the project root:

```powershell
docker build -f src/python/Dockerfile.web -t brainnet-viewer:web-local src/python
```

Then use the helper instead of Compose, not both for the same service:

```powershell
.\tools\manage_brainnet_web.ps1 -Action Start
.\tools\manage_brainnet_web.ps1 -Action Status
.\tools\manage_brainnet_web.ps1 -Action Logs
.\tools\manage_brainnet_web.ps1 -Action Stop
.\tools\manage_brainnet_web.ps1 -Action Start
.\tools\manage_brainnet_web.ps1 -Action Restart
```

It defaults to image `brainnet-viewer:web-local`, container `brainnet-web` and
host port 1031. Optional `-Image`, `-ContainerName` and `-Port` select a different
candidate or free local port; the container-internal port remains 1031.
The helper checks exact image identity and loopback port bindings before
operating on an existing container. It never replaces/removes one automatically.
Start is idempotent, and start/restart checks HTTP readiness for up to 30 seconds.
If PowerShell blocks the script, follow your institution's script policy;
ordinary Docker commands above remain available. Do not weaken system policy.

## Session and file lifetime

**Save Scene and verify browser downloads before stopping, restarting, updating
or removing a container.** Settings, cameras, uploads and generated tool files
are temporary session data in `/tmp`, not persistent project files. Recreating
or restarting the process does not restore the scene automatically. Closing
or refreshing a browser tab is not a reliable way to create a new isolated session.

- Add Files uploads local inputs into the container. Local path strings are not
  server filesystem access.
- Export Figure downloads an image and its `.provenance.json` separately, not ZIP.
  Browser download permissions, locations and duplicate names apply.
- Save Scene downloads a portable Scene ZIP. Open Scene and Apply restore it;
  this does not restore another user's live browser session.
- Files already saved on your computer are not deleted by container stop/restart.

## Limits, troubleshooting and verification

The supplied recipe uses a non-root user, read-only root, 512 MiB temporary
filesystem, 8 GiB memory, 8 CPU quota and PID limit 256. Host CPU count is not
the CPU quota. Container memory reporting handles cgroup v1/v2. Software
rendering is expected; GPU inventory and render-device identity are distinct.

If port 1031 is occupied, identify the owner; do not stop an unrelated process.
Use a free loopback host port with the helper or explicitly adjust the Compose
port mapping while retaining `127.0.0.1`. If the page does not load, inspect
status/logs, check the engine and port, then refresh the browser. A readiness
timeout does not authorize a second competing service.

If an upload/export exceeds limits or the temporary filesystem fills, save
available results and use smaller inputs/output dimensions. Restart only after
saving your portable Scene. Do not silently relax dependencies or quotas.

The current candidate has focused Windows-hosted Linux-container lifecycle,
rendering and export checks; this is not macOS Docker, hardware-GPU, multi-user
or full three-edition acceptance. Shared scientific usage is covered in the
[unified tutorials](../../tutorials/unified/en/index.md) and
[manual](../../manual/en/index.md). Web-specific behavior is described in
Web development guidance (repository reference).

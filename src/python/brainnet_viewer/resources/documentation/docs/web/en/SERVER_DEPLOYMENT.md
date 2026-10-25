# BrainNet Viewer on a Linux LAN server

[中文](../zh-CN/SERVER_DEPLOYMENT.md) · [Local installation](INSTALLATION.md)

Server mode lets a trusted team use BrainNet Viewer through a Linux server's IP
address. Each signed-in browser session has its own application process, uploaded
files, settings and cameras. Two browsers using the same client IP remain separate.
Tabs in the same browser profile share its session cookie and therefore its process;
use a different profile or a private browsing session for a separate workspace.

Server mode is available from the current source branch. The existing
`2.0.0-beta.1` Docker Hub image does not include it. Build the source image using
the recipe below. The ordinary local Compose recipe still uses port 1031 on loopback
and one shared application session.

## Prepare the server

Install [Docker Engine](https://docs.docker.com/engine/install/) and the
[Compose plugin](https://docs.docker.com/compose/install/linux/) on Linux. Obtain
the complete repository and open a terminal at its root. Choose a stable server
IP and restrict incoming TCP connections on port 1031 to your team's LAN using
the host or institutional firewall. Do not publish this service on the Internet.

The server requires HTTPS and an access password. Obtain a certificate whose
Subject Alternative Name includes the server IP, together with its private key,
from your administrator. The certificate must be trusted on the client computers.
Do not bypass certificate warnings or transmit passwords over plain HTTP.

Create `src/python/.server-secrets/` and place these three files inside it:

Generate the access password locally, for example with `openssl rand -base64 24`.
Save its output in `access_password.txt` and share it through your institution's
approved private channel, not a public issue or repository. Everyone using this
password has the same access identity; browser sessions isolate workspaces but
do not identify individual people.

| File | Content |
| --- | --- |
| `server.crt` | PEM certificate and intermediate chain, if needed |
| `server.key` | PEM private key matching the certificate |
| `access_password.txt` | A random team access password of 16–256 UTF-8 bytes, on one line |

The directory is excluded from Git and the Docker build. Never commit its contents.
Keep the original files accessible only to the administrator and the Docker service.
The application runs as UID 10001; its read-only secret mounts must be readable by
that UID. On native Linux, an administrator can assign the files to UID 10001 and
use mode 0400, with a private parent directory. Check local ownership and Docker
rootless mappings before doing so. Do not make the private key world-readable.

If your administrator keeps secrets elsewhere, set `BNV_SERVER_SECRETS_DIR` to
that directory's absolute path instead. Secret files are mounted at runtime;
they are not included in the image. Changing a password file requires restarting
the server and ends all active sessions.

## Build and start

Replace the example address with the certificate's server IP:

```sh
export BNV_SERVER_ORIGIN=https://192.168.1.10:1031
docker compose -f src/python/compose.web.server.yml up -d --build
docker compose -f src/python/compose.web.server.yml ps
docker compose -f src/python/compose.web.server.yml logs --tail 80
```

On a client computer, open **https://192.168.1.10:1031/index.html** and enter
the team access password. The first application launch in a new browser session
may take up to 90 seconds for graphics initialization. Refreshing the page reuses
that session; it does not create another process.

Use the exact configured address. Other IP aliases, hostnames and ports are
rejected. To publish a different host port, set `BNV_PORT` and change the port in
`BNV_SERVER_ORIGIN` to match. The container's internal port remains 1031.
This recipe terminates TLS directly in the gateway. It does not accept forwarded
host or scheme headers as proof of origin; a TLS-terminating reverse proxy needs
a separately configured deployment rather than simply adding those headers.

## Session lifetime and resources

The default limit is four browser sessions. A session reserves a slot after
sign-in and starts its worker on the first application request. When all slots
are occupied, another sign-in returns a capacity message without disturbing
existing users. A failed or crashed worker is removed; the user signs in again
to start a new workspace.

After 30 minutes without user activity, the server removes the session's process
and temporary files, even if an inactive tab remains connected. Mouse, keyboard
and touch input renew activity; transport heartbeats and server-rendered frames
do not. A warning appears before expiration with a **Keep session** button.
Scientific commands receive a bounded five-minute grace period; this is not an
unlimited exemption for a stalled operation. Closing all application tabs also
leaves the session subject to the same idle timeout.
For immediate cleanup, open `https://SERVER_IP:1031/_bnv/session` and select
**Sign out and end session**. Save a Scene before doing so.

| Variable | Default | Meaning |
| --- | --- | --- |
| `BNV_MAX_SESSIONS` | `4` | Maximum signed-in browser sessions, 1–32 |
| `BNV_IDLE_SECONDS` | `1800` | Disconnected-session lifetime, 30–86400 seconds |
| `BNV_WORKER_THREADS` | `2` | Scientific-library thread setting per worker, 1–64 |
| `BNV_LOGIN_ATTEMPTS` | `10` | Failed sign-ins per source group per window, 1–100 |
| `BNV_LOGIN_WINDOW` | `60` | Sign-in failure window, 10–3600 seconds |
| `BNV_MEM` | `16g` | Memory limit for the whole container |
| `BNV_CPUS` | `1` | CPU quota for the whole container |
| `BNV_TMP_SIZE` | `2g` | Shared temporary-storage limit |
| `BNV_RENDER_BACKEND` | `auto` | `auto`, `cpu` or `gpu` |
| `BNV_SERVER_BIND` | `0.0.0.0` | Host interface receiving connections |
| `BNV_PORT` | `1031` | Host port |

Container limits are shared across all workers, not guaranteed allocations per
user. Thread settings do not impose a per-process CPU or memory quota. Start
with a small session limit and measure representative datasets on the server;
reduce concurrency if memory, temporary storage or GPU capacity is insufficient.
Separate processes isolate application state, not hostile operating-system users.
This deployment is for trusted team members, not anonymous public hosting.
The shared password controls entry but does not provide named accounts, roles,
individual revocation or an institutional identity provider.

Successful sign-ins do not consume failure quota. An already authenticated
browser can return to its session without another password check. Failed sign-ins
are limited by socket peer, with IPv6 addresses grouped by /64; there is also a
global failure limit of ten times the per-source allowance. A blocked source
must wait for the failure window to expire. Forwarded addresses are not trusted.

The gateway records sign-in outcomes and session creation/termination reasons.
Audit identifiers are independent random values, not cookie prefixes. Passwords,
session cookies, worker credentials and scientific filenames are not logged.
Logs include peer IPs; apply your institution's access and retention policy.
The command-line `--log-level` option accepts INFO, WARNING or ERROR. Static
JavaScript, CSS and fonts use private browser caching; session and data responses
remain uncached.

HTTP form bodies are limited to 4 KiB. Scientific uploads use bounded WebSocket
messages, up to 72 MiB per message, with existing per-file and workspace limits
still enforced by the application. The gateway relays messages rather than
decoding scientific arrays; allow for simultaneous incoming/outgoing buffers
when planning memory. This is not a constant-memory file-streaming interface.


The Compose CPU default is conservative for small engines. Increase BNV_CPUS
for the server's workload, never above the Docker engine's available CPU count;
this quota is shared across sessions and is not a per-user reservation.

## CPU and GPU rendering

Each worker performs an isolated graphics probe. `auto` chooses hardware
rendering when available and falls back to CPU when the probe cannot use it.
The default server recipe does not allocate GPU devices, so it normally uses
software rendering. `gpu` requires actual hardware rendering and fails startup
if it is unavailable; it does not silently choose CPU.

GPU access on Linux requires compatible drivers and container device allocation.
NVIDIA deployments also require the
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
Configure device access with your administrator for the server's hardware; do
not assume Windows WSL settings apply to a native Linux server. Workers share
the allocated GPU and its memory. Startup fallback does not guarantee recovery
from an out-of-memory error or a graphics-driver failure during a session.

## Files and maintenance

Add Files uploads from the client computer to that session only. Save Scene
downloads a portable ZIP to the client. Export Figure downloads its image and
provenance JSON separately. Browser download permissions still apply.
Temporary uploads are not a server-side archive: keep the downloaded Scene
before closing a session, stopping the service or applying an update.

```sh
docker compose -f src/python/compose.web.server.yml stop
docker compose -f src/python/compose.web.server.yml start
```

Keep `BNV_SERVER_ORIGIN` and other environment values set when running these
commands, or store non-secret settings in a private environment file. Access
passwords and TLS private keys belong in the mounted secret files, not command
arguments. After updating source, save active Scenes and run `up -d --build`.
Service restarts end all unsaved sessions.

## Versioned image

For an image without a source build, use [versioned installation](RELEASE_INSTALLATION.md).
HTTPS, password, independent sessions and resource rules remain the same.
The unchanged beta.1 image does not contain server mode.

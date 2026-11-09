# Unraid LAN image

The `2.0.0-unraid.1` image adds a trusted-LAN entry point to the published 2.0.0
application. It leaves the `2.0.0` and `latest` images unchanged. The application
and each browser worker retain the 2.0.0 renderer and resources.

The Unraid Community Applications template starts with HTTP and no password.
These defaults are also set by the image entry point when run outside Unraid.
Install it from **Apps**, then open **WebUI** at `http://UNRAID_IP:1031`.
No certificate, password file or public-origin setting is needed for this mode.
The default address discovery accepts literal private/loopback IP addresses.
Set `BNV_SERVER_ORIGIN` explicitly to use a DNS name or a different canonical URL.

Each browser cookie session owns a separate process and workspace. Tabs in one
browser profile share the session. Scene uploads remain temporary: save Scene
before ending the session or restarting the container. Figure and JSON downloads
retain the normal separate-file behavior.

HTTP does not encrypt traffic and anonymous mode permits access from devices
that can reach the port. Use these defaults on a trusted LAN, not a public port
forward. Keep container resource limits appropriate to the available hardware.

## Optional HTTPS and password

The advanced settings are independent:

| Setting | Default | Optional setting |
| --- | --- | --- |
| `BNV_SCHEME` | `http` | `https` |
| `BNV_PASSWORD_AUTH` | `off` | `on` |
| `BNV_SERVER_ORIGIN` | empty; private IP discovery | Explicit `http(s)://host:port` |
| Private server directory | not mounted | Mount read-only at `/run/bnv-secrets` |

For HTTPS, supply a certificate (`server.crt`) and private key (`server.key`),
set `BNV_SCHEME=https` and set the exact HTTPS origin. The certificate must cover
that hostname/IP and its issuer must be trusted by client browsers. Update the
WebUI shortcut to the same HTTPS URL.

For password access, supply `access_password.txt` and set `BNV_PASSWORD_AUTH=on`.
The file contains one line of 16–256 UTF-8 bytes. Use a random password; no shared
default password is provided. The directory and files must be readable by UID
10001, kept private, and mounted read-only. Enabling password access alone does
not encrypt HTTP; enable HTTPS when encryption is needed.

The ordinary `brainnet-server` entry point still requires its explicit secure
configuration. The new behavior requires `--trusted-lan` or the Unraid launcher;
it is not an implicit change to existing deployments.

Source for this variant is on branch `maintenance/unraid-easy-lan-20261102`.
The image is built with `src/python/Dockerfile.unraid`, from the pinned 2.0.0
multi-architecture index. Docker/Linux HTTP and optional TLS checks are separate
from native Unraid installation, GPU passthrough and native ARM64 rendering.

## Unreleased anonymous network guard

The following changes are in the local maintenance source and are not included
in the published `2.0.0-unraid.1` image. The Community Applications template
continues to use that published image.

The guard admits anonymous requests from the actual socket peer only when it is
a private or loopback address. It normalizes IPv4-mapped IPv6 addresses. It does
not use `Forwarded`, `X-Forwarded-For` or `X-Real-IP` to grant access. Existing
Host, Origin and same-origin WebSocket checks remain in force; rejected requests
do not allocate a session. Password-enabled access keeps its existing rules.

Docker bridge addresses remain supported. For a VPN that routes private LAN
addresses, no additional network setting is needed. For direct VPN peers in a
different range, the source launcher accepts `BNV_ANONYMOUS_NETWORKS`, a
comma-separated list of canonical CIDRs, for example `100.101.102.0/24`. Allow
only the client range you intend to use. This does not change server-address
validation: automatic origin discovery still requires a private/loopback server
IP. Use a DNS name with an explicit matching `BNV_SERVER_ORIGIN` when needed.

A reverse proxy is the socket peer seen by the gateway. If that proxy has a
private address, its clients must be restricted by the proxy or upstream
firewall. The application cannot recover the original client boundary from
untrusted forwarding headers. A same-origin HTTP proxy must preserve Host and
Origin and support WebSocket upgrade. TLS termination in front of an HTTP
gateway is not covered by these checks; configure and validate the HTTPS path
separately rather than disabling origin validation.

The association checks cover a Docker bridge, an HTTP proxy and simulated CGNAT
VPN addresses in Docker network namespaces. They do not constitute physical VPN,
native Unraid or GPU passthrough acceptance.

## Anonymous source guard (source maintenance update)

This section describes the source guard on this maintenance branch. The published 2.0.0-unraid.1 image retains its original gateway. A later release receipt will identify any new image and installation target.

Anonymous requests are checked against the actual connection peer. Defaults allow RFC1918 private networks, loopback and IPv6 ULA. BNV_ANONYMOUS_NETWORKS adds explicit canonical CIDRs for controlled VPN or other client networks. BNV_SERVER_ORIGIN identifies the application address; it is independent of client source admission. Forwarded headers grant no access. HTTPS and password authentication remain optional.

A proxy, docker-proxy or SNAT can give several clients the same allowed private peer. Apply access controls upstream where real clients are distinguishable. The application can check only its actual connection peer. Record observed peers, response codes and refusal before session allocation. Windows Docker Desktop host-port checks are distinct from native Unraid, physical VPN and IPv6 deployment validation.

With password authentication enabled, failed attempts from clients sharing a proxy peer count towards the same limit. Once exhausted, other users' new sign-ins can temporarily return HTTP 429. Existing sessions and successful sign-ins retain their existing handling. Check concurrent sign-in availability alongside upstream access and rate limits.

# Security and supported deployment

## Local Web mode

The Web edition is intended for **one trusted user on a private local computer**.
Publish its port on the loopback interface only. Shared-user computers,
JupyterHub, shared network namespaces and public hosting require authentication
and user isolation that this local server does not provide. The same restriction
applies if untrusted processes can run on the computer.

Host and Origin checks, together with a new random WebSocket secret at each
startup, protect against cross-site browser requests. They do not authenticate
operating-system users: a local process can forge an Origin header and obtain a
key. Binding to loopback does not resolve this limitation.

## Linux server mode

The current source includes a separate [Linux LAN server recipe](docs/web/en/SERVER_DEPLOYMENT.md).
It requires HTTPS and an administrator-managed team access password. Each browser
cookie session owns a separate loopback worker process, startup credentials and
temporary workspace. Workers require an additional private gateway credential;
their ports must never be published. Browser cookies are HttpOnly, SameSite Strict
and Secure on HTTPS. Only the configured origin is accepted; forwarded headers
are not trusted. Sign-in attempts, concurrent sessions and inactive-session
lifetimes are bounded. Sign-out or server shutdown ends the owned workers.

Inactivity is measured from user activity, not the existence of a WebSocket or
transport heartbeats. Server frames do not renew it. Browser warnings and the
keep-session action help users save work before expiry; scientific commands have
a bounded grace period. Failed sign-ins, rather than successful access, consume
rate-limit quota. Audit logs contain peer IPs and independent random audit IDs,
not passwords, session cookies, worker credentials or scientific filenames.

Use this mode only for trusted team members on a restricted LAN. It does not
provide named accounts, individual access revocation, role permissions or a
security boundary against hostile OS users. Processes run as the same non-root
container user and share container resource limits and any allocated GPU. A
resource-intensive session can affect other users. It is not an anonymous public
hosting service, and it does not make confidential clinical data safe to upload
without your institution's authorization and deployment controls.

The existing public-beta image does not include server mode. Source builds are
required until a release explicitly includes it. Never enable LAN access simply
by changing the local recipe's port binding.

## Dependencies and reporting

Use the pinned dependencies and run `pip check` after installation. The server
rejects unsupported Web clients. Source updates do not upgrade previously
installed packages or running containers.

Report sensitive issues privately to Mingrui Xia at mxia@bnu.edu.cn or
mingruixia@gmail.com. Include the version or commit, platform, deployment details
and steps to reproduce the issue. Remove patient data and credentials from logs;
do not post private datasets or active secrets publicly. The project does not
guarantee a response deadline or a fixed support period.

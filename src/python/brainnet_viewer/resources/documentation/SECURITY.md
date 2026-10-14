# Security and supported deployment

Web is for **one trusted user on a private local machine**, with loopback port
publication. Shared-user hosts, JupyterHub, shared network namespaces, public
hosting and untrusted local processes require separate authentication and are
not supported by this local server.

Host/Origin checks and a per-start random WebSocket secret protect against
cross-site browser requests, not operating-system users. A local process can
forge Origin and obtain a key. Neither loopback nor bootstrap is user isolation.
Use pinned dependencies and `pip check`; unsupported Web clients fail closed.
Source updates do not upgrade existing packages or running containers.

Report sensitive issues privately to Mingrui Xia: mxia@bnu.edu.cn or
mingruixia@gmail.com. Include version/commit, platform, deployment and minimal
steps. Remove patient data and credentials from logs; never post private datasets
or live secrets publicly. No response deadline or support lifetime is guaranteed.

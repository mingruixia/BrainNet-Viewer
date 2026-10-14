# Security and supported deployment

The Web edition is intended for **one trusted user on a private local computer**.
Publish its port on the loopback interface only. Shared-user computers,
JupyterHub, shared network namespaces and public hosting require authentication
and user isolation that this local server does not provide. The same restriction
applies if untrusted processes can run on the computer.

Host and Origin checks, together with a new random WebSocket secret at each
startup, protect against cross-site browser requests. They do not authenticate
operating-system users: a local process can forge an Origin header and obtain a
key. Binding to loopback does not resolve this limitation.

Use the pinned dependencies and run `pip check` after installation. The server
rejects unsupported Web clients. Source updates do not upgrade previously
installed packages or running containers.

Report sensitive issues privately to Mingrui Xia at mxia@bnu.edu.cn or
mingruixia@gmail.com. Include the version or commit, platform, deployment details
and steps to reproduce the issue. Remove patient data and credentials from logs;
do not post private datasets or active secrets publicly. The project does not
guarantee a response deadline or a fixed support period.

# SPDX-License-Identifier: GPL-3.0-or-later
"""Same-origin browser bootstrap for the local, single-user aiohttp server."""
from pathlib import Path
import secrets
from urllib.parse import urlsplit


def authority(value, scheme="http"):
    """Accept only literal loopback authorities, not suffixes or userinfo."""
    try:
        parsed = urlsplit(f"{scheme}://{value}")
        if parsed.hostname not in ("127.0.0.1", "localhost", "::1"):
            raise ValueError("Non-loopback host")
        if parsed.username or parsed.password or parsed.path or parsed.query or parsed.fragment:
            raise ValueError("Invalid authority")
        port = parsed.port or (443 if scheme == "https" else 80)
        if not 1 <= port <= 65535:
            raise ValueError("Invalid port")
        return parsed.hostname, port
    except (ValueError, TypeError) as error:
        raise ValueError("Unsupported local Host header.") from error


def permitted(host, origin, *, scheme="http", require_origin=False):
    try:
        expected = authority(host, scheme)
        if not origin:
            return not require_origin
        parsed = urlsplit(origin)
        if parsed.scheme != scheme or parsed.path or parsed.query or parsed.fragment:
            return False
        return authority(parsed.netloc, parsed.scheme) == expected
    except (TypeError, ValueError):
        return False


def install(server):
    """Attach through the SDK bind lifecycle; never patch installed SDK files."""
    if getattr(server, "_bnv_security_installed", False):
        return
    from aiohttp import web
    token = secrets.token_urlsafe(32)
    server.cli.set_defaults(authKey=token, authKeyFile="")

    @web.middleware
    async def guard(request, handler):
        sensitive = request.method not in ("GET", "HEAD") or request.headers.get("Upgrade", "").lower() == "websocket"
        if not permitted(request.headers.get("Host", ""), request.headers.get("Origin"),
                         scheme=request.scheme, require_origin=sensitive):
            raise web.HTTPForbidden(text="Local same-origin access required.")
        site = request.headers.get("Sec-Fetch-Site", "")
        top_navigation = request.headers.get("Sec-Fetch-Mode") == "navigate" and request.headers.get("Sec-Fetch-Dest") == "document"
        if site in ("cross-site", "same-site") and not top_navigation:
            raise web.HTTPForbidden(text="Cross-origin resource access denied.")
        response = await handler(request)
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        response.headers["Content-Security-Policy"] = "frame-ancestors 'none'"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    def bind(bound):
        app = bound.app
        app.middlewares.append(guard)
        # The SDK's documented launcher bootstrap supplies the secret in a POST
        # response, never a URL/query string, shared state, log or persistent file.
        server.protocol.updateSecret(token)
        index = Path(server._www) / "index.html"
        html = index.read_text(encoding="utf-8")
        if "<html " not in html or "data-session-manager-url=" in html:
            raise RuntimeError("Unsupported trame client bootstrap; refusing insecure startup.")
        html = html.replace("<html ", '<html data-session-manager-url="/bnv-session" ', 1)

        async def page(_request):
            return web.Response(text=html, content_type="text/html", headers={"Cache-Control": "no-store"})

        async def session(request):
            if len(await request.content.read(4097)) > 4096:
                raise web.HTTPRequestEntityTooLarge(max_size=4096, actual_size=4097)
            protocol = "wss" if request.scheme == "https" else "ws"
            return web.json_response({"sessionURL": f"{protocol}://{request.host}/ws", "secret": token},
                                     headers={"Cache-Control": "no-store"})

        app.router.add_get("/index.html", page)
        app.router.add_post("/bnv-session", session)

    server.controller.on_server_bind.add(bind)
    server._bnv_security_installed = True

# SPDX-License-Identifier: GPL-3.0-or-later
"""Authenticated Linux LAN gateway with one process per browser cookie session."""
import argparse
import asyncio
from collections import OrderedDict, deque
from dataclasses import dataclass
import hashlib
import hmac
import ipaddress
import logging
from pathlib import Path
import ssl
import sys
import time
from urllib.parse import urlsplit

from aiohttp import ClientError, ClientSession, ClientTimeout, DummyCookieJar, WSMsgType, web
from .web_sessions import ProcessLauncher, SessionPool

COOKIE = 'bnv_browser_session'
MAX_MESSAGE = 72 * 1024 * 1024
LOG = logging.getLogger(__name__)


def loopback(value):
    try:
        return value == 'localhost' or ipaddress.ip_address(value).is_loopback
    except ValueError:
        return False


def parse_origin(value):
    parsed = urlsplit(value)
    if (parsed.scheme not in ('http', 'https') or not parsed.hostname or
            parsed.username is not None or parsed.password is not None or
            parsed.path or parsed.query or parsed.fragment or
            '\\' in value or any(c.isspace() for c in value)):
        raise ValueError('Use one explicit http(s) origin without a path or credentials.')
    port = parsed.port if parsed.port is not None else (443 if parsed.scheme == 'https' else 80)
    if not 1 <= port <= 65535:
        raise ValueError('Invalid server port.')
    return parsed.scheme, parsed.hostname.lower(), port


@dataclass(frozen=True)
class ServerConfig:
    origin: str
    maximum: int = 4
    idle_seconds: int = 1800
    startup_seconds: int = 90
    threads: int = 2
    login_attempts: int = 10
    login_window: int = 60

    def __post_init__(self):
        scheme, host, _ = parse_origin(self.origin)
        if scheme == 'http' and not loopback(host):
            raise ValueError('LAN server access requires HTTPS.')
        for value, low, high in ((self.maximum, 1, 32), (self.idle_seconds, 30, 86400),
                                 (self.startup_seconds, 5, 300), (self.threads, 1, 64),
                                 (self.login_attempts, 1, 100), (self.login_window, 10, 3600)):
            if type(value) is not int or not low <= value <= high:
                raise ValueError('Server resource settings are outside supported bounds.')


def allowed_request(request, config):
    """Validate the actual connection. Forwarded headers never grant access."""
    try:
        expected = parse_origin(config.origin)
        if parse_origin(f'{request.scheme}://{request.host}') != expected:
            return False
        sensitive = (request.method not in ('GET', 'HEAD') or
                     request.headers.get('Upgrade', '').lower() == 'websocket')
        origin = request.headers.get('Origin')
        if sensitive and not origin:
            return False
        if origin and parse_origin(origin) != expected:
            return False
        site = request.headers.get('Sec-Fetch-Site', '')
        navigation = (request.method in ('GET', 'HEAD') and
                      request.headers.get('Sec-Fetch-Mode') == 'navigate' and
                      request.headers.get('Sec-Fetch-Dest') == 'document')
        return site not in ('cross-site', 'same-site') or navigation
    except (ValueError, TypeError):
        return False


class LoginLimiter:
    """Bounded rate limits on socket peers, not untrusted forwarded IP headers."""
    def __init__(self, attempts=10, window=60):
        self.peers = OrderedDict()
        self.global_attempts = deque()
        self.attempts, self.window = attempts, window
        self.notices = OrderedDict()

    @staticmethod
    def group(peer):
        try:
            address = ipaddress.ip_address(peer)
            return str(ipaddress.ip_network(f'{address}/64', strict=False)) if address.version == 6 else str(address)
        except ValueError:
            return 'unknown'

    def report_limit(self, peer):
        peer, now = self.group(peer), time.monotonic()
        last = self.notices.pop(peer, -float('inf'))
        self.notices[peer] = now if now - last >= self.window else last
        while len(self.notices) > 256:
            self.notices.popitem(last=False)
        return now - last >= self.window

    def accept(self, peer, now=None, *, record=True):
        now = time.monotonic() if now is None else now
        peer = self.group(peer)
        while self.global_attempts and self.global_attempts[0] <= now - self.window:
            self.global_attempts.popleft()
        attempts = self.peers.pop(peer, deque())
        while attempts and attempts[0] <= now - self.window:
            attempts.popleft()
        self.peers[peer] = attempts
        while len(self.peers) > 256:
            self.peers.popitem(last=False)
        if len(attempts) >= self.attempts or len(self.global_attempts) >= self.attempts * 10:
            return False
        if record:
            attempts.append(now)
            self.global_attempts.append(now)
        return True


def login_page(message=''):
    # Only fixed application messages belong here, never request-derived HTML.
    return web.Response(text=f'''<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BrainNet Viewer Server</title><style>
body{{font:16px Arial,sans-serif;background:#f3f6fb;color:#0b2855;margin:0}}
main{{max-width:420px;margin:12vh auto;padding:28px;background:white;border:1px solid #d6deeb;border-radius:8px}}
h1{{font-size:24px}}input,button{{box-sizing:border-box;width:100%;padding:12px;margin-top:12px;font-size:16px}}
button{{background:#075fe4;color:white;border:0;border-radius:4px}}p{{line-height:1.5}}
</style></head><body><main><h1>BrainNet Viewer</h1>
<p>Sign in to start your browser session. Save your Scene before signing out.</p>
<p role="alert">{message}</p><form action="/_bnv/login" method="post">
<label for="password">Server access password</label>
<input id="password" name="password" type="password" required maxlength="256" autocomplete="current-password">
<button type="submit">Sign in</button></form></main></body></html>''',
        content_type='text/html')


def create_server(config, password, *, launcher=None):
    if (not isinstance(password, str) or not 16 <= len(password.encode('utf-8')) <= 256
            or any(character in password for character in ('\r', '\n', '\0'))):
        raise ValueError('The server password must contain 16 to 256 UTF-8 bytes.')
    digest = hashlib.sha256(password.encode('utf-8')).digest()
    limiter = LoginLimiter(config.login_attempts, config.login_window)
    pool = None
    client = None
    janitor = None

    def response_headers(request, response):
        static = (request.method in ('GET', 'HEAD') and response.status in (200, 304)
                  and not request.path.startswith('/_bnv/')
                  and Path(request.path).suffix in ('.js', '.css', '.woff', '.woff2')
                  and pool is not None and pool.find(request.cookies.get(COOKIE, '')) is not None)
        headers = {'Cache-Control': 'no-store',
                   'Cross-Origin-Resource-Policy': 'same-origin',
                   'Content-Security-Policy': "frame-ancestors 'none'",
                   'X-Content-Type-Options': 'nosniff',
                   'Referrer-Policy': 'no-referrer'}
        if static:
            headers['Cache-Control'] = 'private, max-age=3600'
            headers['Vary'] = 'Cookie'
        if request.path in ('/_bnv/login', '/_bnv/session'):
            # no-referrer makes browser form POSTs send Origin:null, which our
            # strict origin guard must reject. Keep origins for same-origin forms.
            headers['Referrer-Policy'] = 'same-origin'
            headers['Content-Security-Policy'] = "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"
        if config.origin.startswith('https://'):
            headers['Strict-Transport-Security'] = 'max-age=31536000'
        return headers

    @web.middleware
    async def security(request, handler):
        if not allowed_request(request, config):
            raise web.HTTPForbidden(text='Use the configured server address and same-origin requests.')
        try:
            response = await handler(request)
        except web.HTTPException as error:
            error.headers.update(response_headers(request, error))
            raise
        response.headers.update(response_headers(request, response))
        return response

    app = web.Application(middlewares=[security], client_max_size=4096)

    async def prepared(request, response):
        # Streaming and WebSocket responses send headers before middleware returns.
        response.headers.update(response_headers(request, response))

    app.on_response_prepare.append(prepared)

    async def cleanup_context(_app):
        nonlocal pool, client, janitor
        client = ClientSession(cookie_jar=DummyCookieJar(),
                               trust_env=False, auto_decompress=False,
                               timeout=ClientTimeout(total=None, sock_connect=5, sock_read=120))
        pool = SessionPool(client, maximum=config.maximum, idle_seconds=config.idle_seconds,
                           startup_seconds=config.startup_seconds,
                           launcher=launcher or ProcessLauncher(config.threads))

        async def clean_idle():
            while True:
                await asyncio.sleep(5)
                await pool.reap()

        janitor = asyncio.create_task(clean_idle())
        yield
        janitor.cancel()
        await asyncio.gather(janitor, return_exceptions=True)
        await pool.close()
        await client.close()

    app.cleanup_ctx.append(cleanup_context)

    def current(request):
        return pool.find(request.cookies.get(COOKIE, ''))

    async def login(request):
        if request.method == 'GET':
            return login_page()
        existing = current(request)
        if existing is not None:
            existing.activity = time.monotonic()
            raise web.HTTPSeeOther(location='/index.html')
        if not limiter.accept(request.remote or '', record=False):
            if limiter.report_limit(request.remote or ''):
                LOG.warning('login rate-limited peer=%s', request.remote or 'unknown')
            raise web.HTTPTooManyRequests(text='Too many sign-in attempts. Try again in a minute.',
                                         headers={'Retry-After': str(config.login_window)})
        if request.content_type != 'application/x-www-form-urlencoded':
            raise web.HTTPUnsupportedMediaType()
        fields = await request.post()
        if list(fields.keys()) != ['password'] or len(fields.getall('password')) != 1:
            raise web.HTTPBadRequest(text='Submit one password field.')
        supplied = fields['password']
        if not isinstance(supplied, str) or not hmac.compare_digest(
                hashlib.sha256(supplied.encode('utf-8')).digest(), digest):
            response = login_page('Incorrect password.')
            response.set_status(401)
            limiter.accept(request.remote or '')
            LOG.warning('login failed peer=%s', request.remote or 'unknown')
            return response
        # Successful logins do not consume failure quota, including shared NATs.
        try:
            item = existing or pool.allocate()
        except RuntimeError as error:
            raise web.HTTPServiceUnavailable(text=str(error), headers={'Retry-After': '30'})
        response = web.HTTPSeeOther(location='/index.html')
        LOG.info('login ok peer=%s audit=%s', request.remote or 'unknown', item.audit_id)
        response.set_cookie(COOKIE, item.key, httponly=True,
                            secure=config.origin.startswith('https://'), samesite='Strict', path='/')
        raise response

    async def activity(request):
        item = current(request)
        if item is None:
            raise web.HTTPUnauthorized(text='Browser session ended. Sign in again.')
        if request.method == 'POST':
            item.activity = time.monotonic()
            return web.Response(status=204)
        return web.json_response({'remaining': max(0, int(config.idle_seconds -
                                 (time.monotonic() - item.activity))),
                                  'warning': min(60, config.idle_seconds // 3),
                                  'busy': bool(item.requests or time.monotonic() < item.busy_until
                                               or item.task and not item.task.done())})

    async def session_control(request):
        item = current(request)
        if item is None:
            raise web.HTTPSeeOther(location='/_bnv/login')
        if request.method == 'POST':
            await pool.remove(item)
            response = web.HTTPSeeOther(location='/_bnv/login')
            response.del_cookie(COOKIE, path='/')
            raise response
        return web.Response(text='''<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>BrainNet Viewer session</title></head><body><h1>Browser session</h1>
<p>Tabs in this browser share this session. Other browser sessions use separate processes.</p>
<p>Save your Scene before signing out. Unsaved files and settings will be removed.</p>
<p><a href="/index.html">Return to BrainNet Viewer</a></p>
<form action="/_bnv/session" method="post"><button type="submit">Sign out and end session</button></form>
</body></html>''', content_type='text/html')

    async def websocket(request, item, worker):
        upstream = await client.ws_connect(worker.origin + request.rel_url.raw_path_qs,
            headers={'Host': urlsplit(worker.origin).netloc, 'Origin': worker.origin,
                     'X-BNV-Worker-Token': worker.token, 'Sec-Fetch-Site': 'same-origin'},
            max_msg_size=MAX_MESSAGE, autoping=True)
        downstream = web.WebSocketResponse(max_msg_size=MAX_MESSAGE, autoping=True)
        tasks = []
        item.sockets.add(downstream)
        item.upstreams.add(upstream)
        try:
            await downstream.prepare(request)

            async def pump(source, target, *, from_browser=False):
                async for message in source:
                    # Bounded lookahead only, not a second 72 MiB message decode.
                    # User-triggered scientific jobs get a finite five-minute grace;
                    # server frames and heartbeat traffic never count as UI activity.
                    if from_browser and message.type in (WSMsgType.TEXT, WSMsgType.BINARY):
                        prefix = message.data[:256]
                        needle = 'trame.trigger' if isinstance(prefix, str) else b'trame.trigger'
                        if needle in prefix:
                            item.busy_until = time.monotonic() + 300
                    if message.type == WSMsgType.TEXT:
                        await target.send_str(message.data)
                    elif message.type == WSMsgType.BINARY:
                        await target.send_bytes(message.data)
                    elif message.type in (WSMsgType.ERROR, WSMsgType.CLOSE, WSMsgType.CLOSED):
                        break

            # The current request task is the only reader of the server socket.
            async def from_worker():
                try:
                    await pump(upstream, downstream)
                finally:
                    code = upstream.close_code or 1000
                    await downstream.close(code=1011 if code in (1005, 1006, 1015) else code)

            remote = asyncio.create_task(from_worker())
            tasks.append(remote)
            await pump(downstream, upstream, from_browser=True)
        finally:
            # Complete the client close handshake before cancelling its reader.
            await upstream.close()
            for task in tasks:
                task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)
            await downstream.close()
            item.sockets.discard(downstream)
            item.upstreams.discard(upstream)
        return downstream

    async def proxy(request):
        item = current(request)
        if item is None:
            if request.method in ('GET', 'HEAD') and request.headers.get('Upgrade', '').lower() != 'websocket':
                raise web.HTTPSeeOther(location='/_bnv/login')
            raise web.HTTPUnauthorized(text='Sign in before using this browser session.')
        # Trame static files, session bootstrap and one WebSocket only.
        if request.path.startswith('/_bnv/') or request.method not in ('GET', 'HEAD', 'POST'):
            raise web.HTTPNotFound()
        if request.method == 'POST' and request.path != '/bnv-session':
            raise web.HTTPNotFound()
        item.requests += 1
        item.touched = time.monotonic()
        try:
            worker = await pool.ready(item)
            if request.headers.get('Upgrade', '').lower() == 'websocket':
                if request.path != '/ws':
                    raise web.HTTPNotFound()
                # A live connection is not an in-flight scientific request.
                item.requests -= 1
                try:
                    return await websocket(request, item, worker)
                finally:
                    item.requests += 1
            if request.path in ('/', '/index.html'):
                item.activity = time.monotonic()
            headers = {'Host': urlsplit(worker.origin).netloc, 'Origin': worker.origin,
                       'X-BNV-Worker-Token': worker.token, 'Sec-Fetch-Site': 'same-origin',
                       'Accept-Encoding': 'identity'}
            body = await request.read() if request.method == 'POST' else None
            if request.method == 'POST':
                headers['Content-Type'] = request.headers.get('Content-Type', 'application/json')
            for name in ('If-None-Match', 'If-Modified-Since'):
                if name in request.headers:
                    headers[name] = request.headers[name]
            async with client.request(request.method, worker.origin + request.rel_url.raw_path_qs,
                                      headers=headers, data=body, allow_redirects=False) as upstream:
                if request.method == 'POST' and request.path == '/bnv-session':
                    if upstream.status != 200:
                        raise web.HTTPBadGateway(text='Session bootstrap failed.')
                    value = await upstream.json()
                    protocol = 'wss' if config.origin.startswith('https://') else 'ws'
                    # Browser-visible address must never expose a worker port.
                    value['sessionURL'] = protocol + '://' + urlsplit(config.origin).netloc + '/ws'
                    return web.json_response(value)
                if upstream.status == 200 and request.path in ('/', '/index.html'):
                    # read(n) may return only the first network chunk. Wait for
                    # EOF while retaining the strict bootstrap-size ceiling.
                    try:
                        payload = await upstream.content.readexactly(1024 * 1024 + 1)
                    except asyncio.IncompleteReadError as error:
                        payload = error.partial
                    if len(payload) > 1024 * 1024:
                        raise web.HTTPBadGateway(text='Application bootstrap is too large.')
                    if 'text/html' in upstream.headers.get('Content-Type', ''):
                        payload = payload.replace(b'</head>', b'<script src="/_bnv/activity.js" defer></script></head>', 1)
                        return web.Response(body=payload, content_type='text/html')
                    return web.Response(body=payload, content_type=upstream.content_type)
                if 300 <= upstream.status < 400 and upstream.status != 304:
                    raise web.HTTPBadGateway(text='Unexpected worker redirect.')
                copied = {name: value for name, value in upstream.headers.items()
                          if name.lower() in ('content-type', 'content-length', 'content-encoding', 'etag', 'last-modified')}
                response = web.StreamResponse(status=upstream.status, headers=copied)
                await response.prepare(request)
                async for chunk in upstream.content.iter_chunked(65536):
                    await response.write(chunk)
                await response.write_eof()
                return response
        except (ClientError, asyncio.TimeoutError, RuntimeError):
            LOG.warning('Browser worker request failed; scientific session data is not logged.')
            raise web.HTTPBadGateway(text='Browser worker unavailable. Return to the sign-in page.')
        finally:
            item.requests -= 1
            item.touched = time.monotonic()

    async def health(_request):
        return web.json_response({'status': 'ready'})

    app.router.add_get('/_bnv/health', health)
    async def client_script(_request):
        return web.Response(text=Path(__file__).with_name('web_session_client.js').read_text(encoding='utf-8'),
                            content_type='application/javascript')
    app.router.add_get('/_bnv/activity.js', client_script)
    app.router.add_post('/_bnv/activity', activity)
    app.router.add_get('/_bnv/status', activity)
    app.router.add_route('GET', '/_bnv/login', login)
    app.router.add_route('POST', '/_bnv/login', login)
    app.router.add_route('GET', '/_bnv/session', session_control)
    app.router.add_route('POST', '/_bnv/session', session_control)
    app.router.add_route('*', '/{path:.*}', proxy)
    # Test/embedding access without exposing sessions through an HTTP endpoint.
    app[web.AppKey('session_pool', object)] = lambda: pool
    return app


def arguments(argv=None):
    parser = argparse.ArgumentParser(description='BrainNet Viewer Linux browser-session server.')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=1031)
    parser.add_argument('--public-origin', required=True)
    parser.add_argument('--password-file', type=Path, required=True)
    parser.add_argument('--cert', type=Path)
    parser.add_argument('--key', type=Path)
    parser.add_argument('--allow-local-http', action='store_true',
                        help='Development only: HTTP on a literal loopback bind and origin.')
    parser.add_argument('--max-sessions', type=int, default=4)
    parser.add_argument('--idle-seconds', type=int, default=1800)
    parser.add_argument('--startup-seconds', type=int, default=90)
    parser.add_argument('--worker-threads', type=int, default=2)
    parser.add_argument('--login-attempts', type=int, default=10)
    parser.add_argument('--login-window', type=int, default=60)
    parser.add_argument('--log-level', choices=('INFO', 'WARNING', 'ERROR'), default='INFO')
    args = parser.parse_args(argv)
    try:
        config = ServerConfig(args.public_origin, args.max_sessions, args.idle_seconds,
                              args.startup_seconds, args.worker_threads,
                              args.login_attempts, args.login_window)
        scheme, host, _ = parse_origin(args.public_origin)
        if not 1 <= args.port <= 65535:
            raise ValueError('Listening port must be between 1 and 65535.')
        local_host, local_bind = loopback(host), loopback(args.host)
        if scheme == 'http':
            if not (args.allow_local_http and local_host and local_bind) or args.cert or args.key:
                raise ValueError('LAN server access requires HTTPS and a certificate/key pair.')
        elif not args.cert or not args.key:
            raise ValueError('HTTPS requires both --cert and --key.')
    except ValueError as error:
        parser.error(str(error))
    return args, config


def main(argv=None):
    args, config = arguments(argv)
    if sys.platform != 'linux':
        raise RuntimeError('Server deployment is supported on Linux; local Web mode remains available.')
    logging.basicConfig(level=args.log_level, format='%(asctime)s %(levelname)s %(name)s %(message)s')
    context = None
    try:
        if args.password_file.stat().st_size > 258:
            raise ValueError('Server password file is too large.')
        password = args.password_file.read_text(encoding='utf-8').rstrip('\r\n')
        if len(set(password)) < 5 or password.isdecimal():
            LOG.warning('Server password appears weak. Generate a random team access password.')
        if args.cert:
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.minimum_version = ssl.TLSVersion.TLSv1_2
            context.load_cert_chain(args.cert, args.key)
        app = create_server(config, password)
    except (OSError, ValueError, UnicodeError) as error:
        raise SystemExit(f'Server configuration unavailable ({type(error).__name__}); check password and TLS files.') from None
    web.run_app(app, host=args.host, port=args.port,
                ssl_context=context, access_log=None, shutdown_timeout=10)


if __name__ == '__main__':
    main()

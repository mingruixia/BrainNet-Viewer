# SPDX-License-Identifier: GPL-3.0-or-later
"""Unraid defaults: trusted-LAN HTTP, anonymous per-browser processes."""
import os
import ssl
import urllib.request
from .web_server import main as server_main


def command(environ=None):
    env = os.environ if environ is None else environ
    scheme = env.get('BNV_SCHEME', 'http').strip().lower()
    auth = env.get('BNV_PASSWORD_AUTH', 'off').strip().lower()
    if scheme not in ('http', 'https') or auth not in ('off', 'on'):
        raise ValueError('BNV_SCHEME must be http/https and BNV_PASSWORD_AUTH off/on.')
    args = ['--trusted-lan', '--host', '0.0.0.0', '--port', '1031',
            '--max-sessions', env.get('BNV_MAX_SESSIONS', '4'),
            '--idle-seconds', env.get('BNV_IDLE_SECONDS', '1800'),
            '--worker-threads', env.get('BNV_WORKER_THREADS', '2')]
    origin = env.get('BNV_SERVER_ORIGIN', '').strip()
    if origin:
        if not origin.startswith(scheme + '://'):
            raise ValueError('Public origin must match BNV_SCHEME.')
        args += ['--public-origin', origin]
    if scheme == 'https':
        if not origin:
            raise ValueError('HTTPS requires an explicit BNV_SERVER_ORIGIN.')
        args += ['--cert', '/run/bnv-secrets/server.crt', '--key', '/run/bnv-secrets/server.key']
    if auth == 'on':
        args += ['--password-file', '/run/bnv-secrets/access_password.txt']
    return args


def main():
    try:
        args = command()
    except ValueError as error:
        raise SystemExit(str(error)) from None
    server_main(args)


def healthcheck():
    """Gateway readiness only; TLS bypass is confined to container loopback."""
    scheme = os.environ.get('BNV_SCHEME', 'http').strip().lower()
    origin = os.environ.get('BNV_SERVER_ORIGIN', '').strip()
    from urllib.parse import urlsplit
    host = urlsplit(origin).netloc if origin else '127.0.0.1:1031'
    context = ssl._create_unverified_context() if scheme == 'https' else None
    handlers = [urllib.request.ProxyHandler({})]
    if context:
        handlers.append(urllib.request.HTTPSHandler(context=context))
    opener = urllib.request.build_opener(*handlers)
    request = urllib.request.Request(scheme + '://127.0.0.1:1031/_bnv/health', headers={'Host':host})
    with opener.open(request, timeout=3) as response:
        if response.status != 200:
            raise RuntimeError('Gateway not ready')


if __name__ == '__main__':
    main()

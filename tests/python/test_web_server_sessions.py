# SPDX-License-Identifier: GPL-3.0-or-later
"""LAN gateway guards and real subprocess lifecycle; no GUI/Mac claims."""
import asyncio
import contextlib
import io
import os
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from aiohttp import ClientSession, ClientTimeout, CookieJar, web
from aiohttp.test_utils import TestServer
from brainnet_viewer.web_server import (
    COOKIE, LoginLimiter, ServerConfig, allowed_request, arguments, create_server, parse_origin)
from brainnet_viewer.web_sessions import ProcessLauncher

PASSWORD = 'test-password-not-for-deployment'


class FixtureLauncher(ProcessLauncher):
    def command(self, port):
        import sys
        fixture = Path(__file__).resolve().parents[1] / 'security/session_worker_fixture.py'
        return [sys.executable, str(fixture), str(port)]


class ServerConfigTests(unittest.TestCase):
    def test_origin_validation(self):
        for value in ('http://host:0', 'https://a/path', 'https://user@host', 'https://a/#x',
                      'ftp://host', 'https://a\\b', 'https://a b', 'https://a:65536'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_origin(value)
        self.assertEqual(parse_origin('https://[::1]:1031'), ('https', '::1', 1031))
        for value in (0, 33, True):
            with self.assertRaises(ValueError): ServerConfig('https://192.168.1.10:1031', maximum=value)
        with self.assertRaises(ValueError): ServerConfig('http://192.168.1.10:1031')

    def test_actual_origin_not_forwarded_headers(self):
        config = ServerConfig('https://192.168.1.10:1031')
        request = SimpleNamespace(scheme='https', host='192.168.1.10:1031', method='POST',
                                  headers={'Origin': config.origin})
        self.assertTrue(allowed_request(request, config))
        request.headers = {'Origin': 'http://evil.invalid', 'X-Forwarded-Proto': 'https',
                           'X-Forwarded-Host': '192.168.1.10:1031'}
        self.assertFalse(allowed_request(request, config))
        request.headers = {}
        self.assertFalse(allowed_request(request, config))
        request.method = 'GET'
        request.headers = {'Upgrade': 'websocket'}
        self.assertFalse(allowed_request(request, config))
        request.headers = {'Origin': config.origin, 'Sec-Fetch-Site': 'cross-site'}
        self.assertFalse(allowed_request(request, config))

    def test_no_cleartext_lan_or_implicit_tls(self):
        common = ['--password-file', 'unused', '--public-origin', 'http://192.168.1.10:1031']
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit): arguments(common + ['--allow-local-http'])
            with self.assertRaises(SystemExit): arguments(['--password-file', 'unused', '--public-origin',
                                                          'https://192.168.1.10:1031'])
        args, _ = arguments(['--password-file', 'unused', '--public-origin', 'http://127.0.0.1:1031',
                             '--host', '127.0.0.1', '--allow-local-http'])
        self.assertEqual(args.port, 1031)

    def test_password_never_optional_or_short(self):
        for value in ('short', '', 'a' * 257, 'long-but\nmultiline-password'):
            with self.assertRaises(ValueError): create_server(ServerConfig('https://192.168.1.10'), value)

    def test_bounded_login_attempts(self):
        limiter = LoginLimiter()
        self.assertTrue(all(limiter.accept('one', now=0) for _ in range(5)))
        self.assertFalse(limiter.accept('one', now=1))
        self.assertTrue(limiter.accept('one', now=61))
        for i in range(400): limiter.accept(str(i), now=62)
        self.assertLessEqual(len(limiter.peers), 256)


class GatewayProcessTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        # TestServer chooses a free port; no LAN binding or certificate mutation.
        self.server = TestServer(web.Application())
        await self.server.start_server()
        port = self.server.port
        await self.server.close()
        self.origin = f'http://127.0.0.1:{port}'
        self.app = create_server(ServerConfig(self.origin, maximum=2, idle_seconds=30,
                                              startup_seconds=10), PASSWORD,
                                 launcher=FixtureLauncher(threads=1))
        self.server = TestServer(self.app, port=port)
        await self.server.start_server()
        self.a = ClientSession(cookie_jar=CookieJar(unsafe=True), timeout=ClientTimeout(total=20))
        self.b = ClientSession(cookie_jar=CookieJar(unsafe=True), timeout=ClientTimeout(total=20))
        self.pool = next(v for k, v in self.app.items() if getattr(k, '_name', '').endswith('session_pool'))()

    async def asyncTearDown(self):
        await self.a.close()
        await self.b.close()
        await self.server.close()

    async def login(self, client):
        async with client.post(self.origin + '/_bnv/login', data={'password': PASSWORD},
                               headers={'Origin': self.origin}, allow_redirects=False) as response:
            self.assertEqual(response.status, 303)
            cookie = response.cookies[COOKIE]
            self.assertTrue(cookie['httponly'])
            self.assertEqual(cookie['samesite'], 'Strict')
            return cookie.value

    async def index(self, client):
        async with client.get(self.origin + '/index.html') as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers['Cache-Control'], 'no-store')
            return await response.json()

    async def bootstrap(self, client):
        async with client.post(self.origin + '/bnv-session',
                               headers={'Origin': self.origin}) as response:
            self.assertEqual(response.status, 200)
            result = await response.json()
            self.assertEqual(result['sessionURL'], self.origin.replace('http:', 'ws:') + '/ws')
            return result['secret']

    async def test_two_browsers_same_ip_isolate_state_files_secrets_and_pids(self):
        ka, kb = await self.login(self.a), await self.login(self.b)
        a, b = await asyncio.gather(self.index(self.a), self.index(self.b))
        self.assertNotEqual(ka, kb)
        self.assertNotEqual(a['pid'], b['pid'])
        self.assertNotEqual(a['cwd'], b['cwd'])
        self.assertFalse(a['cookie_received'])
        sa, sb = await self.bootstrap(self.a), await self.bootstrap(self.b)
        self.assertNotEqual(sa, sb)
        ws = await self.a.ws_connect(self.origin + '/ws', headers={'Origin': self.origin})
        await ws.send_str(sa)
        self.assertEqual((await ws.receive()).data, 'authenticated')
        await ws.send_str('23')
        self.assertEqual((await ws.receive()).data, '23')
        self.assertEqual((await self.index(self.a))['value'], 23)
        self.assertEqual((await self.index(self.b))['value'], 0)
        self.assertTrue(Path(a['cwd'], 'uploaded.txt').is_file())
        self.assertFalse(Path(b['cwd'], 'uploaded.txt').exists())
        # Refresh and another tab with the same cookie reuse exactly this worker.
        self.assertEqual((await self.index(self.a))['pid'], a['pid'])
        async with self.b.get(self.pool.find(kb).worker.origin + '/index.html') as response:
            self.assertEqual(response.status, 403)
        async with self.b.get(self.pool.find(kb).worker.origin + '/index.html',
                              headers={'X-BNV-Worker-Token': self.pool.find(ka).worker.token}) as response:
            self.assertEqual(response.status, 403)
        await ws.close()
        async with self.a.post(self.origin + '/_bnv/session', headers={'Origin': self.origin},
                               allow_redirects=False) as response:
            self.assertEqual(response.status, 303)
        self.assertIsNone(self.pool.find(ka))
        self.assertFalse(Path(a['cwd']).exists())
        self.assertEqual((await self.index(self.b))['pid'], b['pid'])

    async def test_admission_auth_host_origin_and_unknown_session(self):
        async with self.a.get(self.origin + '/index.html', allow_redirects=False) as response:
            self.assertEqual(response.status, 303)
        for headers in ({}, {'Origin': 'http://evil.invalid'},
                        {'Origin': self.origin, 'Host': 'evil.invalid'}):
            async with self.a.post(self.origin + '/_bnv/login', data={'password': PASSWORD},
                                   headers=headers, allow_redirects=False) as response:
                self.assertEqual(response.status, 403)
        async with self.a.post(self.origin + '/_bnv/login', data={'password': 'wrong'},
                               headers={'Origin': self.origin}) as response:
            self.assertEqual(response.status, 401)
        self.assertEqual(len(self.pool.sessions), 0)
        await self.login(self.a)
        await self.login(self.b)
        async with ClientSession(timeout=ClientTimeout(total=20)) as third:
            async with third.post(self.origin + '/_bnv/login', data={'password': PASSWORD},
                                  headers={'Origin': self.origin}) as response:
                self.assertEqual(response.status, 503)
            async with third.post(self.origin + '/bnv-session',
                                  headers={'Origin': self.origin, 'Cookie': f'{COOKIE}=forged'}) as response:
                self.assertEqual(response.status, 401)
        self.assertEqual(len(self.pool.sessions), 2)

    async def test_idle_crash_and_cleanup(self):
        key = await self.login(self.a)
        a = await self.index(self.a)
        item = self.pool.find(key)
        item.touched = 0
        await self.pool.reap(now=31)
        self.assertIsNone(self.pool.find(key))
        self.assertIsNotNone(item.worker.process.returncode)
        self.assertFalse(Path(a['cwd']).exists())
        key = await self.login(self.b)
        await self.index(self.b)
        item = self.pool.find(key)
        item.worker.process.kill()
        await item.worker.process.wait()
        await self.pool.reap()
        self.assertIsNone(self.pool.find(key))

    async def test_concurrent_refresh_allocates_only_one_process(self):
        key = await self.login(self.a)
        results = await asyncio.gather(*(self.index(self.a) for _ in range(4)))
        self.assertEqual(len({item['pid'] for item in results}), 1)
        self.assertIsNotNone(self.pool.find(key).worker)

    async def test_other_session_secret_cannot_authenticate(self):
        await self.login(self.a)
        await self.login(self.b)
        await self.index(self.a)
        await self.index(self.b)
        secret = await self.bootstrap(self.a)
        async with self.b.ws_connect(self.origin + '/ws', headers={'Origin': self.origin}) as ws:
            await ws.send_str(secret)
            message = await ws.receive()
            self.assertEqual(message.type, __import__('aiohttp').WSMsgType.CLOSE)
            self.assertEqual(message.data, 1008)

    async def test_failed_startup_releases_admission_slot(self):
        class Failing(FixtureLauncher):
            def command(self, port):
                import sys
                return [sys.executable, '-c', 'raise SystemExit(9)']
        self.pool.launcher = Failing()
        await self.login(self.a)
        async with self.a.get(self.origin + '/index.html') as response:
            self.assertEqual(response.status, 502)
        self.assertEqual(len(self.pool.sessions), 0)

    async def test_connected_session_is_not_reaped_and_shutdown_closes_it(self):
        key = await self.login(self.a)
        a = await self.index(self.a)
        secret = await self.bootstrap(self.a)
        ws = await self.a.ws_connect(self.origin + '/ws', headers={'Origin': self.origin})
        await ws.send_str(secret)
        await ws.receive()
        item = self.pool.find(key)
        item.touched = 0
        await self.pool.reap(now=31)
        self.assertIs(self.pool.find(key), item)
        await self.pool.close()
        self.assertFalse(Path(a['cwd']).exists())
        self.assertIsNotNone(item.worker.process.returncode)
        await ws.close()

    async def test_worker_crash_with_connected_socket_is_cleaned(self):
        key = await self.login(self.a)
        await self.index(self.a)
        secret = await self.bootstrap(self.a)
        async with self.a.ws_connect(self.origin + '/ws', headers={'Origin': self.origin}) as ws:
            await ws.send_str(secret)
            await ws.receive()
            worker = self.pool.find(key).worker
            worker.process.kill()
            await worker.process.wait()
            await ws.receive()
            await self.pool.reap()
            self.assertIsNone(self.pool.find(key))

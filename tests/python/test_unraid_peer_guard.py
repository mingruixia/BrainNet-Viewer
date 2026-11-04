import contextlib
import io
import ipaddress
import unittest
from types import SimpleNamespace

from aiohttp import ClientSession, CookieJar, web
from aiohttp.test_utils import TestServer
from brainnet_viewer.web_server import (
    COOKIE, ServerConfig, allowed_request, anonymous_peer_allowed,
    arguments, create_server,
)
from brainnet_viewer.web_unraid import command


def request(peer, **headers):
    return SimpleNamespace(scheme='http', host='tower.local:1031', method='POST',
                           remote=peer, headers={'Origin': 'http://tower.local:1031', **headers})


class PeerGuardTests(unittest.TestCase):
    def test_actual_peers_and_forwarded_headers(self):
        config = ServerConfig('http://tower.local:1031', trusted_lan=True, anonymous=True)
        for peer in ('127.0.0.1', '::1', '192.168.2.7', '172.17.0.1', '10.43.4.13',
                     'fd00::23', '::ffff:192.168.2.7'):
            with self.subTest(peer=peer):
                self.assertTrue(allowed_request(request(peer), config))
        for peer in ('8.8.8.8', '100.101.102.3', '192.0.2.5', 'fe80::1', '::',
                     '0.0.0.0', '224.0.0.1', 'not-an-ip', None, 'fe80::1%eth0'):
            with self.subTest(peer=peer):
                self.assertFalse(allowed_request(request(peer, **{
                    'X-Forwarded-For': '192.168.2.7',
                    'Forwarded': 'for=192.168.2.7;proto=http;host=tower.local:1031',
                    'X-Real-IP': '192.168.2.7',
                }), config))
        self.assertFalse(allowed_request(request('192.168.2.7', Origin='http://evil.invalid'), config))

    def test_vpn_opt_in_keeps_origin_independent(self):
        _, config = arguments(command({
            'BNV_SERVER_ORIGIN': 'http://tower.local:1031',
            'BNV_ANONYMOUS_NETWORKS': '100.101.102.0/24, 2001:db8:42::/64',
        }))
        self.assertTrue(allowed_request(request('100.101.102.3'), config))
        self.assertTrue(allowed_request(request('2001:db8:42::3'), config))
        self.assertFalse(allowed_request(request('100.101.103.3'), config))
        self.assertFalse(allowed_request(request('100.101.102.3', Origin='http://other.local:1031'), config))
        auto = ServerConfig('auto', trusted_lan=True, anonymous=True,
                            anonymous_networks=('100.101.102.0/24',))
        req = request('100.101.102.3')
        req.host = '100.101.102.1:1031'
        req.headers = {'Origin': 'http://100.101.102.1:1031'}
        self.assertFalse(allowed_request(req, auto))
        self.assertTrue(anonymous_peer_allowed('::ffff:100.101.102.3', config.anonymous_networks))

    def test_invalid_network_settings_fail_before_startup(self):
        for networks in (['100.64.0.0/10'], ('',), ('not-a-network',), ('100.64.0.1/10',),
                         ('0.0.0.0/0',), ('::/0',), ('224.0.0.0/4',),
                         ('::ffff:192.168.2.0/120',), tuple(['10.0.0.0/8'] * 33)):
            with self.subTest(networks=networks), self.assertRaises(ValueError):
                ServerConfig('auto', trusted_lan=True, anonymous=True, anonymous_networks=networks)
        for value in ('100.64.0.0/10,', 'bad', 'x' * 4097):
            with self.subTest(value=value[:30]), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises((ValueError, SystemExit)):
                    arguments(command({'BNV_ANONYMOUS_NETWORKS': value}))

    def test_authenticated_mode_keeps_its_existing_admission(self):
        config = ServerConfig('http://tower.local:1031', trusted_lan=True, anonymous=False)
        self.assertTrue(allowed_request(request('8.8.8.8'), config))
        self.assertFalse(allowed_request(request('8.8.8.8', Origin='http://evil.invalid'), config))


class HTTPGuardTests(unittest.IsolatedAsyncioTestCase):
    async def test_refusal_before_allocation_and_real_proxy(self):
        config = ServerConfig('auto', trusted_lan=True, anonymous=True)
        app = create_server(config)

        @web.middleware
        async def controlled_transport_peer(req, handler):
            # Test-only transport fixture. Production never reads this header.
            return await handler(req.clone(remote=req.headers.get('X-Test-Peer', req.remote)))

        app.middlewares.insert(0, controlled_transport_peer)
        server = TestServer(app)
        await server.start_server()
        origin = str(server.make_url('')).rstrip('/')
        pool = next(value for key, value in app.items()
                    if getattr(key, '_name', '').endswith('session_pool'))()
        client = ClientSession(cookie_jar=CookieJar(unsafe=True))
        proxy_server = None
        try:
            async with client.post(origin + '/_bnv/start', headers={
                    'Origin': origin, 'X-Test-Peer': '8.8.8.8',
                    'X-Forwarded-For': '192.168.2.7'}, allow_redirects=False) as response:
                self.assertEqual(response.status, 403)
                self.assertIn('allowed client network', await response.text())
                self.assertNotIn(COOKIE, response.cookies)
            self.assertFalse(pool.sessions)

            async def forward(req):
                headers = dict(req.headers)
                # A same-origin HTTP proxy deliberately preserves browser Host/Origin.
                headers.pop('X-Test-Peer', None)
                async with client.request(req.method, origin + req.path_qs,
                                          headers=headers, data=await req.read(),
                                          allow_redirects=False) as response:
                    return web.Response(status=response.status, body=await response.read(),
                                        headers={key: value for key, value in response.headers.items()
                                                 if key.lower() not in ('content-length', 'transfer-encoding')})

            proxy = web.Application()
            proxy.router.add_route('*', '/{path:.*}', forward)
            proxy_server = TestServer(proxy)
            await proxy_server.start_server()
            proxy_origin = str(proxy_server.make_url('')).rstrip('/')
            async with client.post(proxy_origin + '/_bnv/start', headers={
                    'Origin': proxy_origin, 'X-Forwarded-For': '8.8.8.8'},
                    allow_redirects=False) as response:
                self.assertEqual(response.status, 303)
                self.assertIn(COOKIE, response.cookies)
            self.assertEqual(len(pool.sessions), 1)
            # A private proxy's public clients need upstream ACL/authentication.
            # The application intentionally does not interpret forwarded client headers.
        finally:
            if proxy_server is not None:
                await proxy_server.close()
            await client.close()
            await server.close()
        self.assertFalse(pool.sessions)


if __name__ == '__main__':
    unittest.main()

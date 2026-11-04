# SPDX-License-Identifier: GPL-3.0-or-later
"""Only the new explicit trusted-LAN admission and optional-auth paths."""
import contextlib
import io
import unittest
from types import SimpleNamespace
from aiohttp import ClientSession, CookieJar, web
from aiohttp.test_utils import TestServer
from brainnet_viewer.web_server import ServerConfig, allowed_request, arguments, create_server, COOKIE, private_address
from brainnet_viewer.web_unraid import command


class ModeTests(unittest.TestCase):
    def test_explicit_mode_and_advanced_switches(self):
        args, config = arguments(command({}))
        self.assertEqual(config.origin, 'auto')
        self.assertTrue(config.anonymous)
        self.assertIsNone(args.cert)
        self.assertIsNone(args.password_file)
        args, config = arguments(command({'BNV_SCHEME':'https','BNV_PASSWORD_AUTH':'on',
                                         'BNV_SERVER_ORIGIN':'https://tower.local:1031'}))
        self.assertFalse(config.anonymous)
        self.assertEqual(args.cert.as_posix(), '/run/bnv-secrets/server.crt')
        self.assertEqual(args.password_file.as_posix(), '/run/bnv-secrets/access_password.txt')
        _, password_http = arguments(command({'BNV_PASSWORD_AUTH':'on'}))
        self.assertFalse(password_http.anonymous)
        self.assertEqual(password_http.origin,'auto')
        _, anonymous_tls = arguments(command({'BNV_SCHEME':'https','BNV_SERVER_ORIGIN':'https://tower.local:1031'}))
        self.assertTrue(anonymous_tls.anonymous)
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            arguments(['--host','0.0.0.0','--public-origin','http://192.168.2.7:1031'])
        with self.assertRaises(ValueError):
            ServerConfig('auto')
        with self.assertRaises(ValueError):
            create_server(ServerConfig('https://tower.local'), None)

    def test_private_host_and_same_origin(self):
        config=ServerConfig('auto',trusted_lan=True,anonymous=True)
        for host in ['127.0.0.1','10.43.4.13','172.16.193.184','192.168.2.7','::1','fd00::1']:
            self.assertTrue(private_address(host),host)
        for host in ['0.0.0.0','::','8.8.8.8','192.0.2.7','169.254.1.1','evil.example','224.0.0.1']:
            self.assertFalse(private_address(host),host)
        request=SimpleNamespace(scheme='http',host='192.168.2.7:1045',method='POST',headers={'Origin':'http://192.168.2.7:1045'},remote='192.168.2.8')
        self.assertTrue(allowed_request(request,config))
        for headers in ({},{'Origin':'null'},{'Origin':'http://evil.invalid'},
                        {'Origin':'http://192.168.2.7:1031'},
                        {'Origin':'http://192.168.2.7:1045','Sec-Fetch-Site':'cross-site'}):
            request.headers=headers;self.assertFalse(allowed_request(request,config))
        request.headers={'Origin':'http://evil.invalid','X-Forwarded-Host':'192.168.2.7:1045'}
        request.host='evil.invalid:1045';self.assertFalse(allowed_request(request,config))


class AnonymousGatewayTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.app=create_server(ServerConfig('auto',maximum=2,trusted_lan=True,anonymous=True))
        self.server=TestServer(self.app);await self.server.start_server()
        self.origin=str(self.server.make_url('')).rstrip('/')
        self.a=ClientSession(cookie_jar=CookieJar(unsafe=True))
        self.b=ClientSession(cookie_jar=CookieJar(unsafe=True))
        self.pool=next(v for k,v in self.app.items() if getattr(k,'_name','').endswith('session_pool'))()

    async def asyncTearDown(self):
        await self.a.close();await self.b.close();await self.server.close()
        self.assertEqual(len(self.pool.sessions),0)

    async def start(self,client):
        async with client.post(self.origin+'/_bnv/start',headers={'Origin':self.origin},allow_redirects=False) as r:
            self.assertEqual(r.status,303)
            cookie=r.cookies[COOKIE];self.assertTrue(cookie['httponly']);self.assertFalse(cookie['secure'])
            self.assertEqual(cookie['samesite'],'Strict');return cookie.value

    async def test_lazy_start_isolation_capacity_and_exit(self):
        async with self.a.get(self.origin+'/index.html') as r:
            text=await r.text();self.assertIn('data-auto="yes"',text)
            self.assertIn('/_bnv/start.js',text);self.assertNotIn('type="password"',text)
        self.assertEqual(len(self.pool.sessions),0)  # GET never allocates a worker.
        for headers in ({},{'Origin':'null'},{'Origin':'http://evil.invalid'}):
            async with self.a.post(self.origin+'/_bnv/start',headers=headers) as r:self.assertEqual(r.status,403)
        a=await self.start(self.a);b=await self.start(self.b)
        self.assertNotEqual(a,b);self.assertIsNone(self.pool.find(a).worker)
        self.assertEqual(a,await self.start(self.a));self.assertEqual(len(self.pool.sessions),2)
        async with ClientSession(cookie_jar=CookieJar(unsafe=True)) as c:
            async with c.post(self.origin+'/_bnv/start',headers={'Origin':self.origin}) as r:self.assertEqual(r.status,503)
        async with self.a.post(self.origin+'/_bnv/session',headers={'Origin':self.origin},allow_redirects=False) as r:
            self.assertEqual(r.status,303);self.assertEqual(r.headers['Location'],'/_bnv/login?ended=1')
        async with self.a.get(self.origin+'/_bnv/login?ended=1') as r:self.assertIn('data-auto="no"',await r.text())
        self.assertIsNone(self.pool.find(a));self.assertIsNotNone(self.pool.find(b))
        async with self.b.get(self.origin+'/_bnv/status') as r:self.assertEqual(r.status,200)

    async def test_invalid_hosts_and_payload_do_not_allocate(self):
        for host in ['8.8.8.8','evil.invalid','192.0.2.7','0.0.0.0']:
            async with self.a.get(self.origin+'/_bnv/health',headers={'Host':host}) as r:self.assertEqual(r.status,403)
        async with self.a.post(self.origin+'/_bnv/start',headers={'Origin':self.origin},data='not empty') as r:self.assertEqual(r.status,400)
        self.assertFalse(self.pool.sessions)

if __name__=='__main__':unittest.main()

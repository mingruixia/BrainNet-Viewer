# SPDX-License-Identifier: GPL-3.0-or-later
"""Installed idle expiry and static caching over real TLS/WS, not native GUI."""
import argparse
import asyncio
import json
from pathlib import Path
import re
import ssl
import time
from urllib.parse import urljoin
import aiohttp
from check_browser_sessions import Rpc


async def check(args):
    origin = args.url.rstrip('/')
    context = ssl.create_default_context(cafile=str(args.ca_file))
    result = {}
    async with aiohttp.ClientSession(cookie_jar=aiohttp.CookieJar(unsafe=True),
            connector=aiohttp.TCPConnector(ssl=context), timeout=aiohttp.ClientTimeout(total=100)) as client:
        password = args.password_file.read_text().rstrip('\r\n')
        async def login():
            async with client.post(origin + '/_bnv/login', data={'password': password},
                                   headers={'Origin': origin}, allow_redirects=False) as response:
                assert response.status == 303
        await login()
        async with client.get(origin + '/index.html') as response:
            page = await response.text()
            assert response.headers['Cache-Control'] == 'no-store'
            assert '/_bnv/activity.js' in page
        scripts = re.findall(r'<script[^>]+src="([^\"]+)"', page)
        static = next(urljoin(origin + '/index.html', item) for item in scripts
                      if item.endswith('.js') and '/_bnv/' not in item)
        assert static.startswith(origin + '/')
        async with client.get(static) as response:
            assert response.status == 200
            assert response.headers['Cache-Control'] == 'private, max-age=3600'
            tag = response.headers.get('ETag')
            result['static_bytes'] = len(await response.read())
        assert tag
        async with client.get(static, headers={'If-None-Match': tag}) as response:
            assert response.status == 304
        result['private_static_304'] = True
        async with client.post(origin + '/bnv-session', headers={'Origin': origin}) as response:
            secret = (await response.json())['secret']
        async with client.ws_connect(origin + '/ws', headers={'Origin': origin}) as socket:
            rpc = Rpc(socket)
            await rpc.result('wslink.hello', [{'secret': secret}])
            before = time.monotonic()
            remaining = 30
            # Polling and genuine wslink state reads are not user input.
            while time.monotonic() - before < 45:
                async with client.get(origin + '/_bnv/status') as response:
                    if response.status == 401:
                        break
                    value = await response.json()
                    remaining = value['remaining']
                try:
                    await rpc.state()
                except (AssertionError, aiohttp.ClientError):
                    pass  # An expected close can race with the last idle poll.
                await asyncio.sleep(3)
            else:
                raise AssertionError('An idle connected application was not reclaimed.')
            result['idle_seconds'] = round(time.monotonic() - before, 2)
            result['last_remaining'] = remaining
        result['idle_connected_session_reclaimed'] = True
        await login()
        async with client.get(origin + '/index.html') as response:
            assert response.status == 200
        async with client.post(origin + '/bnv-session', headers={'Origin': origin}) as response:
            assert (await response.json())['secret'] != secret
        result['relogin_fresh_worker'] = True
        async with client.post(origin + '/_bnv/session', headers={'Origin': origin}, allow_redirects=False): pass
    result['passed'] = True
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--password-file', type=Path, required=True)
    parser.add_argument('--ca-file', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    asyncio.run(check(parser.parse_args()))

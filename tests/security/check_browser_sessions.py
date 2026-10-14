# SPDX-License-Identifier: GPL-3.0-or-later
"""Real installed Web RPC checks through the server gateway; not GUI evidence."""
import argparse
import asyncio
import base64
import io
import json
from pathlib import Path
import re
import ssl
import subprocess
from zipfile import ZipFile

import aiohttp
import msgpack
from PIL import Image
from wslink.chunking import generate_chunks, UnChunker


class Rpc:
    def __init__(self, socket):
        self.socket = socket
        self.sequence = 0
        self.decoder = UnChunker()
        self.decoder.set_max_message_size(72 * 1024 * 1024)

    async def call(self, method, args):
        self.sequence += 1
        key = ('system:' if method == 'wslink.hello' else 'rpc:') + str(self.sequence)
        data = msgpack.packb({'wslink': '1.0', 'id': key, 'method': method, 'args': args})
        for chunk in generate_chunks(data, 4194304):
            await self.socket.send_bytes(chunk)
        for _ in range(300):
            message = await self.socket.receive(timeout=90)
            assert message.type == aiohttp.WSMsgType.BINARY, f'Unexpected WS type: {message.type}'
            value = self.decoder.process_chunk(message.data)
            if isinstance(value, dict) and value.get('id') == key:
                return value
        raise AssertionError('No RPC reply.')

    async def result(self, method, args):
        value = await self.call(method, args)
        assert 'error' not in value, value.get('error')
        return value.get('result')

    async def state(self):
        return (await self.result('trame.state.get', []))['state']

    async def update(self, **values):
        await self.result('trame.state.update', [[{'key': k, 'value': v} for k, v in values.items()]])


async def check(origin, password, *, context=None, output=None, container=None):
    origin = origin.rstrip('/')
    clients = [aiohttp.ClientSession(cookie_jar=aiohttp.CookieJar(unsafe=True),
               connector=aiohttp.TCPConnector(ssl=context or True),
               timeout=aiohttp.ClientTimeout(total=150)) for _ in range(2)]
    sockets = []
    checks = {}
    workers = None
    try:
        for client in clients:
            async with client.post(origin + '/_bnv/login', data={'password': password},
                                   headers={'Origin': origin}, allow_redirects=False) as response:
                assert response.status == 303, response.status
                cookie = response.cookies['bnv_browser_session']
                assert cookie['httponly'] and cookie['samesite'] == 'Strict'
                if origin.startswith('https:'):
                    assert cookie['secure']
            async with client.get(origin + '/index.html') as response:
                assert response.status == 200, response.status
                assert 'data-session-manager-url="/bnv-session"' in await response.text()
        secrets = []
        for client in clients:
            async with client.post(origin + '/bnv-session', headers={'Origin': origin}) as response:
                assert response.status == 200
                bootstrap = await response.json()
                assert bootstrap['sessionURL'] == origin.replace('https:', 'wss:').replace('http:', 'ws:') + '/ws'
                secrets.append(bootstrap['secret'])
        assert secrets[0] != secrets[1]
        checks['independent_secrets_secure_cookies'] = True
        rpcs = []
        for client, secret in zip(clients, secrets):
            socket = await client.ws_connect(origin + '/ws', headers={'Origin': origin},
                                            max_msg_size=72 * 1024 * 1024)
            sockets.append(socket)
            rpc = Rpc(socket)
            hello = await rpc.result('wslink.hello', [{'secret': secret}])
            assert hello['clientID']
            rpcs.append(rpc)
        await rpcs[0].update(opacity=.19)
        await rpcs[1].update(opacity=.65)
        assert (await rpcs[0].state())['opacity'] == .19
        assert (await rpcs[1].state())['opacity'] == .65
        checks['independent_actual_trame_state'] = True
        if container:
            probe = '''import json,os,pathlib
workers=[]
for item in pathlib.Path('/proc').iterdir():
 if not item.name.isdigit(): continue
 try:
  command=(item/'cmdline').read_bytes().split(b'\\0')
  if b'brainnet_viewer.web_app' not in command: continue
  env=dict(entry.split(b'=',1) for entry in (item/'environ').read_bytes().split(b'\\0') if b'=' in entry)
  workers.append({'pid':int(item.name),'cwd':os.readlink(item/'cwd'),
    'backend':env.get(b'BNV_RENDER_BACKEND_SELECTED',b'').decode(),
    'driver':env.get(b'GALLIUM_DRIVER',b'').decode()})
 except (OSError,ValueError): pass
print(json.dumps(workers))'''
            result = subprocess.run(['docker', 'exec', container, 'python', '-c', probe],
                                    check=True, capture_output=True, text=True, timeout=10)
            workers = json.loads(result.stdout)
            assert len(workers) == 2 and workers[0]['pid'] != workers[1]['pid']
            assert workers[0]['cwd'] != workers[1]['cwd']
            assert all(item['backend'] in ('cpu', 'gpu') for item in workers)
            checks['independent_linux_application_processes'] = True
        async with clients[1].ws_connect(origin + '/ws', headers={'Origin': origin}) as alien:
            result = await Rpc(alien).call('wslink.hello', [{'secret': secrets[0]}])
            assert result.get('error', {}).get('code') == -32000
        checks['other_session_secret_refused'] = True
        state = await rpcs[0].state()
        # Select the real UI Apply callback, not a new diagnostic/export endpoint.
        templates = '\n'.join(v for k, v in state.items()
                              if isinstance(v, str) and k.startswith('trame__template'))
        if not templates:
            templates = '\n'.join(v for k, v in state.items() if isinstance(v, str) and 'Render Scene' in v)
        matches = re.findall(r'<v-?btn\b[^>]*?@click="([^\"]+)"[^>]*>\s*Render Scene\s*</v-?btn>',
                             templates, re.IGNORECASE)
        location = templates.find('Render Scene')
        assert matches, 'No Render Scene callback: ' + templates[max(0, location-250):location+80]
        name = re.search(r"trigger\(['\"]([^'\"]+)", matches[0])
        assert name, matches[0]
        await rpcs[0].update(surface='Data/SurfTemplate/BrainMesh_ICBM152.nv', preset=1,
                             width=400, height=300, dpi=100, transparent=True)
        await rpcs[0].result('trame.trigger', [name[1], [], {}])
        state = await rpcs[0].state()
        assert state['rendered'] and not state['error'], state.get('error')
        other = await rpcs[1].state()
        assert not other['rendered'] and not other['surface'] and other['opacity'] == .65
        checks['real_surface_apply_does_not_render_other_session'] = True
        payload = await rpcs[0].result('trame.trigger', ['save_brainnet_scene', [], {}])
        scene = base64.b64decode(payload, validate=True)
        with ZipFile(io.BytesIO(scene)) as archive:
            names = archive.namelist()
            assert any(name.endswith('.nv') for name in names)
            assert any(name.endswith('.json') for name in names)
        checks['real_scene_zip_download_rpc'] = True
        # Read the committed image from the normal application export trigger.
        files = await rpcs[0].result('trame.trigger', ['export_brainnet_files', [], {}])
        assert isinstance(files, list), type(files).__name__
        image_record = next(item for item in files if item['name'].lower().endswith('.png'))
        image_bytes = base64.b64decode(image_record['data'], validate=True)
        with Image.open(io.BytesIO(image_bytes)) as image:
            assert image.size == (400, 300)
            assert image.mode == 'RGBA'
            alpha = image.getchannel('A')
            low, high = alpha.getextrema()
            assert low == 0 and high > 0 and sum(alpha.histogram()[1:]) > 1000, 'Blank or opaque export.'
            assert image.getbbox() is not None
        assert any(item['name'].endswith('.json') for item in files)
        checks['real_png_and_sidecar_export_rpc'] = True
        if output:
            output.mkdir(parents=True, exist_ok=True)
            (output / 'scene.zip').write_bytes(scene)
            (output / 'surface.png').write_bytes(image_bytes)
        async with clients[0].get(origin + '/index.html') as response:
            assert response.status == 200
        assert (await rpcs[0].state())['opacity'] == .19
        checks['refresh_keeps_session'] = True
        await sockets[0].close()
        async with clients[0].post(origin + '/_bnv/session', headers={'Origin': origin},
                                   allow_redirects=False) as response:
            assert response.status == 303
        assert (await rpcs[1].state())['opacity'] == .65
        checks['signout_does_not_stop_other_session'] = True
    finally:
        for socket in sockets:
            await socket.close()
        for client in clients:
            try:
                async with client.post(origin + '/_bnv/session', headers={'Origin': origin},
                                       allow_redirects=False):
                    pass
            except aiohttp.ClientError:
                pass
            await client.close()
    return {'passed': True, 'checks': checks, 'workers': workers,
            'evidence': 'real installed HTTP/WebSocket RPC and file readback, not native GUI'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--password-file', type=Path, required=True)
    parser.add_argument('--ca-file', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--container', help='Optional operator-owned Docker container for PID evidence.')
    args = parser.parse_args()
    ssl_context = ssl.create_default_context(cafile=str(args.ca_file)) if args.ca_file else None
    result = asyncio.run(check(args.url, args.password_file.read_text().rstrip('\r\n'),
                              context=ssl_context, output=args.output, container=args.container))
    if args.output:
        (args.output / 'result.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))

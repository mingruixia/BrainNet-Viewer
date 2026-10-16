# SPDX-License-Identifier: GPL-3.0-or-later
"""Bounded four-session installed-render stress. Not browser FPS or manual QA."""
import argparse
import asyncio
import base64
import io
import json
from pathlib import Path
import re
import ssl
import subprocess
import time
import statistics

import aiohttp
from PIL import Image
from check_browser_sessions import Rpc


def processes(container):
    code = '''import json,os,pathlib
out=[]
for p in pathlib.Path('/proc').iterdir():
 if not p.name.isdigit():continue
 try:
  if b'brainnet_viewer.web_app' not in (p/'cmdline').read_bytes().split(b'\\0'):continue
  env=dict(x.split(b'=',1) for x in (p/'environ').read_bytes().split(b'\\0') if b'=' in x)
  status=dict(x.split(':',1) for x in (p/'status').read_text().splitlines() if ':' in x)
  out.append({'pid':int(p.name),'cwd':os.readlink(p/'cwd'),
   'backend':env.get(b'BNV_RENDER_BACKEND_SELECTED',b'').decode(),
   'device':env.get(b'BNV_RENDER_BACKEND_DEVICE',b'').decode(),
   'llvmpipe_threads':env.get(b'LP_NUM_THREADS',b'').decode(),
   'rss_kib':int(status['VmRSS'].split()[0]),'peak_rss_kib':int(status['VmHWM'].split()[0]),
   'threads':int(status['Threads'])})
 except (OSError,ValueError,KeyError):pass
print(json.dumps(out))'''
    value = subprocess.run(['docker', 'exec', container, 'python', '-c', code],
                           capture_output=True, text=True, check=True, timeout=15)
    return json.loads(value.stdout)


async def run(args):
    origin = args.url.rstrip('/')
    password = args.password_file.read_text().rstrip('\r\n')
    context = ssl.create_default_context(cafile=str(args.ca_file))
    clients, sockets, rpcs, measures = [], [], [], []
    result = {'backend_expected': args.backend, 'sessions': args.workers,
              'rounds': args.rounds, 'evidence': 'installed HTTPS/WS RPC, eight-view renders and file readback; not GUI/FPS'}
    try:
        async def connect():
            client = aiohttp.ClientSession(cookie_jar=aiohttp.CookieJar(unsafe=True),
                connector=aiohttp.TCPConnector(ssl=context), timeout=aiohttp.ClientTimeout(total=180))
            clients.append(client)
            async with client.post(origin + '/_bnv/login', data={'password': password},
                                   headers={'Origin': origin}, allow_redirects=False) as response:
                assert response.status == 303, response.status
            started = time.perf_counter()
            async with client.get(origin + '/index.html') as response:
                assert response.status == 200, (response.status, await response.text())
                html = await response.text()
                assert '/_bnv/activity.js' in html
            startup = time.perf_counter() - started
            async with client.post(origin + '/bnv-session', headers={'Origin': origin}) as response:
                secret = (await response.json())['secret']
            socket = await client.ws_connect(origin + '/ws', headers={'Origin': origin},
                                             max_msg_size=72 * 1024 * 1024)
            sockets.append(socket)
            rpc = Rpc(socket)
            await rpc.result('wslink.hello', [{'secret': secret}])
            return client, rpc, startup

        sessions = await asyncio.gather(*(connect() for _ in range(args.workers)))
        rpcs = [item[1] for item in sessions]
        result['startup_seconds'] = [round(item[2], 3) for item in sessions]
        async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=context)) as overflow:
            async with overflow.post(origin + '/_bnv/login', data={'password': password},
                                     headers={'Origin': origin}, allow_redirects=False) as response:
                assert response.status == 503
        result['over_capacity'] = '503 without evicting active sessions'
        trigger_names = []
        view_keys, previous_views = [], [None] * args.workers
        for index, rpc in enumerate(rpcs):
            state = await rpc.state()
            view_keys.append(next(key for key in state if key.startswith('trame__remote_view_') and key.endswith('Id')))
            templates = '\n'.join(value for value in state.values()
                                  if isinstance(value, str) and 'Render Scene' in value)
            matches = re.findall(r'<v-?btn\b[^>]*?@click="([^\"]+)"[^>]*>\s*Render Scene\s*</v-?btn>',
                                 templates, re.I)
            trigger_names.append(re.search(r"trigger\(['\"]([^'\"]+)", matches[0])[1])
            await rpc.update(surface='Data/SurfTemplate/BrainMesh_ICBM152.nv',
                surface_map='atlases/AAL90/icbm_vertex_AAL_label.txt', preset=2,
                opacity=round(.25 + index * .1, 2), width=800, height=600, dpi=200,
                transparent=True)
        args.output.mkdir(parents=True, exist_ok=True)
        async def one(index, rpc, iteration):
            client = sessions[index][0]
            async with client.post(origin + '/_bnv/activity', headers={'Origin': origin}) as response:
                assert response.status == 204
            start = time.perf_counter()
            await rpc.result('trame.trigger', [trigger_names[index], [], {}])
            elapsed = time.perf_counter() - start
            state = await rpc.state()
            assert state['rendered'] and not state['error'], state.get('error')
            assert state['opacity'] == round(.25 + index * .1, 2)
            assert state['status'].startswith('Rendered 8 view(s).'), state['status']
            if args.subscribe:
                current = state[view_keys[index]]
                if previous_views[index] != current:
                    subscribed = await rpc.result('viewport.image.push.observer.add', [current])
                    assert subscribed['success'], subscribed
                await rpc.result('viewport.image.push.original.size', [current, 600, 450])
                await rpc.result('viewport.image.push.quality', [current, 100, 2])
                old = previous_views[index]
                if old is not None and old != current:
                    # Delayed unmount/events must not change the newly active view.
                    assert await rpc.result('viewport.image.push.observer.remove', [old]) == {'result': 'success'}
                    stale = await rpc.result('viewport.image.push.quality', [old, 1, .1])
                    assert 'error' in stale and 'no longer available' in stale['error'], stale
                    stale = await rpc.result('viewport.mouse.zoom.wheel', [{'view': old}])
                    assert 'error' in stale, stale
                quality = await rpc.result('viewport.image.push.quality.get', [current])
                assert quality == {'quality': 100, 'ratio': 2}, quality
                await rpc.result('viewport.image.push', [{'view': current}])
                previous_views[index] = current
            files = await rpc.result('trame.trigger', ['export_brainnet_files', [], {}])
            png = next(item for item in files if item['name'].endswith('.png'))
            content = base64.b64decode(png['data'])
            with Image.open(io.BytesIO(content)) as image:
                assert image.size == (800, 600) and image.mode == 'RGBA'
                alpha = image.getchannel('A')
                assert alpha.getextrema()[0] == 0 and sum(alpha.histogram()[1:]) > 1000
            sidecar = json.loads(base64.b64decode(next(item['data'] for item in files if item['name'].endswith('.json'))))
            assert sidecar['settings']['surface']['opacity'] == state['opacity']
            (args.output / f'session-{index+1}-round-{iteration}.png').write_bytes(content)
            return {'session': index+1, 'round': iteration, 'apply_seconds': round(elapsed, 3)}
        for iteration in range(1, args.rounds + 1):
            measures.extend(await asyncio.gather(*(one(index, rpc, iteration)
                                                  for index, rpc in enumerate(rpcs))))
            snapshot = processes(args.container)
            assert len(snapshot) == args.workers
            assert len({p['pid'] for p in snapshot}) == args.workers
            assert len({p['cwd'] for p in snapshot}) == args.workers
            assert all(p['backend'] == args.backend and p['device'] for p in snapshot), snapshot
            result.setdefault('process_snapshots', []).append(snapshot)
            print(f'{args.backend}: completed round {iteration}/{args.rounds}', flush=True)
            (args.output / 'progress.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
        result['render_and_export'] = measures
        if args.memory_check:
            assert args.rounds >= 20, 'Memory check needs at least 20 rounds.'
            memory = []
            for worker in result['process_snapshots'][0]:
                series = [next(p['rss_kib'] for p in snapshot if p['pid'] == worker['pid']) / 1024
                          for snapshot in result['process_snapshots'][5:]]
                center = (len(series)-1)/2
                slope = sum((i-center)*value for i, value in enumerate(series)) / sum((i-center)**2 for i in range(len(series)))
                growth = statistics.median(series[-5:]) - statistics.median(series[:5])
                memory.append({'pid': worker['pid'], 'warmup_rounds': 5,
                               'rss_slope_mib_per_round': round(slope, 3),
                               'median_rss_growth_mib': round(growth, 3),
                               'passed': slope <= 2 and growth <= 64})
            result['memory_check'] = memory
            (args.output / 'progress.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
            assert all(item['passed'] for item in memory), memory
        result['passed'] = True
    finally:
        for socket in sockets: await socket.close()
        for client in clients:
            try:
                async with client.post(origin + '/_bnv/session', headers={'Origin': origin},
                                       allow_redirects=False): pass
            except aiohttp.ClientError: pass
            await client.close()
    result['remaining_workers'] = processes(args.container)
    assert not result['remaining_workers']
    (args.output / 'result.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--password-file', type=Path, required=True)
    parser.add_argument('--ca-file', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--container', required=True)
    parser.add_argument('--backend', choices=('cpu', 'gpu'), required=True)
    parser.add_argument('--workers', type=int, choices=range(2, 5), default=4)
    parser.add_argument('--rounds', type=int, choices=range(1, 41), default=3)
    parser.add_argument('--subscribe', action='store_true', help='Exercise real image subscriptions and late retired-view RPCs.')
    parser.add_argument('--memory-check', action='store_true', help='After five warm-up rounds: <=2 MiB/round RSS slope and <=64 MiB median growth per worker. Not a universal memory guarantee.')
    value = asyncio.run(run(parser.parse_args()))
    print(json.dumps(value, indent=2))

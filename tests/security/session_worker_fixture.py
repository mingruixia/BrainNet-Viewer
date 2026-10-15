# SPDX-License-Identifier: GPL-3.0-or-later
"""Small real subprocess fixture, not a scientific renderer or GUI test."""
import hmac
import asyncio
import os
from pathlib import Path
import secrets
import sys
from aiohttp import web, WSMsgType

secret = secrets.token_urlsafe(32)
value = 0


@web.middleware
async def guard(request, handler):
    if not hmac.compare_digest(request.headers.get('X-BNV-Worker-Token', ''),
                               os.environ['BNV_GATEWAY_TOKEN']):
        raise web.HTTPForbidden()
    return await handler(request)


async def index(request):
    if request.query.get('chunks') == '1':
        response = web.StreamResponse(headers={'Content-Type': 'text/html'})
        await response.prepare(request)
        await response.write(b'<html><head>')
        await asyncio.sleep(0.05)
        await response.write(b'</head><body>Complete bootstrap</body></html>')
        await response.write_eof()
        return response
    return web.json_response({'pid': os.getpid(), 'value': value, 'cwd': str(Path.cwd()),
                             'cookie_received': bool(request.headers.get('Cookie'))})


async def bootstrap(request):
    return web.json_response({'sessionURL': f'ws://{request.host}/ws', 'secret': secret})


async def socket(request):
    global value
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    authenticated = False
    async for message in ws:
        if message.type == WSMsgType.TEXT:
            if not authenticated:
                if message.data != secret:
                    await ws.close(code=1008)
                    break
                authenticated = True
                await ws.send_str('authenticated')
            else:
                value = int(message.data)
                Path('uploaded.txt').write_text(str(value))
                await ws.send_str(str(value))
    return ws


app = web.Application(middlewares=[guard])
app.router.add_get('/index.html', index)
app.router.add_post('/bnv-session', bootstrap)
app.router.add_get('/ws', socket)
async def static(request):
    if request.headers.get('If-None-Match') == '"fixture-v1"':
        return web.Response(status=304, headers={'ETag': '"fixture-v1"'})
    return web.Response(text='window.fixture = true;', content_type='application/javascript',
                        headers={'ETag': '"fixture-v1"'})
app.router.add_get('/fixture.js', static)
web.run_app(app, host='127.0.0.1', port=int(sys.argv[1]), access_log=None)

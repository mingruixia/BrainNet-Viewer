# SPDX-License-Identifier: GPL-3.0-or-later
"""Actual HTTP/WS checks; do not print secrets."""
import argparse,asyncio,json
import aiohttp,msgpack
from wslink.chunking import generate_chunks,UnChunker

async def check(url):
    origin=url.rstrip('/');result={}
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as client:
        async with client.get(origin+'/index.html') as response:
            assert response.status==200
            assert 'data-session-manager-url="/bnv-session"' in await response.text()
        async with client.post(origin+'/bnv-session',headers={'Origin':origin}) as response:
            assert response.status==200 and response.headers.get('Cache-Control')=='no-store'
            secret=(await response.json())['secret'];assert len(secret)>=32
        cases={'foreign':{'Origin':'http://evil.invalid'},'missing':{},'null':{'Origin':'null'},
               'host':{'Origin':origin,'Host':'evil.invalid'},'cross-site':{'Origin':origin,'Sec-Fetch-Site':'cross-site'}}
        for label,headers in cases.items():
            async with client.post(origin+'/bnv-session',headers=headers) as response:
                assert response.status==403,(label,response.status);result[label]=403
        for label,headers in [('foreign',cases['foreign']),('missing',{}),('host',cases['host'])]:
            try:await client.ws_connect(origin+'/ws',headers=headers)
            except aiohttp.WSServerHandshakeError as error:assert error.status==403;result['ws-'+label]=403
            else:raise AssertionError('Untrusted WS accepted')
        async def rpc(socket,key,method,args):
            for chunk in generate_chunks(msgpack.packb({'wslink':'1.0','id':key,'method':method,'args':args}),4194304):await socket.send_bytes(chunk)
            decoder=UnChunker();decoder.set_max_message_size(4194304)
            for _ in range(30):
                message=await socket.receive(timeout=10);assert message.type==aiohttp.WSMsgType.BINARY
                value=decoder.process_chunk(message.data)
                if value is not None and value.get('id')==key:return value
            raise AssertionError('No RPC reply')
        for label,key,method,args in [('wrong_secret','system:1','wslink.hello',[{'secret':'deliberately-wrong'}]),('unauthenticated_rpc','rpc:1','viewport.image.push.quality.get',[])]:
            async with client.ws_connect(origin+'/ws',headers={'Origin':origin}) as socket:
                value=await rpc(socket,key,method,args);assert value.get('error',{}).get('code')==-32000;result[label]='refused'
        async with client.ws_connect(origin+'/ws',headers={'Origin':origin}) as socket:
            value=await rpc(socket,'system:2','wslink.hello',[{'secret':secret}]);assert value.get('result',{}).get('clientID');result['same_origin_secret']='authenticated'
    return {'passed':True,'checks':result,'model':'one trusted local user; not OS-user authentication'}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--url',required=True);a=p.parse_args();print(json.dumps(asyncio.run(check(a.url)),indent=2))

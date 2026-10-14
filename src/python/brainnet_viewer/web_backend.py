# SPDX-License-Identifier: GPL-3.0-or-later
"""GPU-first Web startup with an isolated native render probe and CPU fallback.

Container GPU allocation is the launcher's responsibility. Never infer rendering
capability from a GPU inventory, and never probe a graphics driver in the server.
"""
import json
import os
from pathlib import Path
import subprocess
import sys

PROBE = '''import json,pyvista as pv
p=pv.Plotter(off_screen=True,window_size=(64,64))
try:
 p.add_mesh(pv.Sphere(theta_resolution=8,phi_resolution=8));p.render_window.Render()
 caps=p.render_window.ReportCapabilities()
 device=next((x.split(':',1)[1].strip() for x in caps.splitlines() if 'OpenGL renderer string:' in x),'')
 image=p.screenshot(return_img=True)
 print(json.dumps({'device':device,'drawn':image.shape[:2]==(64,64)}))
finally:p.close()
'''
DRIVER_KEYS = ('GALLIUM_DRIVER','MESA_LOADER_DRIVER_OVERRIDE','MESA_D3D12_DEFAULT_ADAPTER_NAME')

def hardware(device):
    value=device.lower()
    return bool(value) and not any(x in value for x in
                                  ('llvmpipe','softpipe','software rasterizer','swiftshader'))

def driver_environment(base, *, cpu=False):
    env=dict(base)
    for key in DRIVER_KEYS: env.pop(key,None)
    if cpu:
        env['LIBGL_ALWAYS_SOFTWARE']='1'
        env['GALLIUM_DRIVER']='llvmpipe'
    else:
        env.pop('LIBGL_ALWAYS_SOFTWARE',None)
        adapter=base.get('MESA_D3D12_DEFAULT_ADAPTER_NAME')
        if adapter:
            env['MESA_D3D12_DEFAULT_ADAPTER_NAME']=adapter
        if (Path('/dev/dxg').exists() and Path('/usr/lib/wsl/lib/libd3d12.so').is_file()
                and Path('/usr/lib/wsl/drivers').is_dir()):
            previous=env.get('LD_LIBRARY_PATH','')
            env['LD_LIBRARY_PATH']='/usr/lib/wsl/lib'+(':'+previous if previous else '')
            env.update(GALLIUM_DRIVER='d3d12',MESA_LOADER_DRIVER_OVERRIDE='d3d12',
                       EGL_PLATFORM='surfaceless')
    return env

def probe(env, *, run=subprocess.run):
    try:
        result=run([sys.executable,'-c',PROBE],env=env,capture_output=True,text=True,
                   timeout=20,check=False)
        if result.returncode:
            return {'ok':False,'reason':f'Native render probe exited {result.returncode}',
                    'detail':result.stderr[-1500:]}
        value=json.loads(result.stdout.strip().splitlines()[-1])
        if not value.get('drawn') or not value.get('device'):
            return {'ok':False,'reason':'Render probe did not produce a valid frame/device'}
        return {'ok':True,**value}
    except (subprocess.TimeoutExpired,OSError,ValueError,IndexError) as error:
        return {'ok':False,'reason':f'Render probe unavailable: {type(error).__name__}'}

def configure_backend(mode=None, *, run=subprocess.run):
    mode=(mode or os.environ.get('BNV_RENDER_BACKEND','auto')).lower()
    if mode not in ('auto','gpu','cpu'): raise ValueError('BNV_RENDER_BACKEND must be auto, gpu or cpu')
    base=dict(os.environ); fallback='CPU requested'
    if mode!='cpu':
        env=driver_environment(base)
        result=probe(env,run=run)
        if result['ok'] and hardware(result['device']):
            selected='gpu'; fallback=''; chosen=result
        else:
            fallback=result.get('reason',f"GPU probe selected software: {result.get('device','unknown')}")
            if mode=='gpu': raise RuntimeError(fallback)
            env=driver_environment(base,cpu=True); chosen=probe(env,run=run);selected='cpu'
    else:
        env=driver_environment(base,cpu=True);chosen=probe(env,run=run);selected='cpu'
    if not chosen['ok']: raise RuntimeError('CPU/GPU render startup failed: '+chosen['reason'])
    for key in (*DRIVER_KEYS,'LIBGL_ALWAYS_SOFTWARE','LD_LIBRARY_PATH','EGL_PLATFORM'):
        if key in env: os.environ[key]=env[key]
        else: os.environ.pop(key,None)
    record={'requested':mode,'selected':selected,'device':chosen['device'],'fallback':fallback}
    os.environ['BNV_RENDER_BACKEND_SELECTED']=selected
    print('BrainNet render backend: '+json.dumps(record),flush=True)
    return record

def bootstrap(module=None, argv=None):
    # Linux's dynamic loader consumes LD_LIBRARY_PATH at process startup.
    # Updating os.environ after Python imports is not enough for WSL D3D12.
    # exec preserves PID; an inherited marker from a parent must not skip the
    # actual probe. This is loader state, not an authentication credential.
    marker=str(os.getpid())
    if os.environ.get('BNV_WEB_BOOTSTRAPPED')==marker: return
    configure_backend()
    os.environ['BNV_WEB_BOOTSTRAPPED']=marker
    if sys.platform != 'linux':
        return  # Only Linux needs LD_LIBRARY_PATH applied through re-exec.
    command=([sys.executable,'-m',module,*(sys.argv[1:] if argv is None else argv)]
             if module else [sys.executable,*sys.argv])
    os.execvpe(sys.executable,command,dict(os.environ))

if __name__=='__main__':
    try: configure_backend('gpu' if '--probe-gpu' in sys.argv else None)
    except RuntimeError as error:
        print(str(error),file=sys.stderr);sys.exit(1)

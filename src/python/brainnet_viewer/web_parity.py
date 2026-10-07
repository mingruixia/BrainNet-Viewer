"""Qt-free browser adaptations of desktop navigation and host information."""
import asyncio
import ctypes
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path


def container_memory(read=lambda path:Path(path).read_text()):
    """Return a finite cgroup v2/v1 budget, or None for unknown/unlimited."""
    for limit,usage in (('/sys/fs/cgroup/memory.max','/sys/fs/cgroup/memory.current'),
                        ('/sys/fs/cgroup/memory/memory.limit_in_bytes','/sys/fs/cgroup/memory/memory.usage_in_bytes')):
        try:
            raw=read(limit).strip()
            if raw=='max': continue
            total=int(raw); used=int(read(usage))
            if 0<total<2**60: return max(0,total-used),total
        except (OSError,ValueError): pass
    return None


def host_resources(window=None):
    name=platform.processor() or platform.machine()
    memory='RAM: unavailable'
    if os.name=='nt':
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,r'HARDWARE\DESCRIPTION\System\CentralProcessor\0') as key:
                name=winreg.QueryValueEx(key,'ProcessorNameString')[0].strip()
            class Memory(ctypes.Structure):
                _fields_=[('length',ctypes.c_ulong),('load',ctypes.c_ulong)]+[(key,ctypes.c_ulonglong) for key in ('total','available','page_total','page_available','virtual_total','virtual_available','extended')]
            data=Memory(); data.length=ctypes.sizeof(data)
            if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(data)):
                memory=f'RAM: {data.available/2**30:.1f}/{data.total/2**30:.0f} GiB available'
        except OSError: pass
    elif platform.system()=='Linux':
        try:
            cpu=Path('/proc/cpuinfo').read_text()
            match=re.search(r'^model name\s*:\s*(.+)',cpu,re.M)
            if match: name=match[1]
            values={k:int(v) for k,v in re.findall(r'^(\w+):\s*(\d+)',Path('/proc/meminfo').read_text(),re.M)}
            memory=f'RAM: {values["MemAvailable"]/2**20:.1f}/{values["MemTotal"]/2**20:.0f} GiB available'
            budget=container_memory()
            if budget is not None:
                free,total=budget
                memory=f'Container RAM: {free/2**30:.1f}/{total/2**30:.0f} GiB available'
        except (OSError,ValueError,KeyError): pass
    name=re.sub(r'\s+(\d+-Core Processor|Processor|CPU|@.*)$','',name).strip()
    gpu='GPU: unavailable'
    query=shutil.which('nvidia-smi')
    if query:
        try:
            result=subprocess.run([query,'--query-gpu=name,memory.free,memory.total','--format=csv,noheader,nounits'],
                capture_output=True,text=True,timeout=3,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            if result.returncode==0:
                rows=[]
                for row in result.stdout.strip().splitlines():
                    model,free,total=row.rsplit(',',2)
                    rows.append(f'{model.strip()} {float(free)/1024:.1f}/{float(total)/1024:.0f} GiB free')
                if rows: gpu='GPU inventory: '+'; '.join(rows)
        except (OSError,ValueError,subprocess.TimeoutExpired): pass
    if window is not None:
        match=re.search(r'OpenGL renderer string:\s*([^\n]+)',window.ReportCapabilities())
        if match: gpu+=' · Render device: '+match[1].strip()
    return f'Render host · CPU: {name} · {os.cpu_count()} logical cores | {memory} | {gpu}'


class WebNavigation:
    def __init__(self,state,workspace,update):
        self.state,self.workspace,self.update=state,workspace,update
        self.task=None

    def stop(self):
        self.state.demo_running=False
        if self.task is not None: self.task.cancel(); self.task=None

    def refresh(self):
        window=self.workspace.plotter.render_window if self.workspace.plotter else None
        self.state.resources=host_resources(window)

    def direction(self,value):
        import numpy as np
        self.stop()
        renderer=self.workspace.renderer
        if renderer is None: return
        angles={1:(-90,0),5:(90,0),3:(180,0),7:(0,0),2:(0,90),6:(0,-90)}
        if value in (None,0,'0'):
            renderer.reset(); self.update(); return
        if value not in angles: raise ValueError('Choose a toolbar view direction.')
        az,el=np.deg2rad(angles[value]); vector=np.array([np.cos(el)*np.sin(az),-np.cos(el)*np.cos(az),np.sin(el)])
        for item in renderer.plotter.renderers:
            camera=item.camera; focus=np.asarray(camera.focal_point)
            distance=np.linalg.norm(np.asarray(camera.position)-focus)
            camera.position=focus+vector*distance
            camera.up=(0,1,0) if abs(vector[2])>.99 else (0,0,1)
            item.ResetCameraClippingRange()
        renderer.update_label_records(); renderer.plotter.render(); self.update()

    def tick(self):
        renderer=self.workspace.renderer
        if renderer is None: return
        for item in renderer.plotter.renderers:
            item.camera.Azimuth(5.); item.ResetCameraClippingRange()
        renderer.update_label_records(); renderer.plotter.render(); self.update()

    def start(self):
        self.stop()
        if self.state.animation_busy: raise ValueError('Wait for animation export to finish before starting Live Demo.')
        if self.workspace.renderer is None: return
        async def run():
            try:
                while self.state.demo_running:
                    await asyncio.sleep(.12)
                    self.tick(); self.state.flush()
            except asyncio.CancelledError: pass
            except Exception as error:
                self.state.error=str(error); self.state.demo_running=False; self.state.flush()
        self.task=asyncio.get_running_loop().create_task(run())
        self.state.demo_running=True

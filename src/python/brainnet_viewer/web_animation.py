"""Spawn-isolated animation jobs: no VTK calls on a background thread."""
from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory
import multiprocessing as mp
import queue


def _worker(prepared,camera,size,paths,plan,folder,messages,cancel):
    plot=renderer=None
    try:
        import pyvista as pv
        from .rendering import SceneRenderer,layout
        from .movies import export_movie,apply_camera,MovieCancelled
        if cancel.is_set(): raise MovieCancelled('Animation cancelled.')
        _,views=layout(prepared.settings['layout'],prepared.split)
        plot=pv.Plotter(off_screen=True,shape=(1,len(views)),window_size=size,border=False)
        renderer=SceneRenderer(plot); renderer.render(prepared); apply_camera(renderer,camera)
        def progress(done,total):
            if sum(p.stat().st_size for p in Path(folder).rglob('*') if p.is_file())>48*1024*1024:
                raise ValueError('Animation output exceeds the 48 MiB download limit.')
            messages.put(('progress',done,total))
        export_movie(renderer,Path(folder)/'output',plan,paths=paths,settings=prepared.settings,
                     cancel=cancel.is_set,progress=progress)
        messages.put(('done',))
    except Exception as error:
        from .movies import MovieCancelled
        messages.put(('cancelled' if isinstance(error,MovieCancelled) else 'error',str(error)))
    finally:
        if renderer is not None: renderer.dispose()
        if plot is not None: plot.close()


class AnimationJob:
    def __init__(self,workspace,options):
        from .movies import movie_plan
        plan=movie_plan(**options)
        if plan['frame_count']>120 or plan['width']*plan['height']*plan['frame_count']>120_000_000:
            raise ValueError('Web animation is limited to 120 frames / 120 million frame-pixels.')
        if workspace.renderer is None: raise ValueError('Render a scene before exporting an animation.')
        self.temp=TemporaryDirectory(prefix='animation-job-',dir=workspace.scratch)
        self.folder=Path(self.temp.name); self.total=plan['frame_count']
        context=mp.get_context('spawn')
        self.messages=context.Queue(); self.cancel=context.Event()
        self.process=context.Process(target=_worker,args=(deepcopy(workspace.renderer.prepared),
            workspace.renderer.capture_camera(),tuple(workspace.plotter.render_window.GetSize()),
            dict(workspace.render_paths),plan,str(self.folder),self.messages,self.cancel),daemon=True)
        try: self.process.start()
        except Exception: self.messages.close(); self.temp.cleanup(); raise

    def poll(self):
        result=[]
        while True:
            try: result.append(self.messages.get_nowait())
            except queue.Empty: return result

    def files(self):
        paths=sorted((self.folder/'output').iterdir())
        if sum(p.stat().st_size for p in paths)>48*1024*1024:
            raise ValueError('Animation output exceeds the 48 MiB download limit.')
        return {p.name:p.read_bytes() for p in paths}

    def close(self):
        self.cancel.set(); self.process.join(timeout=1)
        if self.process.is_alive(): self.process.terminate(); self.process.join(timeout=2)
        self.messages.close(); self.temp.cleanup()

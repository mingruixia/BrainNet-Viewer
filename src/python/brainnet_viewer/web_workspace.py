"""Qt-free, single-user Web workspace using the shared scientific core.

Inputs are bundled catalog entries or bounded files uploaded into an owned
temporary directory. Host filesystem paths are never accepted from the browser.
"""
from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZipFile, ZIP_DEFLATED
import uuid
from .settings import DEFAULTS, normalize


def library_root():
    packaged=Path(__file__).resolve().parent/'resources'
    if (packaged/'Data/SurfTemplate').is_dir(): return packaged
    return Path(__file__).resolve().parents[3]/'src/matlab/BrainNetViewer'


class WebWorkspace:
    def __init__(self, root=None, *, scratch=None):
        self.root=Path(root or library_root()).resolve()
        self.settings=deepcopy(DEFAULTS)
        patterns={'surface':['Data/SurfTemplate/*.nv'],
                  'node':['Data/ExampleFiles/AtlasNetworks/*.node','Data/ExampleFiles/FormatExamples/*.node'],
                  'edge':['Data/ExampleFiles/AtlasNetworks/*.edge'],
                  'surface_map':['Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt'],
                  'volume':['Data/Tutorials/OneSample_ROI11_NC.nii','Data/ExampleFiles/AAL90/aal.nii']}
        self.catalog={role:{} for role in patterns}
        for role,globs in patterns.items():
            for pattern in globs:
                for path in sorted(self.root.glob(pattern)):
                    if path.is_file() and path.resolve().is_relative_to(self.root):
                        self.catalog[role][path.relative_to(self.root).as_posix()]=path.resolve()
        self.paths={}; self.plotter=None; self.renderer=None; self.render_settings=None; self.render_paths=None
        self._temp=TemporaryDirectory(prefix='brainnet-web-',dir=scratch)
        self.scratch=Path(self._temp.name)
        self._assets_temp=TemporaryDirectory(prefix='brainnet-web-assets-',dir=scratch)
        self.assets=Path(self._assets_temp.name)
        self.pending_session=None
        self._resize_observer=None

    def select(self, selections):
        if not isinstance(selections,dict) or set(selections)-set(self.catalog):
            raise ValueError('Unknown input role.')
        paths={}
        for role,key in selections.items():
            if key in ('',None): continue
            if not isinstance(key,str) or key not in self.catalog[role]:
                raise ValueError('Choose a bundled input from the library.')
            path=self.catalog[role][key]
            if not path.is_file() or not any(path.resolve().is_relative_to(root) for root in (self.root,self.assets)):
                raise ValueError('Bundled input is unavailable.')
            paths[role]=path
        if 'surface' not in paths: raise ValueError('Select a surface first.')
        if 'edge' in paths and 'node' not in paths: raise ValueError('Edges require nodes.')
        if 'surface_map' in paths and 'volume' in paths: raise ValueError('Choose either Surface Map or Volume, not both.')
        self.paths=paths

    def configure(self, patch):
        from .settings import merge
        self.settings=normalize({'visualization_settings':merge(self.settings,patch)})
        return deepcopy(self.settings)

    def boundary_file(self):
        """Export the committed render mask, matching desktop Save Boundary."""
        import io
        import numpy as np
        prepared=self.renderer.prepared if self.renderer else None
        if prepared is None or prepared.boundary is None:
            raise ValueError('Render a surface boundary before saving it.')
        mask=np.asarray(prepared.boundary)
        if mask.shape!=(len(prepared.surface.points),) or not np.isin(mask,[0,1]).all():
            raise ValueError('Rendered boundary must contain one binary value per surface vertex.')
        stream=io.StringIO(); np.savetxt(stream,mask.astype(int),fmt='%d')
        payload=stream.getvalue().encode('utf-8')
        if len(payload)>48*1024*1024: raise ValueError('Boundary download exceeds 48 MiB.')
        return payload

    def animation_files(self,**options):
        """Isolated desktop movie export, bounded for a single-user Web session."""
        from .movies import movie_plan,export_movie
        plan=movie_plan(**options)
        if plan['frame_count']>120 or plan['width']*plan['height']*plan['frame_count']>120_000_000:
            raise ValueError('Web animation is limited to 120 frames / 120 million frame-pixels.')
        with TemporaryDirectory(prefix='animation-',dir=self.scratch) as folder:
            destination=Path(folder)/'output'
            def progress(*_):
                if sum(p.stat().st_size for p in destination.parent.rglob('*') if p.is_file())>48*1024*1024:
                    raise ValueError('Animation output exceeds the 48 MiB download limit.')
            export_movie(self.renderer,destination,plan,paths=self.render_paths,settings=self.render_settings,progress=progress)
            paths=sorted(destination.iterdir())
            if sum(p.stat().st_size for p in paths)>48*1024*1024:
                raise ValueError('Animation output exceeds the 48 MiB download limit.')
            return {p.name:p.read_bytes() for p in paths}

    def render(self):
        import pyvista as pv
        from .rendering import prepare, layout, SceneRenderer
        if not self.paths: raise ValueError('Select inputs before rendering.')
        prepared=prepare(self.paths,self.settings)
        _,views=layout(self.settings['layout'],prepared.split)
        plot=pv.Plotter(shape=(1,len(views)),border=False,off_screen=True,window_size=(1200,900))
        renderer=SceneRenderer(plot)
        try: renderer.render(prepared)
        except Exception:
            renderer.dispose(); plot.close(); raise
        self.close_render()
        self.plotter,self.renderer=plot,renderer
        self.render_settings=deepcopy(self.settings)
        self.render_paths=dict(self.paths)
        if self.pending_session:
            renderer.restore_session(self.pending_session); self.pending_session=None
        # Trame changes the native render-window size to the browser canvas.
        # Refit on size modification, before VTK/Web captures projection/image
        # state. A Render StartEvent is too late for the first resized frame.
        # Do not reset independently edited cameras or interfere with export's
        # explicit resize/restore transaction.
        fitting=False
        def fit_canvas(window, _event):
            nonlocal fitting
            if renderer.exporting or fitting: return
            fitting=True
            try: renderer.resize_fit(*window.GetSize())
            finally: fitting=False
        self._resize_observer=plot.render_window.AddObserver('ModifiedEvent',fit_canvas,1.)
        return renderer

    def download(self, width=1600,height=1200,dpi=200,transparent=False,format='png',units='Pixels'):
        files=self.export_files(width,height,dpi,transparent,format,units)
        import io
        archive=io.BytesIO()
        with ZipFile(archive,'w',ZIP_DEFLATED) as z:
            for name,data in files.items(): z.writestr(name,data)
        return archive.getvalue()

    def export_files(self,width=1600,height=1200,dpi=200,transparent=False,format='png',units='Pixels',filename='BrainNet'):
        if self.renderer is None: raise ValueError('Render a scene before exporting.')
        from .web_export import preferences,image_name
        options,(width,height)=preferences(width,height,dpi,transparent,format,units)
        dpi=options['dpi']; format=options['format']
        name=image_name(filename,format)
        folder=self.scratch/uuid.uuid4().hex; folder.mkdir()
        try:
            image=folder/name
            self.renderer.export(image,int(width),int(height),int(dpi),transparent,
                                 paths=self.render_paths,settings=self.render_settings,
                                 provenance_context={'entry_point':'web-single-user','requested_export':options})
            sidecar=Path(str(image)+'.provenance.json')
            return {image.name:image.read_bytes(),sidecar.name:sidecar.read_bytes()}
        finally:
            # Only remove known generated files in this unique owned directory.
            for path in folder.iterdir(): path.unlink()
            folder.rmdir()

    def close_render(self):
        if self._resize_observer is not None and self.plotter is not None:
            self.plotter.render_window.RemoveObserver(self._resize_observer)
        self._resize_observer=None
        if self.renderer is not None: self.renderer.dispose()
        if self.plotter is not None: self.plotter.close()
        self.renderer=None; self.plotter=None

    def close(self):
        self.close_render(); self._temp.cleanup(); self._assets_temp.cleanup()

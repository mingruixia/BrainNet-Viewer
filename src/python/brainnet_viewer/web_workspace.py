"""Qt-free, single-user Web workspace using the shared scientific core.

Inputs are bundled catalog entries or bounded files uploaded into an owned
temporary directory. Host filesystem paths are never accepted from the browser.
"""
from copy import deepcopy
from contextlib import contextmanager
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
        self.atlas_root=self.root/'atlases'
        if not self.atlas_root.is_dir() and self.root.name=='BrainNetViewer' and self.root.parent.name=='matlab':
            self.atlas_root=self.root.parents[2]/'resources/atlases'
        self.settings=deepcopy(DEFAULTS)
        patterns={'surface':['Data/SurfTemplate/*.nv'],
                  'node':['Data/ExampleFiles/AtlasNetworks/*.node'],
                  'edge':['Data/ExampleFiles/AtlasNetworks/*.edge'],
                  'surface_map':['atlases/AAL90/icbm_vertex_AAL_label.txt'],
                  'volume':['Data/Tutorials/OneSample_ROI11_NC.nii','atlases/AAL90/aal.nii']}
        self.catalog={role:{} for role in patterns}
        for role,globs in patterns.items():
            for pattern in globs:
                base=self.atlas_root if pattern.startswith('atlases/') else self.root
                glob=pattern.removeprefix('atlases/') if pattern.startswith('atlases/') else pattern
                for path in sorted(base.glob(glob)):
                    if path.is_file() and path.resolve().is_relative_to(base.resolve()):
                        key=('atlases/' if base==self.atlas_root else '')+path.relative_to(base).as_posix()
                        self.catalog[role][key]=path.resolve()
        self.paths={}; self.plotter=None; self.renderer=None; self.render_settings=None; self.render_paths=None
        self._temp=TemporaryDirectory(prefix='brainnet-web-',dir=scratch)
        self.scratch=Path(self._temp.name)
        self._assets_temp=TemporaryDirectory(prefix='brainnet-web-assets-',dir=scratch)
        self.assets=Path(self._assets_temp.name)
        self.pending_session=None
        self._resize_observer=None
        self.retire_view=None
        self._retained_window=None
        self.on_canvas_warning=None

    def _publish_canvas_warning(self):
        if self.on_canvas_warning:
            self.on_canvas_warning(self.renderer.annotation_warning if self.renderer else '')

    def select(self, selections):
        if not isinstance(selections,dict) or set(selections)-set(self.catalog):
            raise ValueError('Unknown input role.')
        paths={}
        for role,key in selections.items():
            if key in ('',None): continue
            if not isinstance(key,str) or key not in self.catalog[role]:
                raise ValueError('Choose a bundled input from the library.')
            path=self.catalog[role][key]
            if not path.is_file() or not any(path.resolve().is_relative_to(root) for root in (self.root,self.atlas_root.resolve(),self.assets)):
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

    def render(self, *, canvas_size=None):
        import pyvista as pv
        from .rendering import prepare, layout, SceneRenderer
        if not self.paths: raise ValueError('Select inputs before rendering.')
        prepared=prepare(self.paths,self.settings)
        _,views=layout(self.settings['layout'],prepared.split)
        plot=pv.Plotter(shape=(1,len(views)),border=False,off_screen=True,window_size=canvas_size or (1200,900))
        renderer=SceneRenderer(plot)
        try:
            renderer.render(prepared)
            if self.pending_session: renderer.restore_session(self.pending_session)
        except Exception:
            renderer.dispose(); plot.close(); plot.deep_clean(); raise
        # Build a complete scene before replacing the visible one. A fresh
        # off-screen Plotter has not rendered yet, so its staging window owns
        # no GPU framebuffer. Keep one native drawing context per session:
        # repeated context destruction retains memory in some Mesa drivers.
        staging=plot.render_window
        if not staging.GetNeverRendered():
            renderer.dispose(); plot.close(); plot.deep_clean()
            raise RuntimeError('Scene staging unexpectedly rendered before commit.')
        # Trame changes the native render-window size to the browser canvas.
        # Refit on size modification, before VTK/Web captures projection/image
        # state. A Render StartEvent is too late for the first resized frame.
        # Do not reset independently edited cameras or interfere with export's
        # explicit resize/restore transaction.
        fitting=False
        def fit_canvas(window, _event):
            nonlocal fitting
            if renderer.exporting or fitting or getattr(self,'_sampling_update',False): return
            fitting=True
            try:
                self._fit_screen()
            finally: fitting=False
        try:
            self.close_render(preserve_window=True)
            if self._retained_window is not None:
                window=self._retained_window
                layers=list(staging.GetRenderers())
                size=staging.GetSize(); dpi=staging.GetDPI(); count=staging.GetNumberOfLayers()
                plot.iren.interactor.SetRenderWindow(None)
                for layer in layers: staging.RemoveRenderer(layer)
                staging.Finalize()
                plot.ren_win=window
                window.SetNumberOfLayers(count); window.SetSize(*size); window.SetDPI(dpi)
                for layer in layers: window.AddRenderer(layer)
                plot.iren.set_render_window(window)
            self._retained_window=None
            self.plotter,self.renderer=plot,renderer
            self.render_settings=deepcopy(self.settings)
            self.render_paths=dict(self.paths)
            self._resize_observer=plot.render_window.AddObserver('ModifiedEvent',fit_canvas,1.)
        except Exception:
            # Old actors have already been released. Do not expose a partially
            # committed scene or leave two Python owners of the same window.
            # Retire it through the usual protocol/cache cleanup; retry will
            # create a fresh context. Draft inputs and pending camera survive.
            if self._retained_window is plot.render_window:
                self._retained_window=None
            self.plotter,self.renderer=plot,renderer
            try:
                self.close_render()
            finally:
                self.render_settings=None; self.render_paths=None
            raise
        self.pending_session=None
        self._publish_canvas_warning()
        return renderer

    def _fit_screen(self):
        renderer=self.renderer; window=self.plotter.render_window
        size=window.GetSize(); previous=renderer.fit_size
        interactor=window.GetInteractor()
        style=interactor.GetInteractorStyle() if interactor else None
        if previous and size!=previous and all(previous) and style and style.GetState():
            # A held drag must not mix event coordinates from two raster sizes.
            position=interactor.GetEventPosition(); last=interactor.GetLastEventPosition()
            scale=lambda point: tuple(int(value*new/old+.5) for value,new,old in zip(point,size,previous))
            interactor.SetEventPosition(*scale(position))
            interactor.SetLastEventPosition(*scale(last))
        renderer.resize_fit(*size,annotation_dpi=window.GetDPI()/getattr(self,'screen_ratio',1))
        self._publish_canvas_warning()

    @contextmanager
    def screen_sampling(self, ratio):
        # The protocol changes native size synchronously. Fit only after its DPI
        # and size agree, so a provisional title warning cannot resize the UI.
        previous=getattr(self,'_sampling_update',False)
        self._sampling_update=True
        try:
            self.set_screen_ratio(ratio)
            yield
        finally:
            self._sampling_update=previous
            if not previous and self.renderer:
                self._fit_screen()
                self.renderer.update_label_records()

    def set_screen_ratio(self, ratio):
        # Scalar bars/title/legends use fixed pixels; preserve their CSS extent
        # when the remote image is sampled above/below the CSS canvas size.
        self.screen_ratio=float(ratio)
        if self.renderer:
            # Point-sized node labels must scale with the raster as well. Keep
            # the base screen DPI; figure export retains its own DPI transaction.
            if not hasattr(self,'_screen_dpi_base'):
                self._screen_dpi_base=self.plotter.render_window.GetDPI()
            window=self.plotter.render_window
            old_dpi=window.GetDPI()
            window.SetDPI(max(1,int(self._screen_dpi_base*self.screen_ratio+.5)))
            if window.GetDPI()!=old_dpi:
                # VTK's scalar-bar layout cache does not track window DPI.
                for bar in self.renderer.colorbars: bar.Modified()
            if getattr(self,'_sampling_update',False): return
            self.renderer.update_label_records()
            self.renderer.update_annotation_fonts(self.plotter.render_window.GetDPI()/self.screen_ratio,strict_title=False)
            self._publish_canvas_warning()

    def download(self, width=1600,height=1200,dpi=200,transparent=False,format='png',units='Pixels'):
        files=self.export_files(width,height,dpi,transparent,format,units)
        import io
        archive=io.BytesIO()
        with ZipFile(archive,'w',ZIP_DEFLATED) as z:
            for name,data in files.items(): z.writestr(name,data)
        return archive.getvalue()

    def export_files(self,width=1600,height=1200,dpi=200,transparent=False,format='png',units='Pixels',filename='BrainNet'):
        if getattr(self,'interaction_detail',None): self.interaction_detail.finish()
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

    def close_render(self, *, preserve_window=False):
        if getattr(self,'interaction_detail',None): self.interaction_detail.clear()
        if self._resize_observer is not None and self.plotter is not None:
            self.plotter.render_window.RemoveObserver(self._resize_observer)
        self._resize_observer=None
        if self.renderer is not None: self.renderer.dispose()
        if self.plotter is not None:
            window=self.plotter.render_window
            if not preserve_window and self.retire_view is not None: self.retire_view(window)
            # SceneRenderer owns background/annotation layers outside PyVista's
            # renderer collection. Release their geometry as well as subplots.
            for layer in list(window.GetRenderers()):
                # Finalize cannot visit a renderer after it has been detached.
                # Release its GPU objects while the original context is alive.
                layer.ReleaseGraphicsResources(window)
                layer.RemoveAllViewProps()
                window.RemoveRenderer(layer)
            if preserve_window:
                self.plotter.iren.interactor.SetRenderWindow(None)
                self.plotter.ren_win=None
                self._retained_window=window
            self.plotter.close()
            self.plotter.deep_clean()
        self.renderer=None; self.plotter=None
        self._publish_canvas_warning()
        if not preserve_window and self._retained_window is not None:
            if self.retire_view is not None: self.retire_view(self._retained_window)
            self._retained_window.Finalize(); self._retained_window=None

    def close(self):
        self.close_render(); self._temp.cleanup(); self._assets_temp.cleanup()

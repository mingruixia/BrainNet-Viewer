"""Temporary CPU surface detail, never a scientific-data or export transformation."""
import pyvista as pv
from collections import OrderedDict
import hashlib


class WebInteractionDetail:
    def __init__(self):
        self.entries=[]; self._producers=[]; self.active=False; self.renderer=None; self.note=''
        self.cache=OrderedDict()

    def prepare(self, renderer):
        self.finish(); self.entries=[]; self._producers=[]; self.renderer=renderer; self.note=''
        # EGL's actual device is unknown until the first native frame is drawn.
        renderer.plotter.render_window.Render()
        device=renderer.plotter.render_window.ReportCapabilities().lower()
        if not any(name in device for name in ('llvmpipe','softpipe','software rasterizer')):
            return  # Hardware rendering keeps full geometry even during interaction.
        for picks in renderer.pick_actors:
            for actor,_transform in picks or []:
                mapper=actor.GetMapper(); mapper.Update()
                original=mapper.GetInput()
                if original is None or original.GetNumberOfCells()<25000: continue
                try:
                    # Preserve topology and cut boundaries; original points/arrays remain untouched.
                    mesh=pv.wrap(original); digest=hashlib.sha256()
                    digest.update(mesh.points.tobytes()); digest.update(mesh.faces.tobytes())
                    for data in (mesh.point_data,mesh.cell_data,mesh.field_data):
                        for name in sorted(data.keys()):
                            array=data[name]
                            digest.update(repr((name,array.shape,array.dtype.str)).encode())
                            digest.update(array.tobytes())
                    key=digest.hexdigest()
                    proxy=self.cache.get(key)
                    if proxy is None:
                        proxy=mesh.decimate_pro(.8,preserve_topology=True,
                            splitting=False,boundary_vertex_deletion=False)
                        self.cache[key]=proxy
                        if len(self.cache)>12: self.cache.popitem(last=False)
                    self.cache.move_to_end(key)
                    if proxy.n_cells>=original.GetNumberOfCells() or not proxy.n_cells: continue
                    required=mapper.GetArrayName()
                    if required and required not in proxy.point_data and required not in proxy.cell_data:
                        continue
                    connection=mapper.GetInputConnection(0,0)
                    # vtkAlgorithmOutput does not own its producer. Keep the producer alive
                    # while the mapper is temporarily connected to the proxy.
                    if connection is not None: self._producers.append(connection.GetProducer())
                    self.entries.append((mapper,connection,original,proxy))
                except (ValueError,RuntimeError) as error:
                    self.note=f'Full geometry retained: {error}'

    def start(self):
        if self.active or not self.entries or self.renderer is None or self.renderer.exporting: return
        self.active=True
        try:
            for mapper,_connection,_original,proxy in self.entries: mapper.SetInputData(proxy)
        except Exception:
            self.finish(); raise

    def finish(self):
        if not self.active: return
        for mapper,connection,original,_proxy in self.entries:
            if connection is not None: mapper.SetInputConnection(connection)
            else: mapper.SetInputData(original)
        self.active=False

    def clear(self):
        self.finish(); self.entries=[]; self._producers=[]; self.renderer=None

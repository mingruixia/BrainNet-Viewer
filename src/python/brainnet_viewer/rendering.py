"""Shared geometry preparation and VTK renderer for the desktop and Web."""
from dataclasses import dataclass
from pathlib import Path
import sys
import numpy as np
import pyvista as pv
from scipy import ndimage, sparse
from scipy.sparse.csgraph import connected_components
from matplotlib.colors import ListedColormap
from .palettes import PALETTES, palette
from .io import read_surface, read_nodes, read_edges, read_surface_map, read_volume
from .network import select_edges, node_radii, edge_radii, edge_diagnostics
from .volume import map_volume, threshold_volume, roi_labels, gaussian_kernel
from .montage import pack, boundary_mask
from .appearance import material, apply_material
from .binding import geometry_signature, custom_edge_colors
from .display import double_brain, label_positions, label_font
from .session import content_hashes, signature, validate_session
from .render_detail import resolve_detail
from .text_rendering import font_for_strings, use_font, fit_title, validate_title, TitleFitError


def _is_mac_qt_plotter(plotter):
    return sys.platform == "darwin" and hasattr(plotter, "render_signal")


def _prepare_raster_capture(plotter):
    # On macOS QtInteractor.render emits from a worker thread. An export
    # callback cannot consume that queued render before reading the front
    # buffer, so explicitly draw the resized window on the GUI thread.
    if _is_mac_qt_plotter(plotter):
        plotter.render_window.MakeCurrent()
        plotter.render_window.Render()

def mapped_colors(values, name, limits):
    if len(limits): low, high = limits
    elif len(values): low, high = float(np.min(values)), float(np.max(values))
    else: low, high = 0., 1.
    table = palette(name)
    if high <= low: return np.tile(table[0],(len(values),1))
    indices = np.clip(np.floor((values-low)/(high-low)*255+.5),0,255).astype(int)
    return table[indices]


def module_colors(modules, name):
    labels, ranks = np.unique(modules, return_inverse=True)
    if isinstance(name, str): colors = palette(name, max(2,len(labels)))
    else:
        colors = palette(name, len(name)); ranks %= len(colors)
    return colors[ranks]


def node_colors(nodes, settings):
    mode = settings["color_mode"]
    if mode == "uniform": return np.tile(settings["color"], (len(nodes.modules), 1))
    if mode in ("modular", "custom", "module", "modules"): return module_colors(nodes.modules, settings["colormap"])
    if mode == "mapped": return mapped_colors(nodes.modules, settings["colormap"], settings["color_limits"])
    if mode == "threshold": return np.where((nodes.modules > settings["color_threshold"])[:, None], settings["color_high"], settings["color_low"])
    raise ValueError(f"Unsupported node color mode '{mode}'.")


def hemispheres(surface):
    faces, points = surface.faces, surface.points
    negative = points[faces,0].mean(axis=1) <= 0
    if not negative.any() or negative.all(): return None
    if not np.intersect1d(faces[negative].ravel(), faces[~negative].ravel()).size:
        return negative
    edges = np.vstack([faces[:,[0,1]], faces[:,[1,2]], faces[:,[2,0]]])
    graph = sparse.coo_matrix((np.ones(len(edges)), (edges[:,0],edges[:,1])), shape=(len(points),len(points)))
    _, labels = connected_components(graph, directed=False)
    used = np.unique(faces); ids = np.unique(labels[used])
    if len(ids) != 2: return None
    for left, right in (ids, ids[::-1]):
        if np.mean(points[used[labels[used]==left],0] <= 0) >= .95 and np.mean(points[used[labels[used]==right],0] > 0) >= .95:
            return labels[faces[:,0]] == left
    return None


def polydata(surface, face_mask=None):
    faces = surface.faces if face_mask is None else surface.faces[face_mask]
    mesh = pv.PolyData(surface.points, np.column_stack((np.full(len(faces),3),faces)))
    mesh.point_data["original_vertex"] = np.arange(len(surface.points))
    return mesh


def roi_meshes(volume, volume_settings, settings):
    volume = roi_labels(volume, volume_settings)
    data = volume.data
    finite = data[np.isfinite(data)]
    labels = np.unique(finite[(finite > 0) & (np.abs(finite-np.round(finite)) < 1e-8)])
    if not settings["draw_all"]: labels = labels[np.isin(labels,settings["selection"])]
    output = []
    kernel_size = 1 if settings["smoothing"] == "none" or settings["smoothing_kernel"] <= 1 else max(3, 2*(settings["smoothing_kernel"]//2)+1)
    if settings["smoothing"] not in ("none", "gaussian", "box"): raise ValueError("Unsupported ROI smoothing.")
    colors = palette(settings["palette"])
    for label in labels:
        coordinates = np.argwhere(data == label)
        padding = max(2,kernel_size//2+1)
        lower, upper = coordinates.min(axis=0)-padding, coordinates.max(axis=0)+padding
        mask = np.zeros(upper-lower+1, dtype=float)
        mask[tuple((coordinates-lower).T)] = 1
        original = mask.copy()
        if kernel_size > 1:
            kernel = gaussian_kernel(kernel_size) if settings["smoothing"] == "gaussian" else np.ones((kernel_size,)*3)/kernel_size**3
            mask = ndimage.convolve(mask,kernel,mode="constant",cval=0)
            components, count = ndimage.label(original, ndimage.generate_binary_structure(3,3))
            retained = np.unique(components[mask > .5]); retained = retained[retained != 0]
            if len(retained) != count: mask = original  # protect every small island, whole-label fallback
        grid = pv.ImageData(dimensions=mask.shape,origin=lower)
        grid.point_data["mask"] = mask.ravel(order="F")
        mesh = grid.contour([.5],scalars="mask").triangulate()
        if not mesh.n_cells: continue
        mesh.points = (volume.affine @ np.column_stack((mesh.points,np.ones(mesh.n_points))).T)[:3].T
        color = settings["color"]
        if settings["color_mode"] == "index": color = colors[(int(round(label))-1)%256]
        elif settings["color_mode"] == "custom":
            custom = np.asarray(settings["custom_colors"])
            row = custom[custom[:,0]==label] if custom.ndim==2 and custom.shape[1]==4 else []
            if len(row) != 1: raise ValueError(f"Missing custom ROI color for label {label}.")
            color = row[0,1:]
        output.append((int(label), mesh, color))
    return output


@dataclass
class Prepared:
    surface: object
    nodes: object
    matrix: object
    mapped: object
    rois: list
    pairs: np.ndarray
    edge_values: np.ndarray
    settings: dict
    split: object
    boundary: object
    display_transform: object = None
    input_hashes: object = None
    input_paths: object = None
    diagnostics: tuple = ()


def prepare(paths, settings):
    hashes = content_hashes(paths)
    if settings["fiber"]["visible"]: raise ValueError("Fiber rendering is not yet ported.")
    surface = read_surface(paths["surface"]) if "surface" in paths else None
    nodes = read_nodes(paths["node"]) if "node" in paths else None
    transform = double_brain(surface, len(nodes.positions) if nodes else 0, settings,
                             "volume" in paths or "surface_map" in paths)
    matrix = read_edges(paths["edge"],len(nodes.positions)) if "edge" in paths and nodes else None
    if "edge" in paths and nodes is None: raise ValueError("Add nodes before rendering edges.")
    pairs, values = select_edges(matrix,settings["edge"],nodes.positions) if matrix is not None else (np.empty((0,2),int),np.empty(0))
    diagnostics = edge_diagnostics(matrix, settings['edge']) if matrix is not None else []
    mapped, rois = None, []
    if "surface_map" in paths:
        if surface is None: raise ValueError("A vertex map requires a surface.")
        mapped = read_surface_map(paths["surface_map"],len(surface.points))
    if "volume" in paths and settings["volume"]["display"]:
        volume = read_volume(paths["volume"])
        options = settings['volume']
        if options['cluster_size'] > 1 and not (options['threshold_mode'] == 'cluster' or
                options['threshold_mode'] == 'p-value' and options['type'] == 'roi'):
            diagnostics.append('Cluster size is not applied in the selected threshold mode.')
        if settings["volume"]["type"] == "roi": rois = roi_meshes(volume, settings["volume"],settings["roi"])
        else:
            if surface is None: raise ValueError("Volume to surface mapping requires a surface.")
            volume, _ = threshold_volume(volume,settings["volume"])
            mapped = map_volume(volume,surface.points,surface.faces,settings["volume"]["map_algorithm"])
    if surface is None and nodes is None and not rois: raise ValueError("Add a surface, nodes or a displayed ROI volume.")
    boundary=None
    if settings["surface"]["boundary_mode"]!="none":
        if surface is None: raise ValueError("Surface boundary needs a surface.")
        if settings["surface"]["boundary_mode"]=="custom":
            boundary=np.asarray(settings["surface"]["boundary_mask"])
            if boundary.shape!=(len(surface.points),) or not np.isin(boundary,[0,1]).all(): raise ValueError("Custom boundary needs one binary value per vertex.")
            if settings["surface"]["boundary_mesh_sha256"]!=geometry_signature(surface.points,surface.faces): raise ValueError("Custom boundary is unbound or belongs to different ordered geometry.")
            boundary=boundary.astype(bool)
        else:
            if mapped is None: raise ValueError("Surface boundary needs a mapped surface.")
            boundary=boundary_mask(mapped,surface.faces,settings["surface"]["boundary_mode"],settings["surface"]["boundary_threshold"])
    if surface and settings["surface"]["color_mode"]=="vertex-rgb" and len(settings["surface"]["vertex_colors"]):
        if settings["surface"]["vertex_colors_mesh_sha256"]!=geometry_signature(surface.points,surface.faces): raise ValueError("Vertex RGB is unbound or belongs to different ordered geometry.")
    if content_hashes(paths) != hashes: raise ValueError("An input or its external data changed while being read. Reload the files.")
    return Prepared(surface,nodes,matrix,mapped,rois,pairs,values,settings,hemispheres(surface) if surface else None,
                    boundary,transform,hashes,{role:Path(path).resolve() for role,path in paths.items()},tuple(diagnostics))


def layout(settings, split):
    preset = settings["preset"]
    if preset not in range(1,6): raise ValueError("Layout preset must be 1 through 5.")
    if preset == 1:
        table = [(-90,0),(0,90),(180,0),(-45,25),(90,0),(0,-90),(0,0),(-45,25)]
        direction = settings["view_direction"]
        if not 1 <= direction <= 8: raise ValueError("View direction must be 1 through 8.")
        az, el = table[direction-1]
        if direction == 4 and settings["custom_azimuth"] != []: az,el=settings["custom_azimuth"],settings["custom_elevation"]
        return [(0,0,1,1)],[(az,el,"full",None)]
    if split is None:
        positions=[(.005,.520,.325,.470),(.3375,.520,.325,.470),(.670,.520,.325,.470),
                   (.005,.010,.325,.470),(.3375,.010,.325,.470),(.670,.010,.325,.470)]
        return positions,[(az,el,"full",None) for az,el in [(-90,0),(0,90),(180,0),(90,0),(0,-90),(0,0)]]
    if preset == 2:
        positions=[(.005,.665,.325,.325),(.3375,.665,.325,.325),(.670,.665,.325,.325),
                   (.005,.340,.325,.315),(.3375,.015,.325,.580),(.670,.340,.325,.315),(.005,.015,.325,.315),(.670,.015,.325,.315)]
        views=[(-90,0,"left",None),(0,90,"full",None),(90,0,"right",None),(90,0,"left",None),
               (0,-90,"full",None),(-90,0,"right",None),(180,0,"full",None),(0,0,"full",None)]
    elif preset in (3,4):
        positions=[(.035,.520,.450,.440),(.515,.520,.450,.440),(.035,.040,.450,.440),(.515,.040,.450,.440)]
        views=[(-90,0,"left",None),(90,0,"right",None),(90,0,"left",None),(-90,0,"right",None)]
        if preset == 4:
            positions=[(.015,.675,.470,.310),(.515,.675,.470,.310),(.015,.345,.470,.310),(.515,.345,.470,.310),(.015,.015,.470,.310),(.515,.015,.470,.310)]
            views += [(-90,-90,"left",[-1,0,0]),(90,-90,"right",[1,0,0])]
    elif preset == 5:
        positions=[(.005,.540,.285,.450),(.295,.270,.410,.460),(.710,.540,.285,.450),(.005,.010,.285,.450),(.710,.010,.285,.450)]
        views=[(-90,0,"left",None),(0,90,"full",None),(90,0,"right",None),(90,0,"left",None),(-90,0,"right",None)]
    else: raise ValueError("Layout preset must be 1 through 5.")
    return positions,views


def surface_map_palette(values, surface):
    """Continuous scalar legend; exact zero/missing colors are applied per vertex."""
    finite=np.asarray(values)[np.isfinite(values)]
    limits=surface["color_limits"] or ([float(finite.min()),float(finite.max())] if finite.size else [0.,1.])
    if limits[0]==limits[1]: limits=[limits[0],limits[0]+1]
    table=np.asarray(palette(surface["colormap"])).copy()
    return ListedColormap(table),limits


class SceneRenderer:
    def __init__(self, plotter):
        self.plotter = plotter
        self.prepared = None
        self.viewports = []
        self.initial_cameras = []
        self.pick_actors = []
        self.fit_spans = []
        self.fit_size = None
        self.exporting = False
        self.label_records = []
        self.label_observers = []
        self.title_actor = None
        self.text_fonts = {}
        self.annotation_warning = ''
        # A full-window background fills the intentional gaps between viewports.
        from vtkmodules.vtkRenderingCore import vtkRenderer
        self.background = vtkRenderer()
        self.background.SetLayer(0); self.background.SetInteractive(False)
        self.annotations = vtkRenderer()
        self.annotations.SetLayer(2); self.annotations.SetInteractive(False)
        self.annotations.SetPreserveColorBuffer(True); self.annotations.SetBackgroundAlpha(0)
        self.plotter.render_window.SetNumberOfLayers(max(3,self.plotter.render_window.GetNumberOfLayers()))
        self.plotter.render_window.AddRenderer(self.background)
        self.plotter.render_window.AddRenderer(self.annotations)

    def render(self, prepared, *, orientation_labels=True):
        # Check glyph coverage before clearing a previously valid canvas.
        font_for_strings([prepared.settings['image']['title']], bold=True)
        font_for_strings([prepared.settings['image']['colorbar_label']])
        if prepared.nodes is not None and prepared.settings['node']['label_mode'] != 'none':
            scopes = {view[2] for view in layout(prepared.settings['layout'], prepared.split)[1]}
            visible = np.zeros(len(prepared.nodes.positions), dtype=bool)
            node = prepared.settings['node']
            for scope in scopes:
                visible |= self.node_mask(prepared, scope)
            if node['label_mode'] == 'threshold':
                basis = prepared.nodes.modules if node['label_basis'] == 'module' else prepared.nodes.values
                visible &= basis > node['label_threshold']
            font_for_strings([prepared.nodes.labels[i] for i in np.flatnonzero(visible)],
                             bold=node['label_font_weight'] == 'bold')
        width,height=self.plotter.window_size
        if width<=0 or height<=0: raise ValueError("The canvas is not yet sized; retry rendering after the window appears.")
        validate_title(prepared.settings['image']['title'],width,height,self.plotter.render_window.GetDPI())
        appearance=material(prepared.settings["global"])
        for camera, tag in self.label_observers: camera.RemoveObserver(tag)
        self.label_observers, self.label_records = [], []
        self.prepared = prepared
        self.plotter.clear()
        self.background.RemoveAllViewProps()
        self.annotations.RemoveAllViewProps()
        self.colorbars = []
        self.legends = []
        self.annotation_text_props = []
        self.title_actor = None
        self.text_fonts = {}
        settings = prepared.settings
        self.appearance=appearance
        self.detail_policy = resolve_detail(settings["global"]["render_detail"],
                                            len(prepared.nodes.positions) if prepared.nodes else 0,
                                            len(prepared.pairs))
        self.node_sphere = None
        if prepared.nodes:
            detail = self.detail_policy.node_detail
            self.node_sphere = pv.Sphere(radius=1, theta_resolution=detail, phi_resolution=detail+1)
        self.background.SetBackground(*settings["global"]["background_color"])
        positions, views = layout(settings["layout"],prepared.split)
        if len(self.plotter.renderers) != len(views): raise ValueError("Plotter view count does not match layout.")
        self.viewports, self.initial_cameras, self.pick_actors = positions, [], []
        self.scientific_bounds = []
        # Shared fit: physical millimetres use the same pixel scale across panes.
        spans, centers, directions, ups = [], [], [], []
        for i, ((x,y,w,h),(az,el,scope,up)) in enumerate(zip(positions,views)):
            self.plotter.subplot(0,i)
            renderer = self.plotter.renderer
            renderer.SetLayer(1); renderer.SetPreserveColorBuffer(False)
            renderer.SetViewport(x,y,x+w,y+h)
            self.plotter.set_background(np.asarray(settings["global"]["background_color"],dtype=float))
            renderer.RemoveAllLights()
            light_direction=settings["global"]["light_direction"]
            light=pv.Light(light_type="headlight" if light_direction=="headlight" else "camera light",intensity=1)
            if light_direction in ("right","left"):
                # MATLAB camlight uses +/-30 azimuth and +30 elevation in
                # camera coordinates; VTK direction-angle uses a different pole.
                light.position=((1 if light_direction=="right" else -1)*np.sqrt(3)/4,.5,.75)
                light.focal_point=(0,0,0)
            elif light_direction!="headlight": raise ValueError("Light direction must be left, right or headlight.")
            renderer.AddLight(light)
            vertices = []
            if prepared.surface:
                face_mask = None if scope=="full" else prepared.split if scope=="left" else ~prepared.split
                mesh = polydata(prepared.surface,face_mask)
                kwargs = dict(color=np.asarray(settings["surface"]["color"],dtype=float), opacity=settings["surface"]["opacity"],
                              smooth_shading=settings["global"]["shading"]=="interp",
                              show_edges=settings["global"]["shading"]=="faceted", edge_color="black")
                mapped = prepared.mapped
                if not settings["volume"]["display"] and settings["surface"]["color_mode"] == "uniform": mapped=None
                if settings["surface"]["color_mode"] == "vertex-rgb":
                    if len(settings["surface"]["vertex_colors"]): mapped=np.asarray(settings["surface"]["vertex_colors"],dtype=float)
                    elif mapped is None or mapped.ndim!=2: raise ValueError("Add or bind a vertex RGB table first.")
                    expected = mesh.n_points*(2 if prepared.display_transform else 1)
                    if mapped.shape!=(expected,3) or not np.isfinite(mapped).all() or ((mapped<0)|(mapped>1)).any():
                        raise ValueError("Vertex RGB needs one RGB row in [0,1] per displayed surface vertex (2N for Double Brain).")
                    all_rgb = mapped; mapped = mapped[:mesh.n_points]
                if mapped is not None:
                    if mapped.ndim==2: kwargs.update(scalars=mapped,rgb=True)
                    else:
                        volume = settings["volume"]
                        map_name = volume["colormap"] if volume["display"] else settings["surface"]["colormap"]
                        cmap = ListedColormap(palette(map_name))
                        limits = settings["surface"]["color_limits"]
                        if volume["display"]:
                            cmap, limits = self.volume_colors(mapped,volume,settings["surface"]["color"])
                        else:
                            cmap, limits = surface_map_palette(mapped,settings["surface"])
                        if limits[0]==limits[1]: limits=[limits[0],limits[0]+1]
                        kwargs.update(scalars=mapped,cmap=cmap,clim=limits,
                                      show_scalar_bar=False)
                        if not volume["display"] or volume["adjust_null"]:
                            rgb=np.asarray(cmap((mapped-limits[0])/(limits[1]-limits[0])))[:,:3]
                            null=~np.isfinite(mapped) | (mapped==0)
                            if volume["display"] and volume["display_mode"]=="positive": null |= mapped <= (volume["positive_minimum"] if volume["positive_minimum"]!=[] else 0)
                            elif volume["display"] and volume["display_mode"]=="negative": null |= mapped >= (volume["negative_maximum"] if volume["negative_maximum"]!=[] else 0)
                            elif volume["display"]:
                                null |= (mapped >= (volume["negative_maximum"] if volume["negative_maximum"]!=[] else 0)) & (mapped <= (volume["positive_minimum"] if volume["positive_minimum"]!=[] else 0))
                            rgb[null]=settings["surface"]["color"]
                            for key in ("cmap","clim"): kwargs.pop(key,None)
                            kwargs.update(scalars=rgb,rgb=True)
                scalar_mapper=None
                if prepared.boundary is not None:
                    if "scalars" not in kwargs: rgb=np.tile(settings["surface"]["color"],(mesh.n_points,1))
                    elif kwargs.get("rgb"): rgb=np.asarray(kwargs["scalars"]).copy()
                    else:
                        lut=pv.LookupTable(cmap=kwargs["cmap"],scalar_range=kwargs["clim"])
                        scalar_mapper=pv.DataSetMapper(dataset=mesh); scalar_mapper.lookup_table=lut
                        mesh["boundary_value"]=mapped; scalar_mapper.array_name="boundary_value"
                        scalar_mapper.scalar_range=kwargs["clim"]
                        rgb=np.asarray(kwargs["cmap"]((mapped-kwargs["clim"][0])/(kwargs["clim"][1]-kwargs["clim"][0])))[:,:3]
                    rgb[prepared.boundary]=settings["surface"]["boundary_color"]
                    kwargs={key:value for key,value in kwargs.items() if key not in ("scalars","rgb","cmap","clim","show_scalar_bar","scalar_bar_args")}
                    kwargs.update(scalars=rgb,rgb=True)
                actor = self.add_geometry(mesh,**kwargs)
                picks = [(actor, None)]
                vertices.append(prepared.surface.points[np.unique(mesh.faces.reshape(-1,4)[:,1:])])
                if prepared.display_transform:
                    duplicate = mesh.copy(deep=True)
                    duplicate.points = prepared.display_transform.forward(mesh.points)
                    if duplicate.point_data.active_normals is not None:
                        duplicate.point_data.active_normals = duplicate.point_data.active_normals @ prepared.display_transform.matrix.T
                    if duplicate.cell_data.active_normals is not None:
                        duplicate.cell_data.active_normals = duplicate.cell_data.active_normals @ prepared.display_transform.matrix.T
                    duplicate_kwargs = dict(kwargs)
                    if settings["surface"]["color_mode"] == "vertex-rgb":
                        rgb = all_rgb[mesh.n_points:].copy()
                        if prepared.boundary is not None: rgb[prepared.boundary] = settings["surface"]["boundary_color"]
                        duplicate_kwargs.update(scalars=rgb,rgb=True)
                    duplicate_actor = self.add_geometry(duplicate,**duplicate_kwargs)
                    picks.append((duplicate_actor,prepared.display_transform))
                    vertices.append(prepared.display_transform.forward(vertices[-1]))
                self.pick_actors.append(picks)
            else: self.pick_actors.append(None)
            self.draw_network(prepared,scope)
            if prepared.nodes:
                positions_for_fit=self.node_positions(prepared)
                if scope=="left": positions_for_fit=positions_for_fit[positions_for_fit[:,0]<=0]
                elif scope=="right": positions_for_fit=positions_for_fit[positions_for_fit[:,0]>0]
                if len(positions_for_fit):
                    radius=max(node_radii(prepared.nodes,settings["node"]))
                    vertices.extend([positions_for_fit-radius,positions_for_fit+radius])
            for label,mesh,color in prepared.rois:
                roi_scope=scope
                if roi_scope=="full" and prepared.surface:
                    name=prepared.surface.path.name.lower()
                    if name.startswith("lh.") or np.quantile(prepared.surface.points[:,0],.95)<=0: roi_scope="left"
                    elif name.startswith("rh.") or np.quantile(prepared.surface.points[:,0],.05)>=0: roi_scope="right"
                if roi_scope!="full": mesh=mesh.clip(normal="x",origin=(0,0,0),invert=roi_scope=="left")
                if mesh.n_cells:
                    self.add_geometry(mesh,color=np.asarray(color,dtype=float),smooth_shading=True)
                    vertices.append(mesh.points)
            vertices = np.vstack(vertices)
            self.scientific_bounds.append((vertices.min(axis=0),vertices.max(axis=0)))
            az,el=np.deg2rad([az,el])
            direction=np.array([np.sin(az)*np.cos(el),-np.cos(az)*np.cos(el),np.sin(el)])
            if up is None: up=[0,1,0] if abs(direction[2])>.99 else [0,0,1]
            right=np.cross(up,direction); right/=np.linalg.norm(right)
            up=np.cross(direction,right)
            projected=vertices @ np.column_stack((right,up))
            spans.append(np.maximum(np.ptp(projected,axis=0),1)*1.08)
            centers.append((vertices.min(axis=0)+vertices.max(axis=0))/2)
            directions.append(direction); ups.append(up)
        width,height=self.plotter.window_size
        if width<=0 or height<=0: raise ValueError("The canvas is not yet sized; retry rendering after the window appears.")
        effective_preset=settings["layout"]["preset"] if prepared.split is not None else 2
        positions=self.figure_annotations(prepared,pack(spans,effective_preset)); self.viewports=positions
        for renderer,(x,y,w,h) in zip(self.plotter.renderers,positions): renderer.SetViewport(x,y,x+w,y+h)
        self.fit_spans=spans; self.fit_size=(width,height)
        pixel_scale=self.pixel_scale(width,height)
        distance=max(np.linalg.norm(span) for span in spans)*3
        for i,((_,_,_,h),center,direction,up) in enumerate(zip(positions,centers,directions,ups)):
            self.plotter.subplot(0,i)
            camera=self.plotter.camera
            camera.position=center+direction*distance; camera.focal_point=center; camera.up=up
            camera.parallel_projection=True; camera.parallel_scale=height*h/(2*pixel_scale)
            self.plotter.renderer.ResetCameraClippingRange()
            self.initial_cameras.append((camera.position,camera.focal_point,camera.up,camera.parallel_scale,
                                         camera.parallel_projection,camera.view_angle))
        self.plotter.subplot(0,0)
        self.update_annotation_fonts(self.plotter.render_window.GetDPI())
        self.update_label_records()
        for renderer in self.plotter.renderers:
            if any(record[0] is renderer for record in self.label_records):
                tag = renderer.camera.AddObserver("ModifiedEvent",lambda *_: self.update_label_records())
                self.label_observers.append((renderer.camera,tag))
        if orientation_labels and settings["global"]["show_orientation_labels"] and prepared.split is not None and len(views)>1:
            text_color="black" if np.mean(settings["global"]["background_color"])>.5 else "white"
            self.plotter.add_text("L",position="upper_left",font_size=13,color=text_color)
            self.plotter.subplot(0,2 if settings["layout"]["preset"] in (2,5) else 1)
            self.plotter.add_text("R",position="upper_right",font_size=13,color=text_color)
            self.plotter.subplot(0,0)
        self.plotter.render()

    def pixel_scale(self, width, height):
        return min(min(width*w/span[0],height*h/span[1]) for (_,_,w,h),span in zip(self.viewports,self.fit_spans))

    @staticmethod
    def node_positions(prepared):
        positions = prepared.nodes.positions.copy()
        transform = prepared.display_transform
        if transform: positions[transform.first_moved_node:] = transform.forward(positions[transform.first_moved_node:])
        return positions

    def update_label_records(self):
        renderers = list(self.plotter.renderers)
        for renderer,cloud,coordinates,radii,settings,names,actor in self.label_records:
            index = renderers.index(renderer)
            if index >= len(self.scientific_bounds): continue
            camera = renderer.camera; low,high = self.scientific_bounds[index]
            direction = np.asarray(camera.position)-camera.focal_point
            if np.linalg.norm(direction)<=1e-12 or np.linalg.norm(np.cross(direction,camera.up))<=1e-12: continue
            points = label_positions(coordinates,radii,low,high,np.asarray(camera.position),
                np.asarray(camera.focal_point),np.asarray(camera.up),not camera.parallel_projection,settings["label_in_front"])[0]
            family,pixels = label_font(settings,self.plotter.render_window.GetDPI(),
                                      self.plotter.window_size[1]*self.viewports[index][3])
            prop = actor.GetMapper().GetInputAlgorithm().GetTextProperty()
            # VTK text sizes are points; convert the requested pixel extent once.
            prop.SetFontSize(max(1,int(np.floor(pixels*72/self.plotter.render_window.GetDPI()+.5))))
            cloud.points = self.bound_label_points(renderer,points,names,prop,index)

    def bound_label_points(self, renderer, points, names, prop, index):
        from vtkmodules.vtkRenderingFreeType import vtkFreeTypeTools
        tools=vtkFreeTypeTools.GetInstance(); width,height=self.plotter.window_size
        x,y,w,h=self.viewports[index]
        limits=(x*width+3,(x+w)*width-3,y*height+3,(y+h)*height-3)
        dpi=self.plotter.render_window.GetDPI()
        result=points.copy()
        boxes=[]
        for name in names:
            box=[0,0,0,0]; tools.GetBoundingBox(prop,name,dpi,box); boxes.append(box)
        max_width=max(box[1]-box[0] for box in boxes)
        # LabelPlacementMapper may place text differently from the FreeType
        # justification on HiDPI Qt. Reserve the full text width on both sides.
        if 2*max_width>limits[1]-limits[0]:
            prop.SetFontSize(max(1,int(prop.GetFontSize()*(limits[1]-limits[0])/(2*max_width))))
            for name,box in zip(names,boxes): tools.GetBoundingBox(prop,name,dpi,box)
        for k,(point,box) in enumerate(zip(points,boxes)):
            renderer.SetWorldPoint(*point,1); renderer.WorldToDisplay(); screen=renderer.GetDisplayPoint()
            margin_x=max(abs(box[0]),abs(box[1]),box[1]-box[0])
            margin_y=max(abs(box[2]),abs(box[3]),box[3]-box[2])
            sx=np.clip(screen[0],limits[0]+margin_x,max(limits[0]+margin_x,limits[1]-margin_x))
            sy=np.clip(screen[1],limits[2]+margin_y,max(limits[2]+margin_y,limits[3]-margin_y))
            renderer.SetDisplayPoint(sx,sy,screen[2]); renderer.DisplayToWorld(); world=renderer.GetWorldPoint()
            if abs(world[3])>1e-12: result[k]=np.asarray(world[:3])/world[3]
        return result

    def capture_camera(self):
        width,height = self.plotter.window_size; pixel = self.pixel_scale(width,height)
        views = []
        for renderer,(_,_,_,h) in zip(self.plotter.renderers,self.viewports):
            camera = renderer.camera
            scale=camera.parallel_scale if camera.parallel_projection else float(np.linalg.norm(np.asarray(camera.position)-camera.focal_point)*np.tan(np.deg2rad(camera.view_angle)/2))
            views.append({"position":list(camera.position),"target":list(camera.focal_point),"up":list(camera.up),
                          "projection":"orthographic" if camera.parallel_projection else "perspective",
                          "parallel_scale":scale,"zoom_factor":scale/(height*h/(2*pixel)),
                          "view_angle":camera.view_angle})
        return {"layout":self.prepared.settings["layout"]["preset"],"views":views}

    def restore_session(self, state):
        state = validate_session(state)
        expected = signature(self.prepared.input_hashes,self.prepared.settings)
        if state["scene_signature"] != expected: return "data-or-settings-mismatch"
        saved = state["camera"]
        if saved is None: return "no-camera"
        if saved["layout"] != self.prepared.settings["layout"]["preset"] or len(saved["views"]) != len(self.viewports):
            return "layout-mismatch"
        width,height = self.plotter.window_size; pixel = self.pixel_scale(width,height)
        for renderer,view,(_,_,_,h) in zip(self.plotter.renderers,saved["views"],self.viewports):
            camera = renderer.camera
            camera.position = view["position"]; camera.focal_point = view["target"]; camera.up = view["up"]
            camera.parallel_projection = view["projection"] == "orthographic"; camera.view_angle = view["view_angle"]
            camera.parallel_scale = view["zoom_factor"]*height*h/(2*pixel)
            if not camera.parallel_projection:
                distance=np.linalg.norm(np.asarray(camera.position)-camera.focal_point)
                camera.view_angle=float(np.rad2deg(2*np.arctan(camera.parallel_scale/distance)))
            renderer.ResetCameraClippingRange()
        self.update_label_records(); self.plotter.render()
        return "restored"

    def resize_fit(self, width, height, *, annotation_dpi=None, strict_title=False):
        """Adapt aspect ratio without resetting each subplot's pan, rotation or zoom."""
        if width > 0 and height > 0:
            self.update_annotation_fonts(annotation_dpi or self.plotter.render_window.GetDPI(),
                                         size=(width,height), strict_title=strict_title)
        if not self.initial_cameras or width<=0 or height<=0 or self.fit_size==(width,height): return
        old_width,old_height=self.fit_size
        old_pixel=self.pixel_scale(old_width,old_height); new_pixel=self.pixel_scale(width,height)
        for renderer,(_,_,_,h) in zip(self.plotter.renderers,self.viewports):
            camera=renderer.camera
            zoom_ratio=camera.parallel_scale/(old_height*h/(2*old_pixel))
            camera.parallel_scale=zoom_ratio*height*h/(2*new_pixel)
            if not camera.parallel_projection:
                ratio=(height*h/(2*new_pixel))/(old_height*h/(2*old_pixel))
                camera.view_angle=float(np.rad2deg(2*np.arctan(np.tan(np.deg2rad(camera.view_angle)/2)*ratio)))
            renderer.ResetCameraClippingRange()
        self.fit_size=(width,height)
        self.update_label_records()

    def volume_colors(self, values, settings, surface_color=None):
        settings=dict(settings)
        if surface_color is not None: settings["null_color"]=surface_color
        values=values[np.isfinite(values)]; table=palette(settings["colormap"])
        mode=settings["display_mode"]
        neg_min=settings["negative_minimum"]; neg_max=settings["negative_maximum"]
        pos_min=settings["positive_minimum"]; pos_max=settings["positive_maximum"]
        if mode=="positive":
            positive=values[values>0]
            limits=[pos_min if pos_min!=[] else 0,pos_max if pos_max!=[] else float(positive.max()) if len(positive) else 1]
            table=palette(table[128:])
        elif mode=="negative":
            negative=values[values<0]
            limits=[neg_min if neg_min!=[] else float(negative.min()) if len(negative) else -1,neg_max if neg_max!=[] else 0]
            table=palette(table[:128])
        elif mode!="both": raise ValueError("Unsupported volume display values mode.")
        else:
            limits=[neg_min if neg_min!=[] else float(values.min()) if len(values) else 0,
                    pos_max if pos_max!=[] else float(values.max()) if len(values) else 1]
            extent=max(abs(limits[0]),abs(limits[1]),np.finfo(float).eps); limits=[-extent,extent]
        if limits[1]<=limits[0]: limits[1]=limits[0]+1
        if settings["adjust_null"]:
            if mode=="both":
                base=table.copy(); samples=np.linspace(*limits,256)
                table=np.tile(settings["null_color"],(256,1))
                negative_max=neg_max if neg_max!=[] else 0; positive_min=pos_min if pos_min!=[] else 0
                negative=samples<negative_max; positive=samples>positive_min
                indices=np.clip(np.floor(127*(samples[negative]-limits[0])/max(negative_max-limits[0],np.finfo(float).eps)+.5),0,127).astype(int)
                table[negative]=base[indices]
                indices=np.clip(np.floor(127*(samples[positive]-positive_min)/max(limits[1]-positive_min,np.finfo(float).eps)+.5),0,127).astype(int)
                table[positive]=base[128+indices]
                table[127:129]=settings["null_color"]
            elif mode=="positive": table[0]=settings["null_color"]
            else: table[-1]=settings["null_color"]
        return ListedColormap(table),limits

    def add_geometry(self, mesh, **kwargs):
        kwargs["lighting"]=self.appearance["lighting"]!="none"
        actor=self.plotter.add_mesh(mesh,**kwargs)
        apply_material(actor,self.appearance)
        return actor

    @staticmethod
    def node_mask(prepared, scope):
        nodes=prepared.nodes
        node,edge=prepared.settings["node"],prepared.settings["edge"]
        keep=np.ones(len(nodes.positions),dtype=bool)
        basis=nodes.modules if node["selection_basis"]=="module" else nodes.values
        if node["selection_mode"]=="threshold": keep &= basis>node["threshold"]
        elif node["selection_mode"]=="connected":
            keep[:]=False; keep[np.unique(prepared.pairs)]=True
        elif node["selection_mode"]!="all": raise ValueError("Unsupported node selection.")
        if scope=="left": keep &= nodes.positions[:,0]<=0
        elif scope=="right": keep &= nodes.positions[:,0]>0
        radii=node_radii(nodes,node)
        keep &= radii > 0
        return keep

    def text_font(self, strings, *, bold=False):
        info = font_for_strings(strings, bold=bold)
        if info:
            self.text_fonts[info['sha256']] = {key: info[key] for key in ('file','sha256','family')}
        return info

    def draw_network(self, prepared, scope):
        nodes=prepared.nodes
        if nodes is None: return
        node,edge=prepared.settings["node"],prepared.settings["edge"]
        node_positions = self.node_positions(prepared)
        keep = self.node_mask(prepared, scope)
        radii = node_radii(nodes, node)
        colors=node_colors(nodes,node)
        if keep.any():
            cloud=pv.PolyData(node_positions[keep]); cloud["radius"]=radii[keep]; cloud["rgb"]=(colors[keep]*255).astype(np.uint8)
            glyph=cloud.glyph(scale="radius",orient=False,geom=self.node_sphere)
            self.add_geometry(glyph,scalars="rgb",rgb=True,smooth_shading=True)
            labels=keep.copy()
            if node["label_mode"]=="none": labels[:]=False
            elif node["label_mode"]=="threshold":
                basis=nodes.modules if node["label_basis"]=="module" else nodes.values
                labels &= basis>node["label_threshold"]
            if labels.any():
                renderer = self.plotter.renderer
                family,pixels = label_font(node,self.plotter.render_window.GetDPI(),self.plotter.window_size[1])
                label_cloud = pv.PolyData(node_positions[labels].copy())
                names=[nodes.labels[i] for i in np.flatnonzero(labels)]
                # A list of labels makes PyVista copy the points, disconnecting
                # camera-follow and viewport corrections from the drawn actor.
                from vtkmodules.vtkCommonCore import vtkStringArray
                label_array=vtkStringArray(); label_array.SetName("labels")
                for name in names: label_array.InsertNextValue(name)
                label_cloud.GetPointData().AddArray(label_array)
                font_info = self.text_font(names, bold=node['label_font_weight']=='bold')
                extra_font = {'font_file': font_info['path']} if font_info else {}
                actor = self.plotter.add_point_labels(label_cloud,"labels",
                    font_size=max(1,int(np.floor(pixels*72/self.plotter.render_window.GetDPI()+.5))),font_family=family,bold=node["label_font_weight"]=="bold",
                    italic=node["label_font_angle"]=="italic",text_color=node["label_color"],show_points=False,
                    always_visible=node["label_in_front"],shape=None,reset_camera=False,justification_horizontal="center",**extra_font)
                self.label_records.append((renderer,label_cloud,node_positions[labels].copy(),radii[labels].copy(),node,names,actor))
        valid=keep[prepared.pairs].all(axis=1)
        pairs,values=prepared.pairs[valid],prepared.edge_values[valid]
        if not len(pairs): return
        a,b=node_positions[pairs[:,0]],node_positions[pairs[:,1]]
        delta=b-a; lengths=np.linalg.norm(delta,axis=1)
        if (lengths<=np.finfo(float).eps).any(): raise ValueError("Edges between coincident nodes cannot be rendered.")
        unit=delta/lengths[:,None]; radius=edge_radii(values,edge)
        trim_a,trim_b=radii[pairs[:,0]].copy(),radii[pairs[:,1]].copy()
        overlap=trim_a+trim_b>=.9*lengths; trim_a[overlap]=.05*lengths[overlap]; trim_b[overlap]=.05*lengths[overlap]
        arrow=np.zeros(len(pairs))
        if edge["directed"]:
            requested=edge["arrow_length_scale"]*np.minimum(.2*lengths,np.maximum(1.5,5*radius))
            arrow=np.minimum(requested,np.minimum(.35*lengths,np.maximum(0,.9*lengths-trim_a-trim_b)))
        start=a+trim_a[:,None]*unit; end=b-(trim_b+arrow)[:,None]*unit
        mode=edge["color_mode"]
        if mode=="uniform": colors=np.tile(edge["color"],(len(pairs),1))
        elif mode=="node-module":
            if len(np.unique(nodes.modules))>20: raise ValueError("Node Module edge coloring supports up to 20 modules.")
            module=module_colors(nodes.modules,node["colormap"]); colors=np.tile(edge["inter_module_color"],(len(pairs),1))
            same=nodes.modules[pairs[:,0]]==nodes.modules[pairs[:,1]]; colors[same]=module[pairs[same,0]]
        elif mode=="mapped": colors=mapped_colors(np.abs(values) if edge["mapped_value_mode"]=="absolute" else values,edge["colormap"],edge["color_limits"])
        elif mode=="threshold": colors=np.where(((np.abs(values) if edge["threshold_value_mode"]=="absolute" else values)>edge["color_threshold"])[:,None],edge["color_high"],edge["color_low"])
        elif mode=="length": colors=np.where((lengths>=edge["length_threshold"])[:,None],edge["color_high"],edge["color_low"])
        elif mode=="custom": colors=custom_edge_colors(edge["custom_color"],edge["colormap"],nodes.positions,pairs)
        else: raise ValueError(f"Edge color mode '{mode}' is not yet ported.")
        if edge["opacity_mode"]=="uniform": alpha=np.full(len(values),edge["opacity"])
        elif edge["opacity_mode"]=="mapped":
            low,high=edge["opacity_range"]
            if not 0<=low<=high<=1: raise ValueError("Edge opacity range must be ordered within [0,1].")
            weights=np.abs(values) if edge["opacity_value_mode"]=="absolute" else values
            span=np.ptp(weights); alpha=np.full(len(values),high) if span==0 else low+(weights-weights.min())/span*(high-low)
        else: raise ValueError("Unsupported edge opacity mode.")
        points=np.stack([start,end],axis=1).reshape(-1,3)
        lines=np.column_stack([np.full(len(pairs),2),np.arange(len(pairs))*2,np.arange(len(pairs))*2+1]).ravel()
        rgba=(np.column_stack([colors,alpha])*255).astype(np.uint8)
        mesh=pv.PolyData(points,lines=lines); mesh["radius"]=np.repeat(radius,2); mesh["rgb"]=np.repeat(rgba,2,axis=0)
        tubes=mesh.tube(scalars="radius",absolute=True,n_sides=self.detail_policy.edge_sides)
        self.add_geometry(tubes,scalars="rgb",rgb=True,smooth_shading=True)
        if edge["directed"]:
            cones=[]
            for i in np.flatnonzero(arrow>0):
                cone=pv.Cone(center=end[i]+unit[i]*arrow[i]/2,direction=unit[i],height=arrow[i],
                             radius=max(.5,2.5*radius[i])*edge["arrow_width_scale"],resolution=8)
                cone["rgb"]=np.tile(rgba[i],(cone.n_points,1)); cones.append(cone)
            if cones: self.add_geometry(pv.merge(cones),scalars="rgb",rgb=True,smooth_shading=True)

    def figure_annotations(self, prepared, positions):
        """One set of bars for the whole montage; reserve space outside brain axes."""
        from vtkmodules.vtkCommonCore import vtkLookupTable
        from vtkmodules.vtkRenderingAnnotation import vtkScalarBarActor
        from vtkmodules.vtkRenderingCore import vtkTextActor
        settings = prepared.settings
        image, surface, volume = settings["image"], settings["surface"], settings["volume"]
        entries = []
        mapped = prepared.mapped
        if (prepared.surface and mapped is not None and mapped.ndim == 1 and surface["show_colorbar"]
                and (volume["display"] or surface["color_mode"] == "scalar")):
            if volume["display"]:
                cmap, limits = self.volume_colors(mapped, volume, surface["color"])
                table = np.asarray(cmap.colors)
            else:
                cmap,limits=surface_map_palette(mapped,surface); table=np.asarray(cmap.colors)
            entries.append(("Surface", table, limits, None))
        if image["show_colorbar"] and prepared.nodes is not None:
            node, edge = settings["node"], settings["edge"]
            if node["color_mode"] == "mapped":
                values = prepared.nodes.modules
                limits = node["color_limits"] or [float(values.min()), float(values.max())]
                entries.append(("Node", palette(node["colormap"]), limits, None))
            elif node["color_mode"] in ("modular", "custom", "module", "modules"):
                labels = np.unique(prepared.nodes.modules)
                entries.append(("Module", module_colors(labels, node["colormap"]), [0, max(1, len(labels)-1)], labels))
            elif node["color_mode"] == "threshold":
                entries.append(("Node",[node["color_low"],node["color_high"]],[0,1],
                                [f"Module <= {node['color_threshold']:g}",f"Module > {node['color_threshold']:g}"]))
            if edge["color_mode"] == "mapped" and len(prepared.edge_values):
                values = prepared.edge_values
                if edge["mapped_value_mode"] == "absolute": values = np.abs(values)
                limits = edge["color_limits"] or [float(values.min()), float(values.max())]
                entries.append(("Edge", palette(edge["colormap"]), limits, None))
            elif edge["color_mode"] in ("threshold","length") and len(prepared.edge_values):
                threshold = edge["color_threshold"] if edge["color_mode"]=="threshold" else edge["length_threshold"]
                basis = "Length" if edge["color_mode"]=="length" else "Absolute value" if edge["threshold_value_mode"]=="absolute" else "Value"
                symbols = ("<",">=") if edge["color_mode"]=="length" else ("<=",">")
                entries.append(("Edge",[edge["color_low"],edge["color_high"]],[0,1],
                                [f"{basis} {symbols[0]} {threshold:g}",f"{basis} {symbols[1]} {threshold:g}"]))
            elif edge["color_mode"]=="node-module" and len(prepared.edge_values):
                labels = np.unique(prepared.nodes.modules)
                colors = module_colors(labels,node["colormap"])
                entries.append(("Edge",np.vstack((colors,edge["inter_module_color"])),[0,len(labels)],
                                [f"Module {value:g}" for value in labels]+["Between modules"]))
            elif edge["color_mode"]=="custom" and len(prepared.edge_values):
                categories = np.asarray(edge["custom_color"]["indices"])
                colors = palette(edge["colormap"],max(2,len(categories))) if isinstance(edge["colormap"],str) else np.asarray(edge["colormap"])
                entries.append(("Edge",colors[:len(categories)],[0,max(1,len(categories)-1)],categories))
        if settings["roi"]["show_legend"] and prepared.rois:
            entries.append(("ROI",[color for _,_,color in prepared.rois],[0,max(1,len(prepared.rois)-1)],
                            [f"ROI {label}" for label,_,_ in prepared.rois]))
        foreground = [0, 0, 0] if np.mean(settings["global"]["background_color"]) > .5 else [1, 1, 1]
        location = image["colorbar_location"]
        if entries and all(name=="Surface" for name,_,_,_ in entries): location="southoutside"
        x0, y0, scale_x, scale_y = 0., 0., 1., 1.
        surface_only=bool(entries) and all(name=="Surface" for name,_,_,_ in entries)
        if entries and not surface_only:
            reserve = .23 if any(labels is not None for _,_,_,labels in entries) else .08
            if location == "eastoutside": scale_x = 1-reserve
            elif location == "westoutside": x0, scale_x = reserve, 1-reserve
            elif location == "southoutside": y0, scale_y = (.25,.75) if reserve>.15 else (.08,.92)
            else: scale_y = .75 if reserve>.15 else .92
            if location == "northoutside" and image["title"]:
                # The heading and scalar strips need separate vertical bands.
                scale_y = min(scale_y, .84)
        horizontal_entries = [entry for entry in entries if entry[0] != "Surface"]
        preset = settings["layout"]["preset"]
        unsplit_montage = preset != 1 and prepared.split is None
        if (preset in (1,4) or unsplit_montage) and any(name == "Surface" for name,_,_,_ in entries):
            # Reserve according to the actual layout. An unsplittable surface
            # uses six full-brain views even when the requested preset is 2/5.
            bottom = .18 if preset == 1 else .08
            # Preserve any existing top annotation margin while adding the
            # bottom band within the remaining brain area.
            y0, scale_y = y0 + bottom*scale_y, (1-bottom)*scale_y
        for i, (name, table, limits, labels) in enumerate(entries):
            if labels is not None:
                shown = min(20,len(labels)); extra = int(len(labels)>shown)
                names = [f"{name}: "+(f"{value:g}" if isinstance(value,(int,float,np.number)) else str(value)) for value in labels[:shown]]
                colors = [list(color) for color in table[:shown]]
                if extra: names.append(f"+{len(labels)-shown} more"); colors.append([.5,.5,.5])
                if location in ("eastoutside","westoutside"):
                    height = .84/len(entries)
                    rectangle = (1-reserve+.015 if location=="eastoutside" else .01,.08+i*height,reserve-.025,height-.04)
                else:
                    width = .84/len(entries)
                    rectangle = (.08+i*width,.015 if location=="southoutside" else .765,width-.025,.22)
                self.draw_legend(names,colors,rectangle,foreground)
                continue
            lut = vtkLookupTable(); lut.SetNumberOfTableValues(len(table))
            lut.SetTableRange(limits[0], limits[1] if limits[1] > limits[0] else limits[0]+1)
            lut.Build()
            for k, rgb in enumerate(table): lut.SetTableValue(k, *rgb, 1.)
            if labels is not None:
                lut.SetIndexedLookup(True)
                for k, label in enumerate(labels): lut.SetAnnotation(float(k), f"{label:g}")
            bar = vtkScalarBarActor(); bar.SetLookupTable(lut)
            bar.SetTitle(image["colorbar_label"] or name); bar.SetNumberOfLabels(4)
            bar.SetUnconstrainedFontSize(True)
            for prop in (bar.GetTitleTextProperty(), bar.GetLabelTextProperty(), bar.GetAnnotationTextProperty()):
                prop.SetColor(*foreground); prop.SetFontSize(12); prop.SetBold(False); prop.SetItalic(False)
                self.annotation_text_props.append((prop,12))
            use_font(bar.GetTitleTextProperty(), self.text_font([bar.GetTitle()]))
            if name=="Surface":
                # Keep the surface strip independent of the Node/Edge location.
                # Place the dorsal bar below the central brain, alongside the
                # lower lateral views. Bring single/ventral bars close to the
                # brain viewport without entering it; unsplit six views keep
                # the strip lower and outside all full-brain viewports.
                if unsplit_montage:
                    y = .015
                elif preset in (1,4):
                    y = y0 + min(p[1] for p in positions)*scale_y - .012 - .10
                elif preset == 5:
                    central_bottom = y0 + positions[1][1]*scale_y
                    lateral_bottom = y0 + min(positions[i][1] for i in (3,4))*scale_y
                    y = min(central_bottom-.015, lateral_bottom+.035) - .10
                else:
                    y = {2:.025,3:.010}[preset]
                # Side legends shift/scale the brain area. Keep the independent
                # strip in that same area so endpoint text stays between brains.
                bar.SetOrientationToHorizontal(); bar.SetPosition(x0+.38*scale_x,y)
                bar.SetWidth(.24*scale_x); bar.SetHeight(.10); bar.SetBarRatio(.18)
            elif location in ("eastoutside", "westoutside"):
                height = .84/len(entries)
                bar.SetOrientationToVertical(); bar.SetPosition(.865 if location == "eastoutside" else .015, .08+i*height)
                bar.SetWidth(.045); bar.SetHeight(min(.30,height-.04)); bar.SetBarRatio(.4)
            else:
                # Surface has its own strip, so it must not consume a slot.
                # Leave room between numeric endpoint labels, not just bars.
                slot = sum(entry[0] != "Surface" for entry in entries[:i])
                width = .84/len(horizontal_entries); length=min(.30,width-.10)
                y=.025 if location=="southoutside" else (.86 if image["title"] else .93)
                bar.SetOrientationToHorizontal(); bar.SetPosition(.08+slot*width+(width-length)/2,y)
                bar.SetWidth(length); bar.SetHeight(.05); bar.SetBarRatio(.36)
            if bar.GetOrientation() == 0:
                bar.SetTextPositionToPrecedeScalarBar()
            self.annotations.AddViewProp(bar); self.colorbars.append(bar)
        if image["title"]:
            title = vtkTextActor(); title.SetInput(image["title"])
            title.GetPositionCoordinate().SetCoordinateSystemToNormalizedViewport()
            title.SetPosition(.5, .985)
            prop = title.GetTextProperty(); prop.SetColor(*foreground); prop.SetFontSize(18)
            prop.SetJustificationToCentered(); prop.SetVerticalJustificationToTop(); prop.SetBold(True)
            use_font(prop, self.text_font([image['title']], bold=True))
            self.title_actor = title
            self.annotation_text_props.append((prop,18))
            self.annotations.AddViewProp(title)
            scale_y *= .93
        return [(x0+x*scale_x,y0+y*scale_y,w*scale_x,h*scale_y) for x,y,w,h in positions]

    def draw_legend(self, names, colors, rectangle, foreground):
        """Fixed-size contrast text with separately colored swatches, no black box."""
        from vtkmodules.vtkRenderingCore import vtkTextActor, vtkActor2D, vtkPolyDataMapper2D, vtkCoordinate
        x,y,w,h=rectangle; width,height=self.plotter.window_size
        rows=max(1,min(len(names),int(h*height/18))); columns=int(np.ceil(len(names)/rows))
        slot=w/columns
        pixels=max(8,min(12,int(slot*width/max(1,max(len(name) for name in names))/.65)))
        actors=[]
        for k,(name,color) in enumerate(zip(names,colors)):
            column,row=divmod(k,rows)
            left=x+column*slot; center=y+h-(row+.5)*h/rows
            swatch=pv.PolyData(np.array([[left,center-.005,0],[left+.01,center-.005,0],
                                        [left+.01,center+.005,0],[left,center+.005,0]]),np.array([4,0,1,2,3]))
            coordinate=vtkCoordinate(); coordinate.SetCoordinateSystemToNormalizedViewport()
            mapper=vtkPolyDataMapper2D(); mapper.SetInputData(swatch); mapper.SetTransformCoordinate(coordinate)
            symbol=vtkActor2D(); symbol.SetMapper(mapper); symbol.GetProperty().SetColor(*color)
            text=vtkTextActor(); text.SetInput(name); text.SetTextScaleModeToNone()
            text.GetPositionCoordinate().SetCoordinateSystemToNormalizedViewport(); text.SetPosition(left+.014,center)
            prop=text.GetTextProperty(); prop.SetColor(*foreground); prop.SetFontSize(pixels)
            prop.SetVerticalJustificationToCentered(); prop.SetBold(False); prop.SetItalic(False)
            self.annotation_text_props.append((prop,pixels))
            for actor in (symbol,text): self.annotations.AddViewProp(actor); actors.append(actor)
        self.legends.append({"labels":names,"colors":colors,"actors":actors,"rectangle":rectangle})

    def update_annotation_fonts(self, dpi, *, size=None, strict_title=True):
        # Global annotations adapt to the available pixels, not to the metadata DPI.
        warning = ''
        if self.title_actor is not None:
            try:
                fit_title(self.title_actor, *(size or self.plotter.window_size), dpi,
                          measure_dpi=self.plotter.render_window.GetDPI())
            except TitleFitError:
                if strict_title: raise
                warning = ('Title temporarily hidden because this canvas is too small. '
                           'Enlarge the canvas to restore it. Exports require the complete title to fit.')
            self.title_actor.SetVisibility(not warning)
        self.annotation_warning = warning
        for prop,pixels in self.annotation_text_props:
            if self.title_actor is None or prop is not self.title_actor.GetTextProperty():
                prop.SetFontSize(max(1,int(np.floor(pixels*72/dpi+.5))))

    def reset(self):
        width,height=self.plotter.window_size
        pixel_scale=self.pixel_scale(width,height)
        for renderer,state,(_,_,_,h) in zip(self.plotter.renderers,self.initial_cameras,self.viewports):
            camera=renderer.camera; camera.position,camera.focal_point,camera.up=state[:3]
            camera.parallel_projection=state[4]; camera.view_angle=state[5]
            camera.parallel_scale=height*h/(2*pixel_scale)
            renderer.ResetCameraClippingRange()
        self.fit_size=(width,height)
        self.plotter.render()

    def dispose(self):
        for camera,tag in self.label_observers: camera.RemoveObserver(tag)
        self.label_observers, self.label_records = [], []
        self.title_actor = None
        self.text_fonts = {}

    def inspect_vertex(self, x, y):
        if self.prepared is None or self.prepared.surface is None: return None
        from vtkmodules.vtkRenderingCore import vtkCellPicker
        native=self.plotter.iren.interactor
        renderer=native.FindPokedRenderer(int(x),int(y))
        renderers=list(self.plotter.renderers)
        if renderer not in renderers: return None
        actors=self.pick_actors[renderers.index(renderer)]
        if actors is None: return None
        picker=vtkCellPicker(); picker.SetTolerance(.005); picker.PickFromListOn()
        for actor,_ in actors: picker.AddPickList(actor)
        if not picker.Pick(float(x),float(y),0,renderer): return None
        point=np.asarray(picker.GetPickPosition())
        transform = next((transform for actor,transform in actors if actor == picker.GetActor()),None)
        if transform: point = transform.inverse(point)
        original=self.prepared.surface.points
        index=int(np.argmin(np.sum((original-point)**2,axis=1)))
        return {"vertex":index+1,"xyz":original[index].tolist(),"method":"cell-hit nearest original vertex"}

    def export(self, filename, width=2000, height=1500, dpi=300, transparent=False, *, overwrite=False, paths=None, settings=None, provenance_context=None):
        from .figure_export import save_figure
        from .provenance import build_provenance, sidecar_path
        if self.prepared is None or self.exporting: raise ValueError("Render a scene before exporting; an export is already active if busy.")
        if any(isinstance(v,bool) or not np.isscalar(v) or not np.isreal(v) or not np.isfinite(v) or int(v)!=v for v in (width,height,dpi)):
            raise ValueError("Export dimensions/DPI must be finite integers.")
        width,height,dpi=int(width),int(height),int(dpi)
        if not 16<=width<=16000 or not 16<=height<=16000 or width*height>64000000 or not 1<=dpi<=2400:
            raise ValueError("Export dimensions/DPI exceed supported limits.")
        suffix=Path(filename).suffix.lower()
        if suffix not in (".png",".jpg",".jpeg",".tif",".tiff",".bmp",".pdf",".svg"):
            raise ValueError("Choose PNG, TIFF, JPEG, BMP, PDF or SVG.")
        if not isinstance(transparent,bool) or not isinstance(overwrite,bool): raise ValueError("Export flags must be boolean.")
        if transparent and suffix not in (".png",".tif",".tiff",".pdf",".svg"): raise ValueError("This format does not support transparent export.")
        target=Path(filename).resolve()
        paths=self.prepared.input_paths if paths is None else paths
        if not paths: raise ValueError("Input paths are required for verified image provenance.")
        if target.exists() and not overwrite: raise FileExistsError("Output already exists. Confirm replacement or choose another filename.")
        if sidecar_path(target).exists() and not overwrite: raise FileExistsError("Provenance file already exists. Confirm replacement or choose another filename.")
        def check_inputs():
            if paths is not None:
                if content_hashes(paths)!=self.prepared.input_hashes: raise ValueError("Source files changed. Reload and render before export.")
            if settings is not None and signature(self.prepared.input_hashes,settings)!=signature(self.prepared.input_hashes,self.prepared.settings):
                raise ValueError("Configuration changed. Apply and render before export.")
        if paths is not None:
            from .io import gifti_dependencies
            protected=[]
            for source in paths.values():
                source=Path(source).resolve(); protected.append(source)
                if source.suffix.lower()==".gii": protected.extend(gifti_dependencies(source))
                if source.suffix.lower() in (".hdr",".img"): protected.append(source.with_suffix(".img" if source.suffix.lower()==".hdr" else ".hdr"))
            if any(p in [source.resolve() for source in protected] for p in (target,sidecar_path(target).resolve())):
                raise ValueError("Do not overwrite an input or its external data.")
        check_inputs()
        # Validate against the requested output, never the current screen size.
        validate_title(self.prepared.settings['image']['title'],width,height,dpi)
        old_size=self.plotter.window_size
        old_fit=self.fit_size
        states=[(r.camera.position,r.camera.focal_point,r.camera.up,r.camera.parallel_scale,r.camera.view_angle) for r in self.plotter.renderers]
        background_alpha=self.background.GetBackgroundAlpha()
        old_dpi=self.plotter.render_window.GetDPI()
        # Preserve the actual screen typography. Recomputing from pixel targets
        # at a high screen DPI can halve the original sizes on any platform.
        old_annotation_fonts=[(prop,prop.GetFontSize()) for prop,_ in self.annotation_text_props]
        old_title_visible=self.title_actor.GetVisibility() if self.title_actor is not None else None
        old_warning=self.annotation_warning
        self.exporting=True
        try:
            self.plotter.render_window.SetDPI(int(dpi))
            self.background.SetBackgroundAlpha(0 if transparent else 1)
            self.plotter.window_size=(width,height)
            self.resize_fit(width,height,strict_title=True)
            self.update_label_records()
            _prepare_raster_capture(self.plotter)
            image=self.plotter.screenshot(return_img=True,window_size=(width,height),transparent_background=transparent)
            return save_figure(self.plotter,image,target,width,height,dpi,transparent,overwrite=overwrite,before_publish=check_inputs,
                               font_text_as_path=bool(self.text_fonts),
                               provenance=lambda export:build_provenance(self,paths,export,provenance_context))
        finally:
            self.plotter.window_size=old_size
            for renderer,state in zip(self.plotter.renderers,states):
                camera=renderer.camera; camera.position,camera.focal_point,camera.up,camera.parallel_scale,camera.view_angle=state
                renderer.ResetCameraClippingRange()
            self.fit_size=old_fit; self.background.SetBackgroundAlpha(background_alpha)
            self.plotter.render_window.SetDPI(old_dpi); self.update_label_records()
            for prop,size in old_annotation_fonts: prop.SetFontSize(size)
            if self.title_actor is not None: self.title_actor.SetVisibility(old_title_visible)
            self.annotation_warning=old_warning
            self.exporting=False
            self.plotter.render()

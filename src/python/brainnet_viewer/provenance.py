"""Image provenance without machine-specific absolute source paths."""
from datetime import datetime, timezone
from copy import deepcopy
from dataclasses import asdict
from importlib.metadata import version, PackageNotFoundError
import platform
from pathlib import Path
from pathlib import PureWindowsPath
from . import __version__
from .io import sha256, gifti_dependencies
from .session import signature, digest


def sidecar_path(filename):
    return Path(str(filename)+'.provenance.json')


def build_provenance(renderer, paths, export, context=None):
    settings=deepcopy(renderer.prepared.settings)
    redacted=[]
    for section,key in [('surface','vertex_colors_source'),('surface','boundary_mask_source')]:
        if settings[section][key]:
            settings[section][key]=PureWindowsPath(settings[section][key]).name
            redacted.append(section+'.'+key)
    if settings['edge']['custom_color']['source']:
        settings['edge']['custom_color']['source']=PureWindowsPath(settings['edge']['custom_color']['source']).name
        redacted.append('edge.custom_color.source')
    assets={}
    for role,path in paths.items():
        path=Path(path).resolve()
        dependencies=gifti_dependencies(path) if path.suffix.lower()=='.gii' else []
        if path.suffix.lower() in ('.hdr','.img'):
            dependencies.append(path.with_suffix('.img' if path.suffix.lower()=='.hdr' else '.hdr'))
        assets[role]={'filename':path.name,'sha256':sha256(path),
                      'content_sha256':renderer.prepared.input_hashes[role],
                      'dependencies':[{'relative_path':p.relative_to(path.parent).as_posix(),'sha256':sha256(p)} for p in dependencies]}
    versions={}
    for name in ('numpy','scipy','nibabel','pyvista','vtk','Pillow'):
        try: versions[name]=version(name)
        except PackageNotFoundError: versions[name]='unavailable'
    return {'schema_version':'1.0','kind':'brainnet-image-provenance',
            'created_utc':datetime.now(timezone.utc).isoformat(),
            'software':{'name':'BrainNet Viewer','version':__version__,'python':platform.python_version(),
                        'platform':platform.system(),'libraries':versions},
            'inputs':assets,'render_signature':signature(renderer.prepared.input_hashes,renderer.prepared.settings),
            'settings':settings,'settings_sha256':digest(settings),'camera':renderer.capture_camera(),
            'render':{'detail_policy':asdict(renderer.detail_policy),'material':renderer.appearance,
                      'surface_vertices':len(renderer.prepared.surface.points) if renderer.prepared.surface else 0,
                      'surface_faces':len(renderer.prepared.surface.faces) if renderer.prepared.surface else 0,
                      'nodes':len(renderer.prepared.nodes.positions) if renderer.prepared.nodes else 0,
                      'selected_edges':len(renderer.prepared.pairs),
                      'roi_labels':[int(roi[0]) for roi in renderer.prepared.rois]},
            'privacy':{'absolute_input_paths_included':False,'source_annotations_reduced_to_filenames':redacted},
            'export':export,'context':context or {},
            'limitations':['Provenance is a reproducibility record, not a digital signature or scientific validation.',
                          'Pixel-identical results across operating systems or GPU drivers are not guaranteed.']}

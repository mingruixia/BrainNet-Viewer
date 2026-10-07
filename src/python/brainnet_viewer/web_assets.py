"""Bounded browser uploads and portable Scene bundles in owned workspaces."""
import io
import shutil
import uuid
from tempfile import TemporaryDirectory
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from .io import resolve_asset, gifti_dependencies
from .scene import read_scene, portable_scene

FILE_LIMIT=32*1024*1024
SESSION_LIMIT=128*1024*1024
BUNDLE_LIMIT=64*1024*1024
SURFACES={'.nv','.gii','.pial','.white','.inflated','.sphere','.surf','.orig','.mesh','.byu','.g','.obj','.mz3'}


def file_role(name, requested=None):
    lower=name.lower(); suffix=Path(lower).suffix
    if requested and requested not in ('surface','node','edge','surface_map','volume'):
        raise ValueError('Unknown upload role.')
    role='volume' if lower.endswith(('.nii','.nii.gz','.hdr','.img')) else 'node' if suffix=='.node' else 'edge' if suffix=='.edge' else 'surface_map' if suffix=='.txt' else 'surface' if suffix in SURFACES else None
    if suffix in ('.bin','.dat'): return None
    if requested:
        if suffix=='.gii' and requested=='surface_map': return requested
        if role!=requested: raise ValueError('File type does not match the selected input role.')
    if role is None: raise ValueError('Unsupported upload file type.')
    return role


def dependency_check(path, root):
    dependencies=gifti_dependencies(path) if path.suffix.lower()=='.gii' else []
    if path.suffix.lower() in ('.hdr','.img'):
        dependencies.append(path.with_suffix('.img' if path.suffix.lower()=='.hdr' else '.hdr'))
    for dep in dependencies:
        if not dep.resolve().is_relative_to(root.resolve()) or not dep.is_file():
            raise ValueError('Upload the paired/external data together with its header.')


def quota(root, extra):
    if sum(p.stat().st_size for p in root.rglob('*') if p.is_file())+extra>SESSION_LIMIT:
        raise ValueError('Session uploads exceed 128 MiB. Start a new session or use smaller data.')


def upload_files(workspace, files, requested=None):
    """Files are (basename, bytes) pairs. Catalog changes commit as one batch."""
    if not files or len(files)>16: raise ValueError('Choose 1–16 files per upload.')
    names=set(); total=0
    for name,data in files:
        if not isinstance(name,str) or not name or '/' in name or '\\' in name or ':' in name or name in ('.','..'):
            raise ValueError('Upload filenames must be basenames.')
        if name.casefold() in names: raise ValueError('Duplicate upload filename.')
        names.add(name.casefold())
        if not isinstance(data,bytes) or not data or len(data)>FILE_LIMIT:
            raise ValueError('Each upload must be nonempty and at most 32 MiB.')
        file_role(name,requested); total+=len(data)
    if total>BUNDLE_LIMIT: raise ValueError('Upload batch exceeds 64 MiB.')
    quota(workspace.assets,total)
    folder=workspace.assets/uuid.uuid4().hex; folder.mkdir()
    try:
        for name,data in files: (folder/name).write_bytes(data)
        chosen={}
        for name,_ in files:
            path=folder/name; role=file_role(name,requested)
            if role is None: continue
            if path.suffix.lower()=='.img' and path.with_suffix('.hdr').is_file(): continue
            if role in chosen: raise ValueError('Choose one primary file per input type; use Merge for multiple surfaces.')
            dependency_check(path,folder); chosen[role]=path
        if not chosen: raise ValueError('Select a primary data file with its dependencies.')
        selections={}
        for role,path in chosen.items():
            key='Uploaded/'+path.relative_to(workspace.assets).as_posix()
            workspace.catalog[role][key]=path; selections[role]=key
        return selections
    except Exception:
        shutil.rmtree(folder); raise


def save_bundle(workspace, settings, session=None):
    with TemporaryDirectory(prefix='scene-',dir=workspace.scratch) as temp:
        folder=Path(temp)
        portable_scene(workspace.paths,settings,folder/'BrainNet.scene.json',session=session)
        files=[p for p in folder.rglob('*') if p.is_file()]
        if sum(p.stat().st_size for p in files)>SESSION_LIMIT:
            raise ValueError('Scene bundle exceeds 128 MiB.')
        stream=io.BytesIO()
        with ZipFile(stream,'w',ZIP_DEFLATED) as archive:
            for path in files: archive.write(path,path.relative_to(folder).as_posix())
        result=stream.getvalue()
        if len(result)>BUNDLE_LIMIT: raise ValueError('Scene ZIP exceeds 64 MiB.')
        return result


def open_bundle(workspace,name,data):
    if not isinstance(data,bytes) or not data or len(data)>BUNDLE_LIMIT:
        raise ValueError('Scene input must be nonempty and at most 64 MiB.')
    folder=workspace.assets/uuid.uuid4().hex; folder.mkdir()
    try:
        if Path(name).suffix.lower()=='.zip':
            with ZipFile(io.BytesIO(data)) as archive:
                entries=[entry for entry in archive.infolist() if not entry.is_dir()]
                if not entries or len(entries)>64: raise ValueError('Scene ZIP requires 1–64 files.')
                if any(e.file_size>FILE_LIMIT or (e.external_attr>>16)&0o170000==0o120000 for e in entries):
                    raise ValueError('Scene ZIP contains an oversized file or symbolic link.')
                quota(workspace.assets,sum(e.file_size for e in entries))
                seen=set()
                for entry in entries:
                    target=resolve_asset(folder,entry.filename)
                    if entry.filename.casefold() in seen: raise ValueError('Duplicate Scene ZIP path.')
                    seen.add(entry.filename.casefold())
                    if target.suffix.lower()!='.json': file_role(target.name)
                for entry in entries:
                    target=resolve_asset(folder,entry.filename); target.parent.mkdir(parents=True,exist_ok=True)
                    target.write_bytes(archive.read(entry))
            scenes=list(folder.rglob('*.json'))
            if len(scenes)!=1: raise ValueError('Scene ZIP must contain exactly one Scene JSON.')
            scene=read_scene(scenes[0],scenes[0].parent,resolve=False)
            paths={}
            for role,ref in scene.document['inputs'].items():
                path=resolve_asset(scene.data_root,ref['relative_path'])
                if not path.is_file(): raise ValueError(f'Missing {role} in Scene ZIP.')
                file_role(path.name,role); dependency_check(path,folder); paths[role]=path
            scene.resolve()
        elif Path(name).suffix.lower()=='.json':
            if len(data)>2*1024*1024: raise ValueError('Scene JSON exceeds 2 MiB.')
            quota(workspace.assets,len(data)); scene_path=folder/'Scene.json'; scene_path.write_bytes(data)
            scene=read_scene(scene_path,workspace.root,resolve=False)
            for role,ref in scene.document['inputs'].items():
                key=ref['relative_path']
                if key not in workspace.catalog[role] or not workspace.catalog[role][key].is_relative_to(workspace.root):
                    raise ValueError('Scene JSON requires external assets. Open a ZIP containing the JSON and its asset folder.')
            scene.resolve(); paths=scene.paths
        else: raise ValueError('Open a Scene JSON or ZIP.')
        if 'surface' not in paths: raise ValueError('Scene requires a surface.')
        settings=scene.settings; chosen={}
        for role,path in paths.items():
            key=next((key for key,value in workspace.catalog[role].items() if value==path),None)
            if key is None: key='Uploaded/'+path.relative_to(workspace.assets).as_posix()
            chosen[role]=key
        # Commit after schema, paths, hashes, dependencies and settings pass.
        for role,key in chosen.items(): workspace.catalog[role][key]=paths[role]
        workspace.paths=paths; workspace.settings=settings
        workspace.pending_session=scene.document.get('metadata',{}).get('python_session_state')
        return chosen
    except Exception:
        shutil.rmtree(folder); raise

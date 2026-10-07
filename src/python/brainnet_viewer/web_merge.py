"""Ordered Web merge inputs and exact NV output using the desktop geometry core."""
from pathlib import Path
from tempfile import TemporaryDirectory
from datetime import datetime,timezone
import io
import json
import shutil
import uuid
import numpy as np
from .io import read_surface
from .advanced_tools import source_records,verify_inputs
from .surface_geometry import merge_surfaces
from .web_assets import FILE_LIMIT,BUNDLE_LIMIT,quota,file_role,dependency_check


class WebMerge:
    output_name='merged.nv'
    kind='merge'
    operation='concatenate vertices in input order and offset face indices; original coordinates preserved'
    def __init__(self,workspace):
        self.workspace=workspace
        self.entries=[]

    def _review(self,key):
        path=self.workspace.catalog['surface'].get(key)
        if path is None or not path.is_file() or not any(path.resolve().is_relative_to(root) for root in (self.workspace.root,self.workspace.assets)):
            raise ValueError('Choose a surface from the library or upload it.')
        dependency_check(path,self.workspace.root if path.is_relative_to(self.workspace.root) else self.workspace.assets)
        records=source_records(path)
        surface=read_surface(path)
        verify_inputs(records)
        return key,surface,records

    def add(self,keys):
        if not keys or len(self.entries)+len(keys)>16: raise ValueError('Merge accepts 1–16 input surfaces.')
        additions=[self._review(key) for key in keys]
        self.entries.extend(additions)

    def upload(self,files):
        if not files or len(files)>16: raise ValueError('Choose 1–16 upload files.')
        names=set(); total=0
        for name,data in files:
            if not isinstance(name,str) or not name or any(c in name for c in '/\\:') or name in ('.','..'):
                raise ValueError('Upload filenames must be basenames.')
            if name.casefold() in names: raise ValueError('Duplicate upload filename.')
            names.add(name.casefold())
            if not isinstance(data,bytes) or not data or len(data)>FILE_LIMIT:
                raise ValueError('Each upload must be nonempty and at most 32 MiB.')
            if file_role(name) not in ('surface',None): raise ValueError('Upload surfaces and their external binary arrays.')
            total+=len(data)
        if total>BUNDLE_LIMIT: raise ValueError('Upload batch exceeds 64 MiB.')
        quota(self.workspace.assets,total)
        folder=self.workspace.assets/uuid.uuid4().hex; folder.mkdir()
        keys=[]
        try:
            for name,data in files: (folder/name).write_bytes(data)
            for name,_ in files:
                if file_role(name) is None: continue
                path=folder/name; dependency_check(path,folder)
                key='Uploaded/'+path.relative_to(self.workspace.assets).as_posix()
                self.workspace.catalog['surface'][key]=path; keys.append(key)
            if not keys: raise ValueError('Choose a primary surface with any required external arrays.')
            self.add(keys)
            return keys
        except Exception:
            for key in keys: self.workspace.catalog['surface'].pop(key,None)
            shutil.rmtree(folder); raise

    def edit(self,index,offset=None):
        if isinstance(index,bool) or not isinstance(index,(int,float)) or int(index)!=index or not 0<=index<len(self.entries):
            raise ValueError('Select an input surface.')
        index=int(index)
        if offset is None:
            self.entries.pop(index); return min(index,len(self.entries)-1)
        target=index+offset
        if not 0<=target<len(self.entries): return index
        self.entries[index],self.entries[target]=self.entries[target],self.entries[index]
        return target

    def summary(self):
        return [{'title':f'{surface.path.name} · {len(surface.points):,} vertices · {len(surface.faces):,} faces',
                 'value':index} for index,(_,surface,_) in enumerate(self.entries)]

    def output_surface(self):
        return merge_surfaces([surface for _,surface,_ in self.entries])

    def output_metadata(self):
        return {}

    def export(self,space='',units='',note=''):
        values=(space,units,note)
        if any(not isinstance(v,str) or len(v)>4096 for v in values): raise ValueError('Optional text must be at most 4096 characters per field.')
        records=[record for _,_,group in self.entries for record in group]
        verify_inputs(records)
        merged=self.output_surface()
        sources=[{'file':surface.path.name,'vertices':len(surface.points),'faces':len(surface.faces),
                  'files':[{'file':Path(record['path']).name,'sha256':record['sha256']} for record in group]}
                 for _,surface,group in self.entries]
        report={'kind':'brainnet-surface-'+self.kind,'schema_version':'1.0',
                'created_utc':datetime.now(timezone.utc).isoformat(),
                'operation':self.operation,
                'sources':sources,'vertices':len(merged.points),'faces':len(merged.faces),
                'space':space,'units':units,'note':note}
        report.update(self.output_metadata())
        stream=io.StringIO()
        stream.write('# BrainNet Viewer tool output; provenance JSON follows.\n')
        stream.write('# '+json.dumps(report,ensure_ascii=False,allow_nan=False,separators=(',',':'))+'\n')
        stream.write(f'{len(merged.points)}\n'); np.savetxt(stream,merged.points,fmt='%.17g')
        stream.write(f'{len(merged.faces)}\n'); np.savetxt(stream,merged.faces+1,fmt='%d')
        payload=stream.getvalue().encode('utf-8')
        if len(payload)>48*1024*1024: raise ValueError('NV output exceeds the 48 MiB download limit.')
        with TemporaryDirectory(prefix='merge-check-',dir=self.workspace.scratch) as folder:
            path=Path(folder)/self.output_name; path.write_bytes(payload)
            checked=read_surface(path)
            if not (np.array_equal(checked.points,merged.points) and np.array_equal(checked.faces,merged.faces)):
                raise ValueError('Exact NV read-back validation failed.')
        verify_inputs(records)
        return payload

    def use(self,payload):
        quota(self.workspace.assets,len(payload))
        folder=self.workspace.assets/uuid.uuid4().hex; folder.mkdir()
        path=folder/self.output_name
        try: path.write_bytes(payload)
        except Exception: shutil.rmtree(folder); raise
        key='Generated/'+path.relative_to(self.workspace.assets).as_posix()
        self.workspace.catalog['surface'][key]=path
        return key


class WebConvert(WebMerge):
    output_name='converted.nv'
    kind='convert'
    operation='convert to NV; original coordinates, vertex order and face connectivity preserved'

    def add(self,keys):
        if len(self.entries)+len(keys)!=1:
            raise ValueError('Conversion accepts one surface at a time. Remove the current input to choose another.')
        super().add(keys)

    def output_surface(self):
        if len(self.entries)!=1: raise ValueError('Add one surface to convert.')
        return self.entries[0][1]


class WebSubdivide(WebConvert):
    output_name='subdivided.nv'
    kind='subdivision'
    operation='linear midpoint triangle subdivision; original vertices retained; no smoothing or attribute transfer'
    max_vertices=500_000
    max_faces=1_000_000

    def __init__(self,workspace):
        super().__init__(workspace)
        self.levels=1
        self._cache=None

    def output_surface(self):
        from .advanced_tools import subdivide_surface,positive_integer
        levels=positive_integer(self.levels,'Levels')
        if levels>3: raise ValueError('Choose 1 to 3 subdivision levels.')
        source=super().output_surface()
        verify_inputs(self.entries[0][2])
        signature=(id(source),levels)
        if self._cache is None or self._cache[0]!=signature:
            result,report=subdivide_surface(source,levels,self.max_vertices,self.max_faces)
            self._cache=(signature,result,report)
        return self._cache[1]

    def output_metadata(self):
        self.output_surface()
        return {'levels':self._cache[2]['levels'],'level_counts':self._cache[2]['level_counts']}

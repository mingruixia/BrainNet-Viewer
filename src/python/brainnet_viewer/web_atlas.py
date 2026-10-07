"""Bounded atlas-node preparation using the desktop reviewed writer."""
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import math
import re
import shutil
import uuid
from .advanced_tools import AtlasNodePlan,verify_inputs
from .web_assets import upload_files,dependency_check,quota


def parse_region_ids(text):
    """Expand inclusive ascending ranges without evaluating user expressions."""
    if not isinstance(text,str) or len(text)>4096:
        raise ValueError('Region IDs must be at most 4096 characters.')
    result=[]; seen=set()
    for token in text.replace(',',' ').split():
        match=re.fullmatch(r'([+-]?\d+)-([+-]?\d+)',token)
        if match:
            first,last=map(int,match.groups())
            if last<first: raise ValueError('Region ranges must be ascending, for example 1-90.')
            if len(result)+last-first+1>10000: raise ValueError('Select at most 10,000 region IDs.')
            values=range(first,last+1)
        else:
            try: value=float(token)
            except ValueError: raise ValueError('Use numeric IDs or inclusive ranges such as 1-90.') from None
            if not math.isfinite(value) or not value.is_integer():
                raise ValueError('Region IDs must be finite integers.')
            values=[int(value)]
        for value in values:
            if value==0 or abs(value)>2**53: raise ValueError('Region IDs must be nonzero integers within the supported range.')
            if value in seen: raise ValueError('Region IDs must be unique; overlapping ranges are not allowed.')
            if len(result)>=10000: raise ValueError('Select at most 10,000 region IDs.')
            seen.add(value); result.append(value)
    return result


class WebAtlasNodes:
    def __init__(self,workspace):
        self.workspace=workspace
        self.plan=None

    def review(self,key,regions='',module=0.,size=0.):
        self.plan=None
        path=self.workspace.catalog['volume'].get(key)
        if path is None or not path.is_file() or not any(path.resolve().is_relative_to(root) for root in (self.workspace.root,self.workspace.assets)):
            raise ValueError('Choose a label atlas from the library or upload it.')
        dependency_check(path,self.workspace.root if path.is_relative_to(self.workspace.root) else self.workspace.assets)
        import nibabel as nib
        image=nib.load(str(path),mmap=False)
        if math.prod(image.shape)>32_000_000: raise ValueError('Web atlas input exceeds 32 million voxels.')
        ids=parse_region_ids(regions)
        plan=AtlasNodePlan.review(path,ids or None,float(module),float(size))
        if len(plan.nodes.labels)>10000: raise ValueError('Web output exceeds 10,000 nodes; select fewer regions.')
        self.plan=plan
        return plan

    def upload(self,files,regions='',module=0.,size=0.):
        previous=self.plan
        before=dict(self.workspace.catalog['volume'])
        selected=upload_files(self.workspace,files,'volume')
        key=selected['volume']; path=self.workspace.catalog['volume'][key]
        try: self.review(key,regions,module,size)
        except Exception:
            self.plan=previous
            self.workspace.catalog['volume'].clear(); self.workspace.catalog['volume'].update(before)
            folder=path.parent.resolve()
            if folder.is_relative_to(self.workspace.assets) and folder!=self.workspace.assets:
                shutil.rmtree(folder)
            raise
        return key

    def export(self,space='',units='',confirmed=False):
        if self.plan is None: raise ValueError('Review a valid label atlas first.')
        if any(not isinstance(v,str) or len(v)>4096 for v in (space,units)):
            raise ValueError('Space and Units must be at most 4096 characters.')
        with TemporaryDirectory(prefix='atlas-check-',dir=self.workspace.scratch) as folder:
            path=Path(folder)/'atlas.node'
            self.plan.write(path,confirmed=confirmed,space=space,units=units)
            lines=path.read_text(encoding='utf-8').splitlines(keepends=True)
        report=json.loads(lines[1][2:])
        report['sources']=[{'file':Path(source['path']).name,'sha256':source['sha256']} for source in report['sources']]
        lines[1]='# '+json.dumps(report,ensure_ascii=False,allow_nan=False,separators=(',',':'))+'\n'
        payload=''.join(lines).encode('utf-8')
        if len(payload)>48*1024*1024: raise ValueError('Node download exceeds 48 MiB.')
        verify_inputs(self.plan.report['sources'])
        return payload

    def use(self,payload):
        quota(self.workspace.assets,len(payload))
        folder=self.workspace.assets/uuid.uuid4().hex; folder.mkdir()
        path=folder/'atlas.node'
        try: path.write_bytes(payload)
        except Exception: shutil.rmtree(folder); raise
        key='Generated/'+path.relative_to(self.workspace.assets).as_posix()
        self.workspace.catalog['node'][key]=path
        return key

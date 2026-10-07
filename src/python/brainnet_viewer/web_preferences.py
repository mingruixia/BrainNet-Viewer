"""Desktop-compatible bounded preset and RGB-table documents."""
import io
import json
import numpy as np
from .settings import normalize
from .palettes import palette

LIMIT=4*1024*1024


def json_input(data):
    if not isinstance(data,bytes) or not data or len(data)>LIMIT:
        raise ValueError('Configuration files must be nonempty and at most 4 MiB.')
    return json.loads(data.decode('utf-8-sig'),parse_constant=lambda value: (_ for _ in ()).throw(ValueError('Nonfinite JSON numbers are not allowed.')))


def load_preset(data):
    document=json_input(data)
    if not isinstance(document,dict) or document.get('kind')!='brainnet-visualization-preset' or document.get('schema_version')!='1.0':
        raise ValueError('Not a supported settings preset.')
    return normalize({'visualization_settings':document['settings']})


def save_preset(settings):
    result=json.dumps({'kind':'brainnet-visualization-preset','schema_version':'1.0','name':'BrainNet',
        'settings':normalize({'visualization_settings':settings})},ensure_ascii=False,allow_nan=False,indent=2).encode('utf-8')
    if len(result)>LIMIT: raise ValueError('Preset exceeds 4 MiB.')
    return result


def rgb_rows(value):
    if not isinstance(value,(list,tuple,np.ndarray)) or not 1<=len(value)<=4096:
        raise ValueError('RGB tables require 1–4096 rows.')
    rows=np.asarray(value,dtype=float)
    palette(rows)
    return rows.tolist()


def import_rgb(name,data):
    if not isinstance(data,bytes) or not data or len(data)>LIMIT: raise ValueError('RGB files must be nonempty and at most 4 MiB.')
    suffix=name.lower().rsplit('.',1)[-1]
    if suffix=='json':
        value=json_input(data)
        if isinstance(value,dict): value=value.get('rgb',value.get('colors'))
    elif suffix in ('txt','csv'):
        value=np.loadtxt(io.StringIO(data.decode('utf-8-sig')),delimiter=',' if suffix=='csv' else None,ndmin=2)
    else: raise ValueError('Choose RGB JSON, TXT or CSV.')
    return rgb_rows(value)


def export_rgb(rows,format):
    rows=rgb_rows(rows)
    if format=='json': return json.dumps(rows,allow_nan=False,indent=2).encode('utf-8')
    if format not in ('txt','csv'): raise ValueError('Choose RGB JSON, TXT or CSV.')
    stream=io.StringIO(); np.savetxt(stream,rows,fmt='%.17g',delimiter=',' if format=='csv' else ' ')
    return stream.getvalue().encode('utf-8')

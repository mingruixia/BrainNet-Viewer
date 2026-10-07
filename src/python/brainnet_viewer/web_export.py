"""Bounded Web export preferences; desktop conversion rules are reused."""
from .export_size import figure_size
import re

FORMATS=('png','tif','jpg','bmp','pdf','svg')
UNITS=('Pixels','Millimetres','Centimetres','Inches','Points')
TRANSPARENT=('png','tif','pdf','svg')


def image_name(name,format):
    if not isinstance(name,str): raise ValueError('Enter a file name, not a path.')
    name=name.strip()
    if not name or len(name)>120 or re.search(r'[<>:"/\\|?*\x00-\x1f]',name) or name.endswith(('.', ' ')):
        raise ValueError('Use a file name of 1–120 characters without path separators or reserved characters.')
    aliases={'tif':('tif','tiff'),'jpg':('jpg','jpeg')}.get(format,(format,))
    if any(name.lower().endswith('.'+ext) for ext in aliases): name=name.rsplit('.',1)[0]
    if not name or name in ('.','..') or re.match(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',name,re.I):
        raise ValueError('Choose a non-reserved file name.')
    return name+'.'+format


def preferences(width,height,dpi,transparent=False,format='png',units='Pixels'):
    format={'tiff':'tif','jpeg':'jpg'}.get(format,format)
    if format not in FORMATS: raise ValueError('Choose PNG, TIFF, JPEG, BMP, PDF or SVG.')
    if units not in UNITS: raise ValueError('Unknown figure size units.')
    if any(isinstance(v,bool) for v in (width,height,dpi)):
        raise ValueError('Export dimensions and DPI must be numbers.')
    width,height,dpi=map(float,(width,height,dpi))
    pixels=figure_size(width,height,dpi,units)
    if int(dpi)!=dpi or not 72<=dpi<=600 or not all(64<=v<=4096 for v in pixels):
        raise ValueError('Web export must be 64–4096 pixels per side and integer DPI 72–600.')
    if not isinstance(transparent,bool): raise ValueError('Transparent must be true or false.')
    if transparent and format not in TRANSPARENT:
        raise ValueError('JPEG and BMP do not support transparent export.')
    return {'width':width,'height':height,'dpi':int(dpi),'transparent':transparent,'format':format,'units':units},pixels

# SPDX-License-Identifier: GPL-3.0-or-later
"""Build the OFL annotation fonts and coverage; no runtime dependency.

Supply the three original fonts plus SC-OFL.txt and Latin-OFL.txt in --input.
The source directory is read-only; --output must be a new directory.
"""
from pathlib import Path
from hashlib import sha256
import importlib.metadata
import json
import argparse
import shutil
import tempfile
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset
from fontTools.merge import Merger
from fontTools.ttLib.tables._c_m_a_p import CmapSubtable

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--input', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
source = args.input
output = args.output
for name in ('NotoSansSC-VF.ttf', 'NotoSans-Regular.ttf', 'NotoSans-Bold.ttf',
             'SC-OFL.txt', 'Latin-OFL.txt'):
    if not (source / name).is_file():
        parser.error(f'Missing original font or license: {source / name}')
output.mkdir(parents=True, exist_ok=False)
coverage = {}
files = {}
for style, weight in [('regular', 400), ('bold', 700)]:
    cjk = instantiateVariableFont(TTFont(source / 'NotoSansSC-VF.ttf'), {'wght': weight}, inplace=True)
    latin_path = source / ('NotoSans-Bold.ttf' if style == 'bold' else 'NotoSans-Regular.ttf')
    latin = TTFont(latin_path)
    # The application draws horizontal annotations only. The complementary
    # Latin font has no vertical metrics; do not merge unmatched vertical tables.
    for font in (cjk, latin):
        for tag in ('vhea', 'vmtx', 'VORG', 'BASE', 'STAT'):
            if tag in font:
                del font[tag]
    missing = set(latin.getBestCmap()) - set(cjk.getBestCmap())
    options = subset.Options()
    options.recalc_timestamp = False
    small = subset.Subsetter(options=options)
    small.populate(unicodes=missing)
    small.subset(latin)
    with tempfile.TemporaryDirectory(prefix='font-build-', dir=output) as staging:
        cjk_path = Path(staging) / 'cjk.ttf'
        latin_small = Path(staging) / 'latin.ttf'
        cjk.save(cjk_path)
        latin.save(latin_small)
        font = Merger().merge([str(cjk_path), str(latin_small)])
    cjk.close()
    latin.close()
    # VTK 9.7 FreeTypeTools uses cmap index 0, not FT's preferred Unicode
    # charmap. A merged format-14 variation table must never occupy that slot.
    unicode_map = CmapSubtable.newSubtable(12)
    unicode_map.platformID, unicode_map.platEncID, unicode_map.language = 0, 4, 0
    unicode_map.cmap = dict(font.getBestCmap())
    font['cmap'].tables = [unicode_map] + [table for table in font['cmap'].tables
                                         if table.platformID == 3 and table.format in (4, 12)]
    for item in font['name'].names:
        values = {1: 'BrainNet Sans', 2: style.title(), 3: f'BrainNetSans-{style}-1.0',
                  4: f'BrainNet Sans {style.title()}', 6: f'BrainNetSans-{style.title()}',
                  16: 'BrainNet Sans', 17: style.title(), 5: 'Version 1.000'}
        if item.nameID in values:
            item.string = values[item.nameID].encode(item.getEncoding())
    # Fixed time makes generated font bytes independent of the build clock.
    font.recalcTimestamp = False
    font['head'].created = font['head'].modified = 3869856000
    target = output / f'BrainNetSans-{style.title()}.ttf'
    font.save(target)
    font = TTFont(target)
    assert font['cmap'].tables[0].format == 12 and font['cmap'].tables[0].isUnicode()
    points = sorted(font['cmap'].tables[0].cmap)
    ranges = []
    for code in points:
        if ranges and code == ranges[-1][1] + 1:
            ranges[-1][1] = code
        else:
            ranges.append([code, code])
    assert all(ord(c) in points for c in '静息态脑网络CO₂αβµ')
    coverage[style] = ranges
    files[style] = {'file': target.name, 'sha256': sha256(target.read_bytes()).hexdigest(),
                    'characters': len(points), 'bytes': target.stat().st_size}
    print(json.dumps(files[style]), flush=True)
manifest = {'version': '1.0', 'family': 'BrainNet Sans', 'license': 'OFL-1.1',
            'active_cmap': 'First charmap: Unicode format 12, full coverage',
            'build_fonttools': importlib.metadata.version('fonttools'), 'files': files,
            'coverage': coverage, 'sources': {name: sha256((source / name).read_bytes()).hexdigest()
                        for name in ['NotoSansSC-VF.ttf', 'NotoSans-Regular.ttf', 'NotoSans-Bold.ttf']}}
(output / 'coverage.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
shutil.copyfile(source / 'SC-OFL.txt', output / 'OFL-NotoSansSC.txt')
shutil.copyfile(source / 'Latin-OFL.txt', output / 'OFL-NotoSans.txt')
notice = Path(__file__).resolve().parents[1] / 'src/python/brainnet_viewer/resources/fonts/NOTICE.txt'
shutil.copyfile(notice, output / 'NOTICE.txt')

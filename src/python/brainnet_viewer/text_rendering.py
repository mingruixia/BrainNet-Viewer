# SPDX-License-Identifier: GPL-3.0-or-later
"""Portable glyph coverage and bounded annotation typography, without OS fonts."""
from bisect import bisect_right
from functools import lru_cache
from hashlib import sha256
import json
from pathlib import Path


# Screen typography stays in pixels; exports use print point sizes.
EXPORT_TITLE_POINTS = 12
EXPORT_ANNOTATION_POINTS = 8


def annotation_font_points(pixels, dpi, *, for_export=False):
    if for_export:
        return max(6, int(pixels * EXPORT_ANNOTATION_POINTS / 12 + .5))
    return max(1, int(pixels * 72 / dpi + .5))


@lru_cache(maxsize=2)
def _font(style):
    folder = Path(__file__).parent / 'resources/fonts'
    manifest = json.loads((folder / 'coverage.json').read_text(encoding='utf-8'))
    entry = manifest['files'][style]
    path = folder / entry['file']
    if sha256(path.read_bytes()).hexdigest() != entry['sha256']:
        raise ValueError('The bundled annotation font is damaged. Reinstall BrainNet Viewer.')
    ranges = manifest['coverage'][style]
    return {**entry, 'path': str(path.resolve()), 'ranges': ranges,
            'starts': [a for a, _ in ranges], 'family': manifest['family']}


def font_for_strings(strings, *, bold=False):
    """Retain legacy ASCII families; use a verified portable font otherwise.

    Cmap coverage is not a guarantee of shaping for every writing system.
    Missing glyphs are errors, not invisible replacements in scientific text.
    """
    strings = tuple(strings)
    controls = {ord(c) for text in strings for c in text
                if (ord(c) < 32 and c not in '\n\r\t') or ord(c) == 127}
    if controls:
        codes = ', '.join(f'U+{code:04X}' for code in sorted(controls)[:8])
        raise ValueError(f'Annotation text contains an unsupported control character: {codes}.')
    if all(text.isascii() for text in strings):
        return None
    info = _font('bold' if bold else 'regular')
    absent = set()
    for text in strings:
        for character in text:
            if character in '\n\r\t':
                continue
            code = ord(character)
            index = bisect_right(info['starts'], code) - 1
            if index < 0 or code > info['ranges'][index][1]:
                absent.add(code)
    if absent:
        codes = ', '.join(f'U+{code:04X}' for code in sorted(absent)[:8])
        raise ValueError(f'The annotation font has no glyph for {codes}. '
                         'Change the title or node label before rendering; no text was removed.')
    return info


def use_font(prop, info):
    if info:
        from vtkmodules.vtkCommonCore import VTK_FONT_FILE
        prop.SetFontFamily(VTK_FONT_FILE)
        prop.SetFontFile(info['path'])


class TitleFitError(ValueError):
    """The complete title cannot fit without exceeding the minimum text size."""


def validate_title(text, width, height, dpi, *, target_points=None):
    """Measure a prospective title without touching the visible canvas."""
    if not text:
        return
    from vtkmodules.vtkRenderingCore import vtkTextActor
    actor = vtkTextActor(); actor.SetInput(text)
    prop = actor.GetTextProperty(); prop.SetBold(True)
    use_font(prop, font_for_strings([text], bold=True))
    fit_title(actor, width, height, dpi, target_points=target_points)


def fit_title(actor, width, height, dpi, *, target_pixels=18, measure_dpi=None, target_points=None):
    """Fit the complete title into its reserved strip; do not crop or elide it."""
    from vtkmodules.vtkRenderingFreeType import vtkFreeTypeTools
    from vtkmodules.vtkRenderingCore import vtkTextProperty
    original = actor.GetTextProperty()
    prop = vtkTextProperty(); prop.ShallowCopy(original)
    if target_points is None:
        requested = max(1, int(target_pixels * 72 / dpi + .5))
        minimum = min(requested, max(1, int(8 * 72 / dpi + .999)))
    else:
        requested = max(1, int(target_points + .5))
        minimum = min(requested, 6)
    maximum_width, maximum_height = .94 * width, .065 * height
    measure_dpi = dpi if measure_dpi is None else measure_dpi
    tools = vtkFreeTypeTools.GetInstance()
    for size in range(requested, minimum - 1, -1):
        prop.SetFontSize(size)
        box = [0, 0, 0, 0]
        if not tools.GetBoundingBox(prop, actor.GetInput(), int(measure_dpi), box):
            raise ValueError('The title could not be drawn with the selected annotation font.')
        if box[1] - box[0] + 1 <= maximum_width and box[3] - box[2] + 1 <= maximum_height:
            original.SetFontSize(size)
            return size
    raise TitleFitError('The complete title does not fit this canvas. Widen the canvas or shorten the title.')

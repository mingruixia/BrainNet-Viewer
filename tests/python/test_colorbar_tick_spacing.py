"""Native Mac scalar labels at small/normal output sizes; no font reduction."""
from copy import deepcopy
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

import numpy as np
from PIL import Image
from PySide6 import QtCore, QtWidgets as W
from pyvistaqt import QtInteractor
from vtkmodules.vtkRenderingFreeType import vtkFreeTypeTools
from brainnet_viewer.rendering import SceneRenderer, prepare
from brainnet_viewer.settings import DEFAULTS

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(sys.platform == 'darwin', 'Actual macOS Qt capture required')
class MacScalarTickSpacingTests(unittest.TestCase):
    def test_small_and_normal_exports_keep_labels_separate_and_restore(self):
        qt = W.QApplication.instance() or W.QApplication([])
        window = W.QWidget(); layout = W.QVBoxLayout(window)
        plot = QtInteractor(window); layout.addWidget(plot)
        window.resize(900, 700); window.show(); qt.processEvents()
        renderer = SceneRenderer(plot)
        fixture = ROOT / 'tests/fixtures/cross-platform-v0.1'
        settings = deepcopy(DEFAULTS)
        settings['surface']['color_mode'] = 'scalar'
        settings['image'].update(title='Mac font restoration', show_colorbar=True)
        settings['node']['color_mode'] = 'modular'
        prepared = prepare({'surface': fixture/'tetrahedron.nv',
                            'surface_map': fixture/'null-map.txt',
                            'node': fixture/'three.node'}, settings)
        renderer.render(prepared); qt.processEvents()
        plot.render_window.MakeCurrent(); plot.render_window.Render()
        captures = []; errors = []
        def state():
            return {'camera': renderer.capture_camera(), 'size': tuple(plot.window_size),
                    'dpi': plot.render_window.GetDPI(), 'fit': renderer.fit_size,
                    'fonts': [p.GetFontSize() for p, _ in renderer.annotation_text_props],
                    'ticks': [bar.GetNumberOfLabels() for bar in renderer.surface_colorbars],
                    'alpha': renderer.background.GetBackgroundAlpha(), 'exporting': renderer.exporting}
        before = state(); original = plot.screenshot
        with tempfile.TemporaryDirectory() as temp:
            output = Path(os.environ.get('BNV_TICK_EVIDENCE', temp)); output.mkdir(exist_ok=True)
            def capture(*args, **kwargs):
                image = original(*args, **kwargs)
                bar = renderer.surface_colorbars[0]; rect = [0, 0, 0, 0]
                bar.GetScalarBarRect(rect, renderer.annotations)
                count = bar.GetNumberOfLabels(); prop = bar.GetLabelTextProperty()
                low, high = bar.GetLookupTable().GetTableRange()
                bounds = []
                for i, value in enumerate(np.linspace(low, high, count)):
                    text = bar.GetLabelFormat().format(value)
                    box = [0, 0, 0, 0]
                    self.assertTrue(vtkFreeTypeTools.GetInstance().GetBoundingBox(
                        prop, text, plot.render_window.GetDPI(), box))
                    center = rect[0] + i*rect[2]/(count-1)
                    bounds.append({'text': text, 'left': center-(box[1]-box[0]+1)/2,
                                   'right': center+(box[1]-box[0]+1)/2})
                captures.append({'size': list(plot.window_size), 'count': count,
                                 'font_points': prop.GetFontSize(), 'scalar_rect': rect,
                                 'labels': bounds, 'range': [low, high]})
                return image
            loop = QtCore.QEventLoop()
            def exercise():
                try:
                    with patch.object(plot, 'screenshot', side_effect=capture):
                        for width, height, count in [(640,480,2), (2000,1500,4)]:
                            target = output/f'{width}x{height}.png'
                            renderer.export(target, width, height, 200, True)
                            self.assertEqual(state(), before)
                            info = captures[-1]
                            self.assertEqual(info['count'], count)
                            self.assertEqual(info['font_points'], 8)
                            for left, right in zip(info['labels'], info['labels'][1:]):
                                self.assertGreaterEqual(right['left']-left['right'], 4)
                            with Image.open(target) as image:
                                self.assertEqual(image.size, (width,height))
                                self.assertEqual(image.mode, 'RGBA')
                        with patch('brainnet_viewer.figure_export.save_figure', side_effect=RuntimeError('controlled writer failure')):
                            with self.assertRaisesRegex(RuntimeError, 'controlled writer failure'):
                                renderer.export(output/'must-not-exist.png',640,480,200,True)
                        self.assertFalse((output/'must-not-exist.png').exists())
                        self.assertEqual(state(), before)
                except BaseException as error:
                    errors.append(error)
                finally:
                    QtCore.QTimer.singleShot(150, loop.quit)
            try:
                QtCore.QTimer.singleShot(0, exercise); loop.exec()
                if errors: raise errors[0]
                self.assertEqual(state(), before)
            finally:
                (output/'capture-metrics.json').write_text(json.dumps(
                    {'captures': captures, 'before': before, 'after': state(),
                     'qt_platform': qt.platformName(), 'backend': plot.render_window.ReportCapabilities(),
                     'evidence': 'Actual Mac Qt capture; screenshot wrapper observes native rendering; only writer failure is mocked'}, indent=2))
                renderer.dispose(); plot.close(); window.close(); qt.processEvents()

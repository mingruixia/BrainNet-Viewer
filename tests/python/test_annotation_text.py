# SPDX-License-Identifier: GPL-3.0-or-later
"""Targeted glyph coverage, actual annotation drawing and export restoration."""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
import numpy as np
import pyvista as pv
from PIL import Image
from vtkmodules.vtkCommonDataModel import vtkImageData
from vtkmodules.vtkRenderingCore import vtkTextProperty
from vtkmodules.vtkRenderingFreeType import vtkFreeTypeTools
from vtkmodules.util.numpy_support import vtk_to_numpy
from brainnet_viewer.rendering import SceneRenderer, prepare
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.text_rendering import font_for_strings, use_font

FIXTURE = Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv'
LONG = 'Resting-state connectivity: AAL90, positive and negative effects, uncorrected P<0.05'


class AnnotationTextTests(unittest.TestCase):
    def make(self, title='', width=800, paths=None, labels=False):
        settings = deepcopy(DEFAULTS)
        settings['image']['title'] = title
        settings['image']['show_colorbar'] = False
        settings['node']['label_mode'] = 'all' if labels else 'none'
        settings['node']['label_in_front'] = True
        plot = pv.Plotter(off_screen=True, window_size=(width, 600))
        self.addCleanup(plot.close)
        renderer = SceneRenderer(plot)
        self.addCleanup(renderer.dispose)
        renderer.render(prepare(paths or {'surface': FIXTURE}, settings))
        return plot, renderer

    def test_portable_font_has_actual_glyph_ink_for_cjk_and_scientific_symbols(self):
        for bold in (False, True):
            prop = vtkTextProperty()
            prop.SetFontSize(24)
            info = font_for_strings(['静息态脑网络CO₂αβµ'], bold=bold)
            use_font(prop, info)
            self.assertIsNotNone(info)
            for character in '静息态脑网络₂αβµ':
                image = vtkImageData()
                self.assertTrue(vtkFreeTypeTools.GetInstance().RenderString(prop, character, 96, image))
                rgba = vtk_to_numpy(image.GetPointData().GetScalars())
                self.assertGreater(int((rgba[:, 3] > 0).sum()), 12, character)
        self.assertIsNone(font_for_strings(['Plain ASCII title', 'ROI_29']))
        with self.assertRaisesRegex(ValueError, 'U\\+0000'):
            font_for_strings(['Do not truncate\x00this title'])

    def test_actual_title_uses_all_characters_and_fits_narrow_canvas(self):
        for title in ('静息态脑网络', 'CO₂', LONG):
            with self.subTest(title=title):
                plot, renderer = self.make(title, 560)
                frame = plot.screenshot(return_img=True)
                ink = frame[:75, :, :3].min(axis=2) < 128
                columns = np.flatnonzero(ink.any(axis=0))
                self.assertGreater(int(ink.sum()), 60)
                self.assertGreater(int(columns.min()), 3)
                self.assertLess(int(columns.max()), 556)
                self.assertEqual(renderer.title_actor.GetInput(), title)
                renderer.dispose(); plot.close()

    def test_subscript_changes_actual_title_pixels(self):
        a, _ = self.make('CO₂')
        b, _ = self.make('CO')
        self.assertFalse(np.array_equal(a.screenshot(return_img=True)[:75], b.screenshot(return_img=True)[:75]))

    def test_unicode_node_labels_have_font_and_visible_pixels(self):
        with tempfile.TemporaryDirectory() as folder:
            node = Path(folder) / 'demonstration.node'
            node.write_text('0 0 0 1 2 岛叶 CO₂\n', encoding='utf-8')
            plot, renderer = self.make(paths={'node': node}, labels=True)
            frame = plot.screenshot(return_img=True)
            prop = renderer.label_records[0][-1].GetMapper().GetInputAlgorithm().GetTextProperty()
            self.assertTrue(prop.GetFontFile().endswith('BrainNetSans-Regular.ttf'))
            other, _ = self.make(paths={'node': node}, labels=False)
            self.assertFalse(np.array_equal(frame, other.screenshot(return_img=True)))

    def test_missing_glyph_rejected_before_old_canvas_changes(self):
        plot, renderer = self.make('Existing title')
        old = renderer.prepared
        before = plot.screenshot(return_img=True)
        settings = deepcopy(DEFAULTS)
        settings['image']['title'] = 'Missing \U0010ffff'
        with self.assertRaisesRegex(ValueError, 'U\\+10FFFF'):
            renderer.render(prepare({'surface': FIXTURE}, settings))
        self.assertIs(renderer.prepared, old)
        self.assertTrue(np.array_equal(before, plot.screenshot(return_img=True)))

    def test_png_pdf_export_fonts_cameras_and_dpi_restore(self):
        plot, renderer = self.make('岛叶 CO₂ — voxelwise P<0.05', width=560)
        camera = renderer.capture_camera()
        size = tuple(plot.window_size)
        dpi = plot.render_window.GetDPI()
        fonts = [(prop, prop.GetFontSize()) for prop, _ in renderer.annotation_text_props]
        with tempfile.TemporaryDirectory() as folder:
            for name, transparent in [('first.png', True), ('second.png', True), ('clear.pdf', True), ('opaque.pdf', False)]:
                target = Path(folder) / name
                renderer.export(target, 800, 600, 200, transparent)
                self.assertEqual(tuple(plot.window_size), size)
                self.assertEqual(plot.render_window.GetDPI(), dpi)
                self.assertEqual(renderer.capture_camera(), camera)
                self.assertTrue(all(prop.GetFontSize() == value for prop, value in fonts))
                record = json.loads(Path(str(target) + '.provenance.json').read_text(encoding='utf-8'))
                self.assertEqual(record['settings']['image']['title'], '岛叶 CO₂ — voxelwise P<0.05')
                self.assertTrue(record['text_rendering']['font_assets'])
                self.assertTrue(all('path' not in item for item in record['text_rendering']['font_assets']))
                if target.suffix == '.png':
                    image = np.asarray(Image.open(target))
                    self.assertEqual(image.shape, (600, 800, 4))
                    self.assertEqual(int(image[:, :, 3].min()), 0)
                    self.assertGreater(int(image[:70, :, 3].sum()), 1000)
                if name == 'opaque.pdf':
                    from pypdf import PdfReader
                    from pypdf.generic import ContentStream
                    pdf = PdfReader(target)
                    page = pdf.pages[0]
                    operations = ContentStream(page.get_contents(), pdf).operations
                    self.assertNotIn(b'ca', [operator for _,operator in operations])
                    for operands, operator in operations:
                        if operator == b'gs':
                            self.assertIn(operands[0], page['/Resources']['/ExtGState'])
            self.assertTrue(np.array_equal(np.asarray(Image.open(Path(folder)/'first.png')),
                                           np.asarray(Image.open(Path(folder)/'second.png'))))

    def test_web_real_resize_sampling_and_reapply(self):
        from brainnet_viewer.web_workspace import WebWorkspace
        workspace = WebWorkspace()
        try:
            workspace.paths = {'surface': FIXTURE}
            workspace.configure({'image': {'title': '静息态 CO₂ ' + LONG}})
            workspace.render()
            window = workspace.plotter.render_window
            workspace.set_screen_ratio(2)
            window.SetSize(1120, 840)
            frame = workspace.plotter.screenshot(return_img=True)
            self.assertEqual(frame.shape[:2], (840,1120))
            ink = frame[:120,:,:3].min(axis=2) < 128
            columns = np.flatnonzero(ink.any(axis=0))
            self.assertGreater(int(columns.min()), 3)
            self.assertLess(int(columns.max()), 1116)
            workspace.configure({'image': {'title': 'Updated 岛叶 CO₂'}})
            workspace.render()
            self.assertIs(workspace.plotter.render_window, window)
            self.assertIn('岛叶', workspace.renderer.title_actor.GetInput())
        finally:
            workspace.close()


if __name__ == '__main__':
    unittest.main()

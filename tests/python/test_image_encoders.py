# SPDX-License-Identifier: GPL-3.0-or-later
"""Image encoder compatibility through the real figure and animation paths."""
import base64
from copy import deepcopy
import hashlib
import io
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image
import pyvista as pv

from brainnet_viewer.movies import export_movie, movie_plan
from brainnet_viewer.rendering import SceneRenderer, prepare
from brainnet_viewer.settings import DEFAULTS

FIXTURE = Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv'


class ImageEncoderTests(unittest.TestCase):
    def setUp(self):
        self.paths = {'surface': FIXTURE}
        settings = deepcopy(DEFAULTS)
        settings['image']['show_colorbar'] = False
        settings['image']['title'] = 'Image export'
        self.plot = pv.Plotter(off_screen=True, window_size=(400, 300))
        self.addCleanup(self.plot.close)
        self.renderer = SceneRenderer(self.plot)
        self.addCleanup(self.renderer.dispose)
        self.renderer.render(prepare(self.paths, settings))

    def test_raster_and_embedded_svg_pixels_and_restore(self):
        camera = self.renderer.capture_camera()
        dpi = self.plot.render_window.GetDPI()
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            arrays = {}
            for suffix in ('png', 'tif', 'jpg'):
                target = folder / ('opaque.' + suffix)
                self.renderer.export(target, 400, 300, 100, False, paths=self.paths)
                with Image.open(target) as image:
                    self.assertEqual(image.size, (400, 300))
                    self.assertTrue(np.allclose(image.info['dpi'], (100, 100), atol=0.1))
                    arrays[suffix] = np.array(image.convert('RGB'))
                self.assertEqual(self.renderer.capture_camera(), camera)
                self.assertEqual(tuple(self.plot.window_size), (400, 300))
                self.assertEqual(self.plot.render_window.GetDPI(), dpi)
            self.assertGreater(int(np.count_nonzero(arrays['png'].min(axis=2) < 200)), 100)
            np.testing.assert_array_equal(arrays['png'], arrays['tif'])
            self.assertLess(float(np.abs(arrays['png'].astype(float) - arrays['jpg']).mean()), 5)

            png, svg = folder / 'clear.png', folder / 'clear.svg'
            self.renderer.export(png, 400, 300, 100, True, paths=self.paths)
            self.renderer.export(svg, 400, 300, 100, True, paths=self.paths)
            element = ET.parse(svg).getroot().find('{http://www.w3.org/2000/svg}image')
            uri = element.attrib['{http://www.w3.org/1999/xlink}href']
            self.assertTrue(uri.startswith('data:image/png;base64,'))
            with Image.open(io.BytesIO(base64.b64decode(uri.split(',', 1)[1]))) as embedded:
                with Image.open(png) as original:
                    np.testing.assert_array_equal(np.asarray(embedded), np.asarray(original))
                    alpha = np.asarray(original)[:, :, 3]
                    self.assertEqual(int(alpha.min()), 0)
                    self.assertGreater(int(alpha.max()), 0)
            self.assertEqual(self.renderer.capture_camera(), camera)
            self.assertEqual(self.plot.render_window.GetDPI(), dpi)

    def test_animation_png_frames_and_source_camera(self):
        camera = self.renderer.capture_camera()
        plan = movie_plan(format='png', width=160, height=128,
                          duration=1, frame_rate=2, end_angle=90)
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / 'frames'
            record = export_movie(self.renderer, destination, plan, paths=self.paths)
            self.assertEqual(record['verified_frames'], 2)
            frames = []
            for frame in record['frames']:
                data = (destination / frame['file']).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), frame['sha256'])
                with Image.open(io.BytesIO(data)) as image:
                    self.assertEqual(image.size, (160, 128))
                    frames.append(np.array(image))
            self.assertFalse(np.array_equal(*frames))
            self.assertEqual((destination / 'preview.png').read_bytes(),
                             (destination / record['frames'][0]['file']).read_bytes())
            self.assertTrue(record['source_camera_untouched'])
        self.assertEqual(self.renderer.capture_camera(), camera)
        self.assertEqual(tuple(self.plot.window_size), (400, 300))


if __name__ == '__main__':
    unittest.main()

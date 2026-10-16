# SPDX-License-Identifier: GPL-3.0-or-later
"""Nonzero colors and uncorrected P-value semantics, without changing statistics."""
from copy import deepcopy
from types import SimpleNamespace
import unittest
import numpy as np
from brainnet_viewer.rendering import surface_map_palette, palette, Prepared, SceneRenderer
from brainnet_viewer.io import read_surface
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.volume import p_cutoff
from pathlib import Path


class ScalarDisplayTests(unittest.TestCase):
    def test_near_zero_palette_is_not_replaced(self):
        settings = deepcopy(DEFAULTS['surface'])
        settings.update(color_limits=[-1, 1], colormap='viridis', color=[.9, .9, .9])
        values = np.array([-.0078, 0, .005, .0078, np.nan, np.inf])
        original = values.copy()
        cmap, limits = surface_map_palette(values, settings)
        np.testing.assert_array_equal(cmap.colors, palette('viridis'))
        np.testing.assert_array_equal(values, original)
        self.assertEqual(limits, [-1, 1])

    def test_actual_surface_rgb_keeps_exact_null_mask(self):
        import pyvista as pv
        settings = deepcopy(DEFAULTS)
        settings['surface'].update(color_mode='scalar', color_limits=[-1, 1], colormap='viridis')
        mesh = read_surface(Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv')
        values = np.array([0., .005, .0078, np.nan])
        prepared = Prepared(mesh, None, None, values, [], np.empty((0, 2), int), np.empty(0), settings, None, None)
        plot = pv.Plotter(off_screen=True)
        renderer = SceneRenderer(plot)
        try:
            renderer.render(prepared)
            actor = renderer.pick_actors[0][0][0]
            rgb = actor.mapper.dataset[actor.mapper.array_name]
            if rgb.dtype == np.uint8: rgb = rgb / 255
            cmap, limits = surface_map_palette(values, settings['surface'])
            expected = np.asarray(cmap((values + 1) / 2))[:, :3]
            expected[[0, 3]] = settings['surface']['color']
            np.testing.assert_allclose(rgb, expected, atol=1/255)
            np.testing.assert_array_equal(prepared.mapped, values)
        finally:
            renderer.dispose(); plot.close(); plot.deep_clean()

    def test_p_value_metadata_is_explicit_without_changing_cutoff(self):
        from scipy.stats import t
        metadata = p_cutoff(SimpleNamespace(description='SPM{T_[20]}', intent=('none', (), '')), .05)
        self.assertAlmostEqual(metadata['cutoff'], t.isf(.025, 20))
        self.assertEqual(metadata['inference_level'], 'voxel')
        self.assertEqual(metadata['multiple_comparison_correction'], 'none')
        self.assertEqual(metadata['tail'], 'two-sided')

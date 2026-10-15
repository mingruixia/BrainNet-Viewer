# SPDX-License-Identifier: GPL-3.0-or-later
"""Advisory diagnostics must not change scientific selection/threshold values."""
from copy import deepcopy
from dataclasses import dataclass
import unittest
import warnings
import numpy as np
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.network import select_edges, edge_diagnostics
from brainnet_viewer.volume import threshold_volume


class DiagnosticTests(unittest.TestCase):
    def test_lower_triangle_warns_without_symmetrizing(self):
        matrix = np.zeros((4, 4)); matrix[3, 0] = 2; matrix[2, 1] = -3
        settings = deepcopy(DEFAULTS['edge']); settings.update(directed=False, selection_mode='all')
        original = matrix.copy()
        with warnings.catch_warnings(record=True) as found:
            warnings.simplefilter('always')
            pairs, values = select_edges(matrix, settings)
        self.assertEqual(len(pairs), 0)
        self.assertEqual(len(values), 0)
        self.assertIn('upper triangle', str(found[0].message))
        np.testing.assert_array_equal(matrix, original)
        self.assertFalse(edge_diagnostics(matrix, dict(settings, directed=True)))
        self.assertFalse(edge_diagnostics(matrix + matrix.T, settings))

    def test_cluster_metadata_preserves_mode_contract(self):
        @dataclass
        class Volume:
            data: object
            description: str = 'SPM{T_[20]}'
            intent: tuple = ('none', (), '')
        data = np.zeros((5, 5, 5)); data[0, 0, :2] = 4; data[4, 4, :3] = -5
        settings = deepcopy(DEFAULTS['volume']); settings.update(cluster_size=3, statistical_threshold=1,
                                                               type='surface-map', threshold_mode='value')
        result, info = threshold_volume(Volume(data), settings)
        self.assertTrue(info['cluster_size_ignored'])
        self.assertFalse(info['cluster_size_applied'])
        self.assertEqual(np.count_nonzero(result.data), 5)
        filtered, info = threshold_volume(Volume(data), dict(settings, threshold_mode='cluster'))
        self.assertEqual(np.count_nonzero(filtered.data), 3)
        self.assertTrue(info['cluster_size_applied'])
        self.assertEqual(info['voxel_connectivity'], settings['voxel_connectivity'])
        self.assertEqual(info['cluster_sign_policy'], 'combined-nonzero')
        self.assertEqual(np.count_nonzero(data), 5)
        kept, info = threshold_volume(Volume(data), dict(settings, threshold_mode='p-value'))
        self.assertTrue(info['cluster_size_ignored'])
        self.assertEqual(np.count_nonzero(kept.data), 5)
        kept, info = threshold_volume(Volume(data), dict(settings, threshold_mode='p-value', type='roi'))
        self.assertTrue(info['cluster_size_applied'])
        self.assertEqual(np.count_nonzero(kept.data), 3)

# SPDX-License-Identifier: GPL-3.0-or-later
"""Display-rule identity is additive and independent of scientific settings."""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
import pyvista as pv
from brainnet_viewer.provenance import DISPLAY_RULES, build_provenance, sidecar_path
from brainnet_viewer.rendering import prepare, SceneRenderer
from brainnet_viewer.session import digest, signature
from brainnet_viewer.settings import DEFAULTS


class DisplayProvenanceTests(unittest.TestCase):
    def test_export_records_rules_without_changing_settings_or_signature(self):
        fixture = Path(__file__).parents[1]/'fixtures/cross-platform-v0.1/tetrahedron.nv'
        settings = deepcopy(DEFAULTS)
        paths = {'surface': fixture}
        prepared = prepare(paths, settings)
        plot = pv.Plotter(off_screen=True, window_size=(320,240))
        renderer = SceneRenderer(plot)
        try:
            renderer.render(prepared)
            with tempfile.TemporaryDirectory() as folder:
                target = Path(folder)/'figure.png'
                renderer.export(target, 320, 240, 100, True, paths=paths)
                record = json.loads(sidecar_path(target).read_text())
            self.assertEqual(record['display_rules'], DISPLAY_RULES)
            self.assertEqual(record['display_rules_sha256'], digest(DISPLAY_RULES))
            self.assertEqual(record['settings'], settings)
            self.assertEqual(record['render_signature'], signature(prepared.input_hashes, settings))
            self.assertEqual(record['schema_version'], '1.0')
            record = build_provenance(renderer, paths, {'format':'png'})
            record['display_rules']['version'] = 'changed-by-caller'
            self.assertEqual(DISPLAY_RULES['version'], '1.0')
        finally:
            renderer.dispose()
            plot.close()
            plot.deep_clean()


if __name__ == '__main__':
    unittest.main()

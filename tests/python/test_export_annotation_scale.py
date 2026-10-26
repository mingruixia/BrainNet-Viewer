# SPDX-License-Identifier: GPL-3.0-or-later
"""Physical export text size and preservation of user-selected label units."""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import numpy as np
from PIL import Image
import pyvista as pv
from brainnet_viewer.rendering import SceneRenderer, prepare
from brainnet_viewer.settings import DEFAULTS

FIXTURE=Path(__file__).resolve().parents[1]/'fixtures/cross-platform-v0.1/tetrahedron.nv'

class ExportAnnotationScaleTests(unittest.TestCase):
    def make(self, *, label_units=None):
        folder=tempfile.TemporaryDirectory();self.addCleanup(folder.cleanup)
        root=Path(folder.name);values=root/'map.txt';np.savetxt(values,[1,2,3,4])
        paths={'surface':FIXTURE,'surface_map':values}
        settings=deepcopy(DEFAULTS)
        settings['image'].update(title='Connectivity T map (AAL90)',show_colorbar=False)
        settings['surface'].update(color_mode='scalar',show_colorbar=True)
        if label_units:
            node=root/'label.node';node.write_text('0 0 0 1 1 Region_A\n',encoding='utf-8')
            paths['node']=node
            settings['node'].update(label_mode='all',label_font_size=9 if label_units=='points' else 18,
                                    label_font_units=label_units,label_in_front=True)
        plot=pv.Plotter(off_screen=True,window_size=(1200,900),border=False)
        self.addCleanup(plot.close)
        renderer=SceneRenderer(plot);self.addCleanup(renderer.dispose)
        renderer.render(prepare(paths,settings))
        return root,plot,renderer

    @staticmethod
    def screen_state(renderer):
        return (renderer.capture_camera(),tuple(renderer.plotter.window_size),
                renderer.plotter.render_window.GetDPI(),
                [p.GetFontSize() for p,_ in renderer.annotation_text_props],renderer.annotation_warning)

    def test_same_physical_figure_retains_text_size_at_double_dpi(self):
        root,plot,renderer=self.make();before=self.screen_state(renderer);heights=[]
        for width,height,dpi in [(2000,1500,300),(4000,3000,600)]:
            target=root/f'{dpi}.png';renderer.export(target,width,height,dpi,False)
            self.assertEqual(self.screen_state(renderer),before)
            with Image.open(target) as image:
                self.assertEqual(image.size,(width,height))
                top=np.asarray(image.convert('RGB'))[:int(.065*height)]
            rows=np.flatnonzero((top.min(axis=2)<200).any(axis=1))
            heights.append(int(rows[-1]-rows[0]+1))
            sidecar=json.loads(Path(str(target)+'.provenance.json').read_text(encoding='utf-8'))
            typography=sidecar['text_rendering']
            self.assertEqual(typography['global_annotation_sizing'],'physical-points')
            self.assertEqual(typography['global_annotation_font_points'],[8])
            self.assertEqual(typography['title_font_points'],12)
        # Rasterization can add a few antialiasing pixels; physical height must
        # remain stable, rather than halving as it did with fixed pixel text.
        self.assertLessEqual(abs(heights[1]-2*heights[0]),4)
        self.assertGreater(heights[0],35)

    def test_writer_failure_restores_screen_and_preserves_node_label_units(self):
        for units,expected in [('points',9),('pixels',4)]:
            with self.subTest(units=units):
                root,plot,renderer=self.make(label_units=units)
                before=self.screen_state(renderer)
                label=renderer.label_records[0][-1].GetMapper().GetInputAlgorithm().GetTextProperty()
                old_label=label.GetFontSize();observed=[]
                def fail(*args,**kwargs):
                    observed.append(label.GetFontSize())
                    self.assertEqual(renderer.title_actor.GetTextProperty().GetFontSize(),12)
                    raise RuntimeError('Controlled figure-writer failure')
                with patch('brainnet_viewer.figure_export.save_figure',side_effect=fail):
                    with self.assertRaisesRegex(RuntimeError,'Controlled figure-writer'):
                        renderer.export(root/'not-published.png',2000,1500,300,False)
                self.assertEqual(observed,[expected])
                self.assertEqual(self.screen_state(renderer),before)
                self.assertEqual(label.GetFontSize(),old_label)
                self.assertFalse((root/'not-published.png').exists())
                self.assertFalse(renderer.exporting)

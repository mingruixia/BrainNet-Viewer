# SPDX-License-Identifier: GPL-3.0-or-later
"""Title-size failures, real resize callbacks and target-sized export recovery."""
from copy import deepcopy
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
import numpy as np
import pyvista as pv
from PIL import Image
from brainnet_viewer.rendering import SceneRenderer, prepare
from brainnet_viewer.settings import DEFAULTS
from brainnet_viewer.text_rendering import fit_title, TitleFitError

FIXTURE=Path(__file__).parents[1]/'fixtures/cross-platform-v0.1/tetrahedron.nv'
LONG='Connectivity effect, voxelwise uncorrected P<0.05; ' * 5


def snapshot(renderer):
    return {'camera':renderer.capture_camera(),'size':tuple(renderer.plotter.window_size),
            'fit':renderer.fit_size,'dpi':renderer.plotter.render_window.GetDPI(),
            'fonts':[p.GetFontSize() for p,_ in renderer.annotation_text_props],
            'visible':renderer.title_actor.GetVisibility(),'warning':renderer.annotation_warning,
            'alpha':renderer.background.GetBackgroundAlpha(),'exporting':renderer.exporting}


class TitleCanvasTests(unittest.TestCase):
    def make(self,title='Original valid title',size=(1800,800)):
        settings=deepcopy(DEFAULTS)
        settings['image'].update(title=title,show_colorbar=False)
        plot=pv.Plotter(off_screen=True,window_size=size,border=False)
        self.addCleanup(plot.close)
        renderer=SceneRenderer(plot);self.addCleanup(renderer.dispose)
        renderer.render(prepare({'surface':FIXTURE},settings))
        return plot,renderer

    def test_failed_apply_preserves_committed_canvas_and_camera(self):
        plot,renderer=self.make()
        plot.camera.azimuth+=12;plot.camera.parallel_scale*=.9
        old=renderer.prepared;before=snapshot(renderer)
        pixels=plot.screenshot(return_img=True)
        draft=deepcopy(old.settings)
        draft['image']['title']='Connectivity threshold P<0.05; '*40
        draft['surface']['color']=[1.,0.,0.]
        with self.assertRaisesRegex(TitleFitError,'complete title'):
            renderer.render(prepare({'surface':FIXTURE},draft))
        self.assertIs(renderer.prepared,old)
        self.assertEqual(snapshot(renderer),before)
        np.testing.assert_array_equal(plot.screenshot(return_img=True),pixels)

    def test_failed_measurement_does_not_change_existing_font(self):
        _,renderer=self.make(LONG)
        prop=renderer.title_actor.GetTextProperty();before=prop.GetFontSize()
        with self.assertRaises(TitleFitError):fit_title(renderer.title_actor,40,600,72)
        self.assertEqual(prop.GetFontSize(),before)

    def test_resize_hides_only_unfittable_title_then_restores_full_text(self):
        plot,renderer=self.make(LONG)
        plot.camera.azimuth+=15;plot.camera.parallel_scale*=.87
        original=renderer.capture_camera()
        plot.window_size=(120,600);renderer.resize_fit(120,600)
        self.assertFalse(renderer.title_actor.GetVisibility())
        self.assertIn('temporarily hidden',renderer.annotation_warning)
        self.assertEqual(renderer.title_actor.GetInput(),LONG)
        self.assertEqual(renderer.fit_size,(120,600))
        plot.window_size=(1800,800);renderer.resize_fit(1800,800)
        self.assertTrue(renderer.title_actor.GetVisibility())
        self.assertEqual(renderer.annotation_warning,'')
        for key in ('position','target','up','zoom_factor','view_angle'):
            np.testing.assert_allclose(renderer.capture_camera()['views'][0][key],original['views'][0][key],rtol=1e-12,atol=1e-12)

    def test_export_uses_target_size_and_restores_hidden_screen_after_errors(self):
        plot,renderer=self.make(LONG)
        plot.window_size=(120,600);renderer.resize_fit(120,600)
        before=snapshot(renderer)
        with tempfile.TemporaryDirectory() as folder:
            target=Path(folder)/'large.png'
            renderer.export(target,2400,800,200,True)
            self.assertEqual(snapshot(renderer),before)
            rgba=np.asarray(Image.open(target))
            self.assertEqual(rgba.shape,(800,2400,4))
            self.assertEqual(int(rgba[:,:,3].min()),0)
            self.assertGreater(int(rgba[:65,:,3].sum()),1000)
            record=json.loads(Path(str(target)+'.provenance.json').read_text(encoding='utf-8'))
            self.assertEqual(record['settings']['image']['title'],LONG)
            blocked=Path(folder)/'small.png';blocked.write_bytes(b'keep existing output')
            with self.assertRaises(TitleFitError):renderer.export(blocked,100,60,200,True,overwrite=True)
            self.assertEqual(blocked.read_bytes(),b'keep existing output')
            self.assertFalse(Path(str(blocked)+'.provenance.json').exists())
            self.assertEqual(snapshot(renderer),before)
            with self.assertRaisesRegex(ValueError,'existing output directory'):
                renderer.export(Path(folder)/'absent'/'large.png',2400,800,200,True)
            self.assertEqual(snapshot(renderer),before)

    def test_web_native_resize_callback_publishes_warning_and_recovers(self):
        from brainnet_viewer.web_workspace import WebWorkspace
        workspace=WebWorkspace();self.addCleanup(workspace.close)
        workspace.paths={'surface':FIXTURE}
        workspace.configure({'image':{'title':LONG,'show_colorbar':False}})
        workspace.render(canvas_size=(1800,800))
        notices=[];workspace.on_canvas_warning=notices.append
        window=workspace.plotter.render_window
        errors=io.StringIO()
        with contextlib.redirect_stderr(errors):
            for ratio in (1,2):
                workspace.set_screen_ratio(ratio)
                window.SetSize(120*ratio,600*ratio)
                self.assertFalse(workspace.renderer.title_actor.GetVisibility())
                self.assertIn('temporarily hidden',notices[-1])
                window.SetSize(1800*ratio,800*ratio)
                self.assertTrue(workspace.renderer.title_actor.GetVisibility())
                self.assertEqual(notices[-1],'')
        self.assertNotIn('Traceback',errors.getvalue())

    def test_web_apply_validates_browser_size_before_old_window_commit(self):
        import test_web_view_lifecycle as lifecycle
        harness=lifecycle.ViewLifecycleTests();harness.setUp();self.addCleanup(harness.tearDown)
        workspace=harness.workspace;state=harness.server.state
        workspace.root=FIXTURE.parent.resolve()
        workspace.catalog['surface']['test-surface']=FIXTURE
        state.surface='test-surface';state.title='Original title'
        harness.actions['apply']()
        self.assertEqual(state.error,'')
        window=workspace.plotter.render_window;window.SetSize(480,1200)
        old=workspace.renderer;old_settings=deepcopy(workspace.settings)
        before=workspace.plotter.screenshot(return_img=True)
        state.title=LONG
        harness.actions['apply']()
        self.assertIn('complete title',state.error)
        self.assertTrue(state.rendered)
        self.assertIs(workspace.renderer,old)
        self.assertIs(workspace.plotter.render_window,window)
        self.assertEqual(workspace.settings,old_settings)
        np.testing.assert_array_equal(workspace.plotter.screenshot(return_img=True),before)


if __name__=='__main__':unittest.main()

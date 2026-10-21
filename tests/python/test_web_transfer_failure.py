# SPDX-License-Identifier: GPL-3.0-or-later
"""Associated native-window handoff failures, with real VTK rendering on retry."""
from copy import deepcopy
from pathlib import Path
import unittest
from unittest.mock import patch
import pyvista as pv
from pyvista.plotting.render_window_interactor import RenderWindowInteractor
import test_web_view_lifecycle as lifecycle


class TransferFailureTests(unittest.TestCase):
    def probe(self, stage):
        baseline=set(pv.plotting.plotter._ALL_PLOTTERS)
        harness=lifecycle.ViewLifecycleTests(); harness.setUp(); workspace=harness.workspace
        # create_app owns a separate empty placeholder until its remote view is
        # bound. It is released by actions.close(), not by workspace.render().
        with_placeholder=set(pv.plotting.plotter._ALL_PLOTTERS)
        retired=[]; retire=workspace.retire_view
        def retire_record(window):
            retired.append(window); retire(window)
        workspace.retire_view=retire_record
        workspace.paths={'surface':Path(__file__).parents[1]/'fixtures/cross-platform-v0.1/tetrahedron.nv'}
        try:
            workspace.render(); old=workspace.plotter.render_window; old.Render()
            old_id=harness.objects.GetGlobalId(old)
            raw=harness.core.StillRenderToBuffer(old,0,100)
            self.assertGreater(raw.GetNumberOfValues(),10)
            workspace.pending_session=None
            workspace.configure({'image':{'title':'Retry handoff'}})
            if stage=='layers':
                original=old.AddRenderer
                def fail(layer):
                    original(layer)
                    raise RuntimeError('injected layers')
                injection=patch.object(old,'AddRenderer',side_effect=fail)
            elif stage=='interactor':
                original=RenderWindowInteractor.set_render_window
                def fail(interactor,window):
                    original(interactor,window)
                    if window is old: raise RuntimeError('injected interactor')
                injection=patch.object(RenderWindowInteractor,'set_render_window',fail)
            else:
                def fail(value):
                    if value is workspace.settings: raise RuntimeError('injected commit')
                    return deepcopy(value)
                injection=patch('brainnet_viewer.web_workspace.deepcopy',side_effect=fail)
            with injection, self.assertRaisesRegex(RuntimeError,'injected '+stage): workspace.render()
            self.assertIsNone(workspace.plotter)
            self.assertIsNone(workspace.renderer)
            self.assertIsNone(workspace._retained_window)
            self.assertIsNone(workspace.render_settings)
            self.assertIsNone(workspace.render_paths)
            self.assertEqual(old.GetRenderers().GetNumberOfItems(),0)
            self.assertEqual(sum(w is old for w in retired),1)
            self.assertIsNone(harness.objects.GetVTKObject(old_id))
            self.assertEqual(len(harness.core.images),0)
            self.assertEqual(set(pv.plotting.plotter._ALL_PLOTTERS),with_placeholder)
            workspace.render()
            image=workspace.plotter.screenshot(return_img=True)
            self.assertGreater(int(image.max())-int(image.min()),10)
            self.assertIsNot(workspace.plotter.render_window,old)
            harness.tearDown()
            self.assertEqual(set(pv.plotting.plotter._ALL_PLOTTERS),baseline)
        finally:
            harness.tearDown()
            # Clean leaked staging objects on the original unfixed code only.
            for key,plot in list(pv.plotting.plotter._ALL_PLOTTERS.items()):
                if key not in baseline: plot.close()

    def test_layer_transfer_failure(self): self.probe('layers')
    def test_interactor_binding_failure(self): self.probe('interactor')
    def test_final_commit_failure(self): self.probe('commit')

    def test_apply_action_restores_placeholder_and_retries(self):
        harness=lifecycle.ViewLifecycleTests(); harness.setUp()
        workspace=harness.workspace; state=harness.server.state
        try:
            fixture=Path(__file__).parents[1]/'fixtures/cross-platform-v0.1/tetrahedron.nv'
            workspace.root=fixture.parent.resolve()
            workspace.catalog['surface']['test-surface']=fixture
            state.surface='test-surface'
            harness.actions['apply']()
            self.assertEqual(state.error,''); self.assertTrue(state.rendered)
            old=workspace.plotter.render_window
            generation=state.view_generation
            original=old.AddRenderer
            def fail(layer):
                original(layer); raise RuntimeError('injected action transfer')
            with patch.object(old,'AddRenderer',side_effect=fail): harness.actions['apply']()
            self.assertIn('injected action transfer',state.error)
            self.assertFalse(state.rendered); self.assertFalse(state.boundary_ready)
            self.assertEqual(state.inspect_text,'')
            self.assertGreater(state.view_generation,generation)
            self.assertIsNone(workspace.plotter)
            self.assertEqual(state.surface,'test-surface')
            harness.actions['apply']()
            self.assertEqual(state.error,''); self.assertTrue(state.rendered)
            self.assertIsNot(workspace.plotter.render_window,old)
            image=workspace.plotter.screenshot(return_img=True)
            self.assertGreater(int(image.max())-int(image.min()),10)
        finally: harness.tearDown()

if __name__=='__main__': unittest.main()

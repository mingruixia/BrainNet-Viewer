# SPDX-License-Identifier: GPL-3.0-or-later
"""Pinned VTK/Trame lifecycle: real native objects, no native GUI acceptance."""
import unittest
import uuid
from trame.app import get_server
from wslink.websocket import ServerProtocol
from vtkmodules.vtkRenderingCore import vtkRenderWindow, vtkRenderer, vtkActor
from trame_vtk.modules.vtk.protocols.publish_image_delivery import vtkWebPublishImageDelivery
from brainnet_viewer.web_app import create_app


class ViewLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.server, self.workspace, self.actions = create_app(
            get_server('lifecycle-' + uuid.uuid4().hex, client_type='vue3'))
        self.root = ServerProtocol()
        for configure in self.server._protocols_to_configure:
            configure(self.root)
        self.delivery = next(p for p in self.root.getLinkProtocols()
                             if isinstance(p, vtkWebPublishImageDelivery))
        self.core = self.root.getSharedObject('app')
        self.objects = self.core.GetObjectIdMap()

    def tearDown(self):
        self.actions['close']()
        self.actions['close']()  # exit callbacks can follow an explicit close

    def test_retired_callbacks_cannot_touch_new_view(self):
        old, new = vtkRenderWindow(), vtkRenderWindow()
        old_id = str(self.objects.GetGlobalId(old))
        new_id = str(self.objects.GetGlobalId(new))
        self.objects.SetActiveObject('VIEW', new)
        tags = [self.core.AddObserver('UpdateEvent', lambda *_: None)]
        self.delivery.tracking_views[old_id] = {'tags': tags, 'observerCount': 2}
        self.delivery.tracking_views[new_id] = {'tags': [], 'observerCount': 1, 'quality': 100, 'ratio': 2}
        self.delivery.last_stale_time[old_id] = 1
        self.delivery.stale_handler_count[old_id] = 1
        self.delivery.views_in_animations[:] = [old_id, old_id, new_id]
        self.workspace.retire_view(old)
        self.assertIsNone(self.objects.GetVTKObject(int(old_id)))
        self.assertNotIn(old_id, self.delivery.tracking_views)
        self.assertNotIn(old_id, self.delivery.last_stale_time)
        self.assertNotIn(old_id, self.delivery.stale_handler_count)
        self.assertEqual(self.delivery.views_in_animations, [new_id])
        self.assertEqual(self.delivery.remove_render_observer(old_id), {'result': 'success'})
        self.assertIn('error', self.delivery.set_view_quality(old_id, 1, .1))
        self.assertIn('error', self.delivery.set_view_size(old_id, 20, 20))
        self.assertIn('error', self.delivery.start_view_animation(old_id))
        self.delivery.render_stale_image(old_id)
        self.assertEqual(self.delivery.get_view_quality(new_id), {'quality': 100, 'ratio': 2})
        self.assertEqual(self.delivery.tracking_views[new_id]['observerCount'], 1)
        self.assertIs(self.delivery.get_view('-1'), new)
        self.workspace.retire_view(new)

    def test_every_vtk_rpc_is_guarded_and_registration_preserved(self):
        from brainnet_viewer.web_view_lifecycle import _UnavailableView
        for protocol in self.root.getLinkProtocols():
            if not hasattr(protocol, 'get_view'):
                continue
            with self.assertRaises(_UnavailableView):
                protocol.get_view('999999')
            for name in dir(protocol):
                method = getattr(type(protocol), name, None)
                if callable(method) and hasattr(method, '_wslinkuris'):
                    self.assertTrue(hasattr(method, '__wrapped__'), name)
        # Exercise the class-level dispatch used by wslink, not just a bound call.
        self.assertEqual(type(self.delivery).remove_render_observer(self.delivery, '999999'), {'result': 'success'})

    def test_close_releases_layers_outside_pyvista_collection(self):
        import pyvista as pv
        plot = pv.Plotter(off_screen=True)
        window = plot.render_window
        extra = vtkRenderer()
        extra.AddActor(vtkActor())
        window.AddRenderer(extra)
        key = self.objects.GetGlobalId(window)
        self.workspace.plotter = plot
        self.workspace.close_render()
        self.assertEqual(window.GetRenderers().GetNumberOfItems(), 0)
        self.assertEqual(extra.GetViewProps().GetNumberOfItems(), 0)
        self.assertIsNone(self.objects.GetVTKObject(key))
        self.assertIsNone(self.workspace.plotter)

    def test_native_image_cache_is_released_with_each_window(self):
        import pyvista as pv
        from vtkmodules.vtkWebCore import vtkWebApplication
        for _ in range(3):
            plot = pv.Plotter(off_screen=True, window_size=(32, 32))
            plot.set_background('white')
            window = plot.render_window
            try:
                raw = self.core.StillRenderToBuffer(window, 0, 100)
                self.assertGreater(raw.GetNumberOfValues(), 10)
                self.assertEqual(len(self.core.images), 1)
                self.assertGreater(self.core.GetLastStillRenderToMTime(), 0)
                reference = vtkWebApplication(); reference.SetImageEncoding(0)
                expected = reference.StillRenderToBuffer(window, 0, 100)
                self.assertEqual(bytes(raw), bytes(expected))
                self.workspace.retire_view(window)
                self.assertEqual(len(self.core.images), 0)
                del reference, raw, expected
            finally:
                plot.close(); plot.deep_clean()

    def test_sampling_changes_fit_once_with_matching_dpi(self):
        from pathlib import Path
        w=self.workspace
        w.paths={'surface': Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv'}
        w.configure({'image': {'title': 'Linux GPU 验证 — Schaefer100 / Yeo7'}})
        w.render(canvas_size=(631,387))
        window=w.plotter.render_window
        key=str(self.objects.GetGlobalId(window))
        self.delivery.add_render_observer(key)
        self.delivery.set_view_size(key,631,387)
        self.delivery.set_view_quality(key,100,2)
        messages=[]
        w.on_canvas_warning=messages.append
        self.actions['stream_start']()
        self.assertEqual((window.GetDPI(),w.screen_ratio),(144,2))
        self.delivery.set_view_quality(key,70,.65)
        self.assertEqual(window.GetSize(),(410,252))
        self.assertEqual(window.GetDPI(),47)
        self.assertEqual(w.screen_ratio,.65)
        self.actions['stream_end']()
        self.assertEqual((window.GetDPI(),w.screen_ratio),(47,.65))
        self.delivery.set_view_quality(key,100,2)
        self.assertEqual(window.GetSize(),(1262,774))
        self.assertEqual(window.GetDPI(),144)
        self.assertEqual(w.screen_ratio,2)
        self.assertFalse(any(messages),messages)
        self.assertTrue(w.renderer.title_actor.GetVisibility())

    def test_resize_during_dolly_preserves_event_coordinate_basis(self):
        from pathlib import Path
        from vtkmodules.vtkWebCore import vtkWebApplication, vtkWebInteractionEvent
        w=self.workspace
        w.paths={'surface': Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv'}
        w.render(canvas_size=(410,252))
        w.plotter.enable_custom_trackball_style(left='dolly')
        window=w.plotter.render_window
        w.plotter.screenshot(return_img=True)
        app=vtkWebApplication()
        event=vtkWebInteractionEvent()
        event.SetX(.21077654516640254); event.SetY(.21059431524547803)
        event.SetButtons(vtkWebInteractionEvent.LEFT_BUTTON)
        app.HandleInteractionEvent(window,event)
        self.assertEqual(window.GetInteractor().GetInteractorStyle().GetState(),4)
        self.assertEqual(window.GetInteractor().GetEventPosition(),(86,53))
        before=w.renderer.capture_camera()['views'][0]['zoom_factor']
        window.SetSize(410,121)
        self.assertEqual(window.GetInteractor().GetEventPosition(),(86,25))
        event.SetY(.2054263565891473)
        app.HandleInteractionEvent(window,event)
        self.assertEqual(w.renderer.capture_camera()['views'][0]['zoom_factor'],before)
        event.SetButtons(0); app.HandleInteractionEvent(window,event)

    def test_initial_stream_placeholder_cannot_replace_committed_frame(self):
        from unittest.mock import patch
        window=vtkRenderWindow()
        key=str(self.objects.GetGlobalId(window))
        try:
            with patch.object(self.delivery,'still_render',return_value={'stale':False,'image':None}) as render:
                self.delivery.add_render_observer(key)
                self.delivery.set_view_size(key,631,387)
                self.delivery.set_view_quality(key,5,.1)
                self.delivery.push_render(key)
                render.assert_not_called()
                self.delivery.set_view_quality(key,100,2)
                self.delivery.push_render(key)
                self.assertEqual(render.call_args.args[0]['size'],[1262,774])
                self.assertEqual(render.call_args.args[0]['quality'],100)
                self.delivery.set_view_quality(key,5,.1)
                self.assertEqual(window.GetSize(),(1262,774))
                self.assertEqual(self.delivery.get_view_quality(key),{'quality':100,'ratio':2})
                self.delivery.set_view_quality(key,70,.65)
                self.assertEqual(window.GetSize(),(410,252))
                self.delivery.remove_render_observer(key)
                self.assertNotIn(key,self.delivery._brainnet_quality_ready)
                self.assertNotIn(key,self.delivery._brainnet_size_ready)
        finally:
            w=self.workspace
            w.retire_view(window)
            window.Finalize()

    def test_apply_layout_clear_and_failure_keep_one_native_context(self):
        from pathlib import Path
        from unittest.mock import patch
        from brainnet_viewer.rendering import SceneRenderer
        w=self.workspace
        w.paths={'surface': Path(__file__).parents[1] / 'fixtures/cross-platform-v0.1/tetrahedron.nv'}
        w.render()
        window=w.plotter.render_window
        window.Render()
        key=self.objects.GetGlobalId(window)
        for preset in (2, 1, 2):
            w.configure({'layout': {'preset': preset}})
            w.render()
            self.assertIs(w.plotter.render_window, window)
            self.assertEqual(self.objects.GetGlobalId(window), key)
            window.Render()
        before=w.renderer.capture_camera()
        size=window.GetSize(); dpi=window.GetDPI()
        w.export_files(320, 240, 200, True)
        self.assertEqual(w.renderer.capture_camera(), before)
        self.assertEqual(window.GetSize(), size)
        self.assertEqual(window.GetDPI(), dpi)
        original=w.renderer
        with patch.object(SceneRenderer, 'render', side_effect=ValueError('staging failed')):
            with self.assertRaisesRegex(ValueError, 'staging failed'): w.render()
        self.assertIs(w.renderer, original)
        self.assertEqual(w.renderer.capture_camera(), before)
        # Clear leaves no actors, but does not destroy the drawing context.
        w.close_render(preserve_window=True)
        self.assertEqual(window.GetRenderers().GetNumberOfItems(), 0)
        w.render()
        self.assertIs(w.plotter.render_window, window)
        w.close_render()
        self.assertIsNone(self.objects.GetVTKObject(key))


if __name__ == '__main__':
    unittest.main()

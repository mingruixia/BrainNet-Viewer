# SPDX-License-Identifier: GPL-3.0-or-later
"""Retire remote VTK views without redirecting late client events to a new view.

This adapter is deliberately local to one server. The pinned trame-vtk helper
keeps native windows in its object map; closing a PyVista plotter is not enough.
Protocol customization runs before any WebSocket RPC methods are registered.
"""
from functools import wraps, lru_cache


class _UnavailableView(Exception):
    pass


class _ImageApplication:
    """Stable public view IDs with a disposable native image cache per window.

    VTK 9.7.1 keeps image/encoder caches for every window ever rendered and has
    no per-view eviction API. Separate image applications let retirement release
    those native caches without resetting IDs or changing JPEG/PNG encoding.
    The outer application continues to own protocol observers and public IDs.
    """
    def __init__(self, application):
        self.application = application
        self.images = {}
        self.last_mtime = 0

    def __getattr__(self, name):
        return getattr(self.application, name)

    def _image_app(self, window):
        key = self.GetObjectIdMap().GetGlobalId(window)
        if key not in self.images:
            from vtkmodules.vtkWebCore import vtkWebApplication
            image_app = vtkWebApplication()
            image_app.SetImageEncoding(self.GetImageEncoding())
            image_app.SetImageCompression(self.GetImageCompression())
            image_app.SetNumberOfEncoderThreads(self.GetNumberOfEncoderThreads())
            self.images[key] = image_app
        return self.images[key]

    def InvalidateCache(self, window):
        self._image_app(window).InvalidateCache(window)

    def GetHasImagesBeingProcessed(self, window):
        return self._image_app(window).GetHasImagesBeingProcessed(window)

    def GetLastStillRenderToMTime(self):
        return self.last_mtime

    def StillRenderToBuffer(self, window, *args):
        app = self._image_app(window)
        result = app.StillRenderToBuffer(window, *args)
        self.last_mtime = app.GetLastStillRenderToMTime()
        return result

    def StillRenderToString(self, window, *args):
        app = self._image_app(window)
        result = app.StillRenderToString(window, *args)
        self.last_mtime = app.GetLastStillRenderToMTime()
        return result

    def StillRender(self, window, *args):
        return self._image_app(window).StillRender(window, *args)

    def InteractiveRender(self, window, *args):
        return self._image_app(window).InteractiveRender(window, *args)

    def HandleInteractionEvent(self, window, event):
        return self._image_app(window).HandleInteractionEvent(window, event)

    def retire_image(self, window):
        key = self.GetObjectIdMap().GetGlobalId(window)
        app = self.images.pop(key, None)
        if app is not None:
            # The native cache installs an AnyEvent listener pointing into its
            # own storage. Detach it before destroying the cache. This window
            # has already been retired and will never receive another event.
            window.RemoveObservers('AnyEvent')
            app.GetObjectIdMap().FreeObject(window)


def _strict_view(protocol, view_id):
    numeric = int(view_id)
    if numeric > 0:
        view = protocol.app.GetObjectIdMap().GetVTKObject(numeric)
        if view is None:
            raise _UnavailableView(f'View {numeric} is no longer available.')
        return view
    # Keep the SDK's explicit active-view convention, but never fall back for
    # a positive ID belonging to a retired window.
    view = protocol.app.GetObjectIdMap().GetActiveObject('VIEW')
    if view is None:
        raise _UnavailableView('No active view.')
    return view


def _guard_rpc(method):
    @wraps(method)
    def guarded(*args, **kwargs):
        try:
            return method(*args, **kwargs)
        except _UnavailableView as error:
            # Vue can unsubscribe the old component after Apply has retired it.
            # A late unsubscribe is idempotent; other stale events are rejected.
            if method.__name__ == 'remove_render_observer':
                return {'result': 'success'}
            return {'error': str(error)}
    return guarded


@lru_cache(maxsize=8)
def _guarded_protocol(base):
    methods = {'get_view': _strict_view}
    for name in dir(base):
        method = getattr(base, name)
        if callable(method) and hasattr(method, '_wslinkuris'):
            methods[name] = _guard_rpc(method)
    return type('BrainNet' + base.__name__, (base,), methods)


class RemoteViewLifecycle:
    def __init__(self, server):
        from trame_vtk.modules.vtk import get_helper
        self.helper = get_helper(server)
        self.helper._vtk_core = _ImageApplication(self.helper._vtk_core)
        self.protocols = []
        server.add_protocol_to_configure(self.configure)

    def configure(self, root):
        from trame_vtk.modules.vtk.protocols.web_protocol import vtkWebProtocol
        self.protocols = [p for p in root.getLinkProtocols() if isinstance(p, vtkWebProtocol)]
        for protocol in self.protocols:
            # wslink discovers RPCs on the class, not on the instance. Use a
            # private subclass for these server-owned instances; SDK classes
            # and other servers remain untouched. Preserve initialized state.
            protocol.__class__ = _guarded_protocol(type(protocol))

    def retire(self, window):
        if window is None:
            return
        core = self.helper._vtk_core
        objects = core.GetObjectIdMap()
        view_id = str(objects.GetGlobalId(window))
        for protocol in self.protocols:
            tracking = getattr(protocol, 'tracking_views', {})
            info = tracking.pop(view_id, None)
            if info:
                for tag in info['tags']:
                    core.RemoveObserver(tag)
            for name in ('last_stale_time', 'stale_handler_count'):
                getattr(protocol, name, {}).pop(view_id, None)
            animations = getattr(protocol, 'views_in_animations', [])
            animations[:] = [item for item in animations if item != view_id]
        if objects.GetActiveObject('VIEW') == window:
            objects.SetActiveObject('VIEW', None)
        core.retire_image(window)
        objects.FreeObjectById(int(view_id))

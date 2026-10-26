# SPDX-License-Identifier: GPL-3.0-or-later
"""Retire remote VTK views without redirecting late client events to a new view.

This adapter is deliberately local to one server. The pinned trame-vtk helper
keeps native windows in its object map; closing a PyVista plotter is not enough.
Protocol customization runs before any WebSocket RPC methods are registered.
"""
from functools import wraps, lru_cache
from contextlib import nullcontext


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
    from trame_vtk.modules.vtk.protocols.publish_image_delivery import vtkWebPublishImageDelivery
    if issubclass(base,vtkWebPublishImageDelivery):
        @wraps(base.set_view_quality)
        def quality(self,view_id,quality,ratio=1):
            window=self.get_view(view_id)
            key=str(self.get_global_id(window))
            if key not in self.tracking_views:
                return base.set_view_quality(self,view_id,quality,ratio)
            # The pinned client sends this placeholder while mounting. It must
            # not replace a committed frame or resize an already shared window.
            if quality==5 and ratio==.1: return {'result':'success'}
            workspace=self._brainnet_workspace
            transaction=(workspace.screen_sampling(ratio) if workspace and workspace.plotter
                         and workspace.plotter.render_window is window else nullcontext())
            self._brainnet_sampling.add(key)
            try:
                with transaction:
                    result=base.set_view_quality(self,view_id,quality,ratio)
                if result.get('result')=='success': self._brainnet_quality_ready.add(key)
                return result
            finally: self._brainnet_sampling.discard(key)

        @wraps(base.set_view_size)
        def size(self,view_id,width,height):
            result=base.set_view_size(self,view_id,width,height)
            if result.get('result')=='success' and width>10 and height>10:
                self._brainnet_size_ready.add(str(self.get_global_id(self.get_view(view_id))))
            return result

        @wraps(base.remove_render_observer)
        def remove(self,view_id):
            key=str(self.get_global_id(self.get_view(view_id)))
            result=base.remove_render_observer(self,view_id)
            if key not in self.tracking_views:
                self._brainnet_quality_ready.discard(key)
                self._brainnet_size_ready.discard(key)
            return result

        @wraps(base.push_render)
        def push(self,v_id,*args,**kwargs):
            if (v_id not in self._brainnet_quality_ready or v_id not in self._brainnet_size_ready
                    or v_id in self._brainnet_sampling): return
            return base.push_render(self,v_id,*args,**kwargs)

        methods.update(set_view_quality=_guard_rpc(quality),set_view_size=_guard_rpc(size),
                       remove_render_observer=_guard_rpc(remove),push_render=push)
    return type('BrainNet' + base.__name__, (base,), methods)


class RemoteViewLifecycle:
    def __init__(self, server, workspace=None):
        from trame_vtk.modules.vtk import get_helper
        self.helper = get_helper(server)
        self.helper._vtk_core = _ImageApplication(self.helper._vtk_core)
        self.protocols = []
        self.workspace = workspace
        server.add_protocol_to_configure(self.configure)

    def configure(self, root):
        from trame_vtk.modules.vtk.protocols.web_protocol import vtkWebProtocol
        self.protocols = [p for p in root.getLinkProtocols() if isinstance(p, vtkWebProtocol)]
        for protocol in self.protocols:
            # wslink discovers RPCs on the class, not on the instance. Use a
            # private subclass for these server-owned instances; SDK classes
            # and other servers remain untouched. Preserve initialized state.
            protocol.__class__ = _guarded_protocol(type(protocol))
            if hasattr(protocol,'tracking_views'):
                protocol._brainnet_workspace=self.workspace
                protocol._brainnet_quality_ready=set()
                protocol._brainnet_size_ready=set()
                protocol._brainnet_sampling=set()

    def retire(self, window):
        if window is None:
            return
        core = self.helper._vtk_core
        objects = core.GetObjectIdMap()
        view_id = str(objects.GetGlobalId(window))
        for protocol in self.protocols:
            tracking = getattr(protocol, 'tracking_views', {})
            info = tracking.pop(view_id, None)
            for name in ('_brainnet_quality_ready','_brainnet_size_ready','_brainnet_sampling'):
                getattr(protocol,name,set()).discard(view_id)
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

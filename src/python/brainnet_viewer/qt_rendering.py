# SPDX-License-Identifier: GPL-3.0-or-later
"""Platform-specific Qt/VTK integration without changing third-party packages."""
import sys
from pyvistaqt import QtInteractor as _QtInteractor


class QtInteractor(_QtInteractor):
    """Supply the native Windows resolver to the FBO-backed VTK window.

    PyVistaQt's GLX/EGL symbol-loader path does not load Windows symbols.
    VTK also needs opengl32's handle for core OpenGL 1.1 entry points that
    wglGetProcAddress does not return. Keep that library alive with the widget.
    Other platforms retain the upstream integration unchanged.
    """

    def _set_symbol_loader(self, render_window):
        if sys.platform != 'win32':
            return super()._set_symbol_loader(render_window)
        import ctypes
        library = getattr(self, '_brainnet_opengl32', None)
        if library is None:
            # Search the Windows system directory, never the working directory.
            library = ctypes.WinDLL('opengl32.dll', winmode=0x800)
            self._brainnet_opengl32 = library
        resolver = ctypes.cast(library.wglGetProcAddress, ctypes.c_void_p).value
        if not resolver or not library._handle:
            raise RuntimeError('Windows desktop OpenGL functions could not be loaded.')
        render_window.SetOpenGLSymbolLoader2(resolver, library._handle)

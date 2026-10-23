# SPDX-License-Identifier: GPL-3.0-or-later
"""Focused resolver contract checks; native drawing is tested separately."""
import importlib.util
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


@unittest.skipUnless(sys.platform == 'win32' and importlib.util.find_spec('PySide6'),
                     'Windows Qt resolver contract')
class WindowsResolverTests(unittest.TestCase):
    def test_windows_resolver_and_core_library_handle_are_both_supplied(self):
        from brainnet_viewer.qt_rendering import QtInteractor
        host = SimpleNamespace()
        window = Mock()
        library = SimpleNamespace(_handle=456, wglGetProcAddress=object())
        with patch('ctypes.WinDLL', return_value=library) as load, \
                patch('ctypes.cast', return_value=SimpleNamespace(value=123)):
            QtInteractor._set_symbol_loader(host, window)
            QtInteractor._set_symbol_loader(host, window)
        load.assert_called_once_with('opengl32.dll', winmode=0x800)
        self.assertIs(host._brainnet_opengl32, library)
        self.assertEqual(window.SetOpenGLSymbolLoader2.call_count, 2)
        window.SetOpenGLSymbolLoader2.assert_called_with(123, 456)

    def test_empty_resolver_rejects_initialization(self):
        from brainnet_viewer.qt_rendering import QtInteractor
        window = Mock()
        library = SimpleNamespace(_handle=456, wglGetProcAddress=object())
        with patch('ctypes.WinDLL', return_value=library), \
                patch('ctypes.cast', return_value=SimpleNamespace(value=0)):
            with self.assertRaisesRegex(RuntimeError, 'OpenGL functions'):
                QtInteractor._set_symbol_loader(SimpleNamespace(), window)
        window.SetOpenGLSymbolLoader2.assert_not_called()

    def test_library_load_failure_is_not_silently_ignored(self):
        from brainnet_viewer.qt_rendering import QtInteractor
        window = Mock()
        with patch('ctypes.WinDLL', side_effect=OSError('controlled system library failure')):
            with self.assertRaisesRegex(OSError, 'controlled'):
                QtInteractor._set_symbol_loader(SimpleNamespace(), window)
        window.SetOpenGLSymbolLoader2.assert_not_called()

    def test_other_platform_delegates_to_upstream(self):
        from PySide6 import QtWidgets
        from brainnet_viewer.qt_rendering import QtInteractor, _QtInteractor
        app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
        widget = QtInteractor(auto_update=False)
        try:
            window = Mock()
            with patch('brainnet_viewer.qt_rendering.sys.platform', 'linux'), \
                    patch.object(_QtInteractor, '_set_symbol_loader', autospec=True,
                                 return_value='upstream') as original:
                self.assertEqual(widget._set_symbol_loader(window), 'upstream')
                original.assert_called_once_with(widget, window)
        finally:
            widget.close()
            app.processEvents()


if __name__ == '__main__':
    unittest.main()

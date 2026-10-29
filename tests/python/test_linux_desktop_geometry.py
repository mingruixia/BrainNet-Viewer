"""Linux shell branch contract; host compositor acceptance is separate."""
import sys
import importlib.util
import unittest
from unittest.mock import patch
if not all(importlib.util.find_spec(name) is not None for name in ('PySide6', 'pyvistaqt')):
    raise unittest.SkipTest('Fixed desktop extra is not installed')
from PySide6 import QtCore, QtWidgets as W, QtTest
from brainnet_viewer.desktop import BrainNetWindow


class LinuxShellTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.qt=W.QApplication.instance() or W.QApplication([])

    def test_small_work_area_keeps_footer_and_file_actions_reachable(self):
        with patch.object(sys,'platform','linux'):
            window=BrainNetWindow()
        window.resize(1100,650); window.show(); QtTest.QTest.qWait(100)
        try:
            self.assertIsInstance(window.centralWidget(),W.QScrollArea)
            self.assertLessEqual(window.statusBar().geometry().bottom(),window.height())
            self.assertFalse(window.canvas_host.testAttribute(QtCore.Qt.WA_NativeWindow))
            scroll=window.workspace_scroll
            for role in ('surface','node','edge','surface_map','volume','scene'):
                control=window.role_buttons[role]
                ancestor=control.parentWidget()
                while ancestor is not None:
                    if isinstance(ancestor,W.QScrollArea): ancestor.ensureWidgetVisible(control)
                    ancestor=ancestor.parentWidget()
                self.qt.processEvents()
                position=control.mapTo(window,control.rect().center())
                self.assertIs(window.childAt(position),control,role)
                with patch.object(W.QFileDialog,'getOpenFileName',return_value=('','')) as chooser:
                    QtTest.QTest.mouseClick(window.windowHandle(),QtCore.Qt.LeftButton,pos=position)
                    self.qt.processEvents()
                    chooser.assert_called_once()
                    self.assertIn('Scene' if role=='scene' else role.replace('_',' '),chooser.call_args.args[1])
            add=next(b for b in window.findChildren(W.QPushButton) if b.text()=='Add Files')
            ancestor=add.parentWidget()
            while ancestor is not None:
                if isinstance(ancestor,W.QScrollArea): ancestor.ensureWidgetVisible(add)
                ancestor=ancestor.parentWidget()
            self.qt.processEvents()
            with patch.object(W.QFileDialog,'getOpenFileNames',return_value=([],'')) as chooser:
                QtTest.QTest.mouseClick(window.windowHandle(),QtCore.Qt.LeftButton,pos=add.mapTo(window,add.rect().center()))
                self.qt.processEvents(); chooser.assert_called_once()
        finally: window.close(); self.qt.processEvents()


if __name__=='__main__': unittest.main()

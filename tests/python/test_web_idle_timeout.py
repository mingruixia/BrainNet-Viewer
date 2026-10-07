"""Container lifetime routing only; no rendering or browser regression."""
import unittest
from unittest.mock import Mock, patch
from brainnet_viewer.web_app import main


class WebIdleTimeoutTests(unittest.TestCase):
    def test_container_disables_idle_timeout(self):
        server = Mock()
        with patch('brainnet_viewer.web_app.create_app', return_value=(server, None, None)):
            main(['--container', '--host', '0.0.0.0'])
        server.start.assert_called_once_with(
            host='0.0.0.0', port=1031, open_browser=False, timeout=0)

    def test_noncontainer_retains_library_default(self):
        server = Mock()
        with patch('brainnet_viewer.web_app.create_app', return_value=(server, None, None)):
            main([])
        server.start.assert_called_once_with(
            host='127.0.0.1', port=1031, open_browser=False, timeout=None)

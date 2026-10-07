"""Real Trame exit-controller callback; no scene rendering regression."""
import unittest
import uuid
from trame.app import get_server
from brainnet_viewer.web_app import create_app


class WebShutdownTests(unittest.TestCase):
    def test_exit_state_keywords_release_owned_workspaces(self):
        server,w,a=create_app(get_server('shutdown-'+uuid.uuid4().hex,client_type='vue3'))
        scratch,assets=w.scratch,w.assets
        self.assertTrue(scratch.is_dir()); self.assertTrue(assets.is_dir())
        server.controller.on_server_exited(trame__scripts=[],trame__server_ready=False)
        self.assertFalse(scratch.exists()); self.assertFalse(assets.exists())

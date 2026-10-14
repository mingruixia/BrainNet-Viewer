# SPDX-License-Identifier: GPL-3.0-or-later
"""Fail-closed client/bootstrap guards, not a replacement for live socket tests."""
import unittest
from unittest.mock import patch
from unittest.mock import Mock
from types import SimpleNamespace
from pathlib import Path
import tempfile
from brainnet_viewer.web_security import CLIENT_VERSIONS,require_client_versions,permitted

class SecurityContractTests(unittest.TestCase):
    def test_client_version_guard(self):
        with patch('brainnet_viewer.web_security.version',side_effect=lambda name:CLIENT_VERSIONS[name]):require_client_versions()
        with patch('brainnet_viewer.web_security.version',return_value='999.0'):
            with self.assertRaises(RuntimeError):require_client_versions()

    def test_authority_and_required_origin(self):
        for host,origin in [('evil.invalid','http://evil.invalid'),('127.0.0.1:1031',None),('127.0.0.1:1031','http://127.0.0.1:1032'),('user@localhost:1031','http://localhost:1031')]:
            self.assertFalse(permitted(host,origin,require_origin=True))
        self.assertTrue(permitted('127.0.0.1:1031','http://127.0.0.1:1031',require_origin=True))

    def test_unsupported_bootstrap_or_protocol_fails_closed(self):
        from aiohttp import web
        from brainnet_viewer.web_security import install
        for valid_protocol in (True,False):
            with tempfile.TemporaryDirectory() as folder:
                Path(folder,'index.html').write_text('<html>unsupported client</html>')
                signal=Mock()
                server=SimpleNamespace(cli=Mock(),controller=SimpleNamespace(on_server_bind=signal),
                    protocol=SimpleNamespace(updateSecret=Mock()) if valid_protocol else SimpleNamespace(),_www=folder)
                install(server);bind=signal.add.call_args.args[0]
                with self.assertRaises(RuntimeError):bind(SimpleNamespace(app=web.Application()))

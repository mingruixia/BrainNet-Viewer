import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from brainnet_viewer.web_help import render_page, prepare_help

class HelpLinkTests(unittest.TestCase):
    def test_fragment_links_and_safe_explicit_anchors(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder).resolve();source=root/"README.md"
            html=render_page('<a id="security"></a>\n[Policy](#security)\n[Other](OTHER.md#licence)',source,root)
            self.assertIn('<a id="security"></a>',html)
            self.assertIn('href="#security"',html)
            self.assertIn('href="/bnv-help-pages/OTHER.html#licence"',html)
    def test_directory_and_unsafe_links_stay_plain(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder).resolve();source=root/"README.md"
            text='[Root](.) [Outside](../escape.md) [Remote](//evil.invalid/path) [Script](javascript:alert) <script>alert</script>'
            html=render_page(text,source,root)
            self.assertNotIn('href="//evil',html)
            self.assertNotIn('href="javascript',html)
            self.assertNotIn('escape.md',html)
            self.assertIn('&lt;script&gt;',html)
    def test_entire_bundled_help_can_be_prepared(self):
        documentation=Path(__file__).resolve().parents[2]/"src/python/brainnet_viewer/resources/documentation"
        with tempfile.TemporaryDirectory() as folder:
            scratch=Path(folder);enabled=[]
            server=SimpleNamespace(enable_module=enabled.append)
            workspace=SimpleNamespace(root=documentation.parent,scratch=scratch)
            self.assertTrue(prepare_help(server,workspace))
            readme=(scratch/"help-pages/README.html").read_text(encoding="utf-8")
            notices=(scratch/"help-pages/THIRD_PARTY_NOTICES.html").read_text(encoding="utf-8")
            self.assertIn('id="security"',readme)
            self.assertIn('id="notice-1"',notices)
            self.assertTrue(enabled)

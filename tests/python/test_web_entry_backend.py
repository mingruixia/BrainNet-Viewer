# SPDX-License-Identifier: GPL-3.0-or-later
"""Entrypoint/process and backend invariants; never start a real service here."""
import os
import unittest
from unittest.mock import Mock,patch
from brainnet_viewer import web_backend as backend
from brainnet_viewer.web_app import main,cli

class EntryBackendTests(unittest.TestCase):
    def test_main_never_bootstraps_or_executes_process(self):
        server=Mock()
        with patch('brainnet_viewer.web_app.create_app',return_value=(server,None,None)),patch.object(backend,'bootstrap') as boot,patch.object(os,'execvpe') as execute:
            main(['--port','1071'])
        boot.assert_not_called();execute.assert_not_called()
        server.start.assert_called_once_with(host='127.0.0.1',port=1071,open_browser=False,timeout=None)

    def test_cli_bootstraps_but_invalid_bind_does_not_probe(self):
        with patch.object(backend,'bootstrap') as boot,patch('brainnet_viewer.web_app.main') as run:
            cli(['--port','1071'])
            boot.assert_called_once_with('brainnet_viewer.web_app',['--port','1071']);run.assert_called_once()
        with patch.object(backend,'bootstrap') as boot:
            with self.assertRaises(SystemExit):cli(['--host','evil.invalid'])
            with self.assertRaises(SystemExit):cli(['--port','0'])
            boot.assert_not_called()

    def test_inherited_bootstrap_marker_does_not_skip_probe(self):
        with patch.object(backend.sys,'platform','linux'),patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':'1'}),patch.object(backend,'configure_backend') as configure,patch.object(os,'execvpe') as execute:
            backend.bootstrap('brainnet_viewer.web_app',[])
            configure.assert_called_once();execute.assert_called_once()
            self.assertEqual(execute.call_args.args[2]['BNV_WEB_BOOTSTRAPPED'],str(os.getpid()))
        with patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':str(os.getpid())}),patch.object(backend,'configure_backend') as configure:
            backend.bootstrap('brainnet_viewer.web_app',[]);configure.assert_not_called()

    def test_nonlinux_cli_does_not_reexec(self):
        with patch.object(backend.sys,'platform','win32'),patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':'1'}),patch.object(backend,'configure_backend') as configure,patch.object(os,'execvpe') as execute:
            backend.bootstrap('brainnet_viewer.web_app',[])
            configure.assert_called_once();execute.assert_not_called()

    def test_wsl_adapter_is_optional_and_cpu_discards_it(self):
        with patch.object(backend.Path,'exists',return_value=True),patch.object(backend.Path,'is_file',return_value=True),patch.object(backend.Path,'is_dir',return_value=True):
            self.assertNotIn('MESA_D3D12_DEFAULT_ADAPTER_NAME',backend.driver_environment({}))
            env=backend.driver_environment({'MESA_D3D12_DEFAULT_ADAPTER_NAME':'Intel'})
            self.assertEqual(env['MESA_D3D12_DEFAULT_ADAPTER_NAME'],'Intel')
            self.assertNotIn('MESA_D3D12_DEFAULT_ADAPTER_NAME',backend.driver_environment(env,cpu=True))

    def test_software_detection_and_startup_fallback(self):
        for value in ('llvmpipe','softpipe','SwiftShader','Software Rasterizer',''):
            self.assertFalse(backend.hardware(value))
        self.assertTrue(backend.hardware('D3D12 (Intel Arc)'))
        completed=lambda device:Mock(returncode=0,stdout='{"device":"'+device+'","drawn":true}',stderr='')
        with patch.dict(os.environ,{},clear=True):
            record=backend.configure_backend('auto',run=Mock(side_effect=[completed('SwiftShader'),completed('llvmpipe')]))
            self.assertEqual(record['selected'],'cpu')
        with patch.dict(os.environ,{},clear=True):
            with self.assertRaises(RuntimeError):backend.configure_backend('gpu',run=Mock(return_value=completed('SwiftShader')))

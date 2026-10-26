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
        with patch.object(backend.sys,'platform','linux'),patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':str(os.getpid()+1)}),patch.object(backend,'configure_backend') as configure,patch.object(os,'execvpe') as execute:
            backend.bootstrap('brainnet_viewer.web_app',[])
            configure.assert_called_once();execute.assert_called_once()
            self.assertEqual(execute.call_args.args[2]['BNV_WEB_BOOTSTRAPPED'],str(os.getpid()))
        with patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':str(os.getpid())}),patch.object(backend,'configure_backend') as configure:
            backend.bootstrap('brainnet_viewer.web_app',[]);configure.assert_not_called()

    def test_nonlinux_cli_does_not_reexec(self):
        with patch.object(backend.sys,'platform','win32'),patch.dict(os.environ,{'BNV_WEB_BOOTSTRAPPED':str(os.getpid()+1)}),patch.object(backend,'configure_backend') as configure,patch.object(os,'execvpe') as execute:
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

    def test_linux_cpu_selects_mesa_egl(self):
        with patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=True):
            env=backend.driver_environment({},cpu=True)
        self.assertEqual(env['VTK_DEFAULT_OPENGL_WINDOW'],'vtkEGLRenderWindow')
        self.assertEqual(env['__EGL_VENDOR_LIBRARY_FILENAMES'],'/usr/share/glvnd/egl_vendor.d/50_mesa.json')
        self.assertEqual(env['LIBGL_ALWAYS_SOFTWARE'],'1')
        self.assertEqual(env['GALLIUM_DRIVER'],'llvmpipe')

    def test_missing_mesa_manifest_is_not_invented(self):
        with patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=False):
            env=backend.driver_environment({'__EGL_VENDOR_LIBRARY_FILENAMES':'inherited-vendor.json'},cpu=True)
        self.assertEqual(env['VTK_DEFAULT_OPENGL_WINDOW'],'vtkEGLRenderWindow')
        self.assertNotIn('__EGL_VENDOR_LIBRARY_FILENAMES',env)

    def test_gpu_discards_software_vendor_and_preserves_window_choice(self):
        base={'__EGL_VENDOR_LIBRARY_FILENAMES':'mesa.json','LIBGL_ALWAYS_SOFTWARE':'1',
              'GALLIUM_DRIVER':'llvmpipe','VTK_DEFAULT_OPENGL_WINDOW':'vtkEGLRenderWindow'}
        env=backend.driver_environment(base)
        self.assertNotIn('__EGL_VENDOR_LIBRARY_FILENAMES',env)
        self.assertNotIn('LIBGL_ALWAYS_SOFTWARE',env)
        self.assertNotIn('GALLIUM_DRIVER',env)
        self.assertEqual(env['VTK_DEFAULT_OPENGL_WINDOW'],base['VTK_DEFAULT_OPENGL_WINDOW'])

    def test_cpu_rejects_a_successful_hardware_frame(self):
        completed=Mock(returncode=0,stdout='{"device":"NVIDIA RTX","drawn":true}',stderr='')
        with patch.dict(os.environ,{},clear=True):
            with self.assertRaisesRegex(RuntimeError,'CPU render probe selected hardware'):
                backend.configure_backend('cpu',run=Mock(return_value=completed))
            self.assertNotIn('BNV_RENDER_BACKEND_SELECTED',os.environ)

    def test_auto_fallback_rejects_hardware_misreported_as_cpu(self):
        software=Mock(returncode=0,stdout='{"device":"SwiftShader","drawn":true}',stderr='')
        hardware=Mock(returncode=0,stdout='{"device":"NVIDIA RTX","drawn":true}',stderr='')
        with patch.dict(os.environ,{},clear=True):
            with self.assertRaisesRegex(RuntimeError,'CPU render probe selected hardware'):
                backend.configure_backend('auto',run=Mock(side_effect=[software,hardware]))
            self.assertNotIn('BNV_RENDER_BACKEND_SELECTED',os.environ)

    def test_cpu_bootstrap_propagates_mesa_selection_to_reexec(self):
        result={'ok':True,'device':'llvmpipe','drawn':True}
        with patch.dict(os.environ,{'BNV_RENDER_BACKEND':'cpu'},clear=True),patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=True),patch.object(backend,'probe',return_value=result) as probe,patch.object(os,'execvpe') as execute:
            backend.bootstrap('brainnet_viewer.web_app',[])
            env=execute.call_args.args[2]
            self.assertEqual(env['VTK_DEFAULT_OPENGL_WINDOW'],'vtkEGLRenderWindow')
            self.assertEqual(env['__EGL_VENDOR_LIBRARY_FILENAMES'],'/usr/share/glvnd/egl_vendor.d/50_mesa.json')
            self.assertEqual(probe.call_args.args[0]['__EGL_VENDOR_LIBRARY_FILENAMES'],env['__EGL_VENDOR_LIBRARY_FILENAMES'])
            self.assertEqual(env['BNV_RENDER_BACKEND_SELECTED'],'cpu')

    def test_auto_probe_failure_falls_back_with_mesa_environment(self):
        failed=Mock(returncode=1,stdout='',stderr='GPU unavailable')
        software=Mock(returncode=0,stdout='{"device":"llvmpipe","drawn":true}',stderr='')
        run=Mock(side_effect=[failed,software])
        with patch.dict(os.environ,{},clear=True),patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=True):
            record=backend.configure_backend('auto',run=run)
            self.assertEqual(record,{'requested':'auto','selected':'cpu','device':'llvmpipe',
                                     'fallback':'Native render probe exited 1'})
            self.assertEqual(run.call_count,2)
            first,second=[call.kwargs['env'] for call in run.call_args_list]
            self.assertNotIn('__EGL_VENDOR_LIBRARY_FILENAMES',first)
            self.assertEqual(second['VTK_DEFAULT_OPENGL_WINDOW'],'vtkEGLRenderWindow')
            self.assertEqual(second['__EGL_VENDOR_LIBRARY_FILENAMES'],os.environ['__EGL_VENDOR_LIBRARY_FILENAMES'])
            self.assertEqual(os.environ['BNV_RENDER_BACKEND_SELECTED'],'cpu')

    def test_missing_mesa_and_failed_cpu_probe_aborts_cpu_and_auto(self):
        failed=Mock(returncode=1,stdout='',stderr='No usable EGL software driver')
        for mode in ('cpu','auto'):
            with self.subTest(mode=mode),patch.dict(os.environ,{},clear=True),patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=False):
                run=Mock(return_value=failed)
                with self.assertRaisesRegex(RuntimeError,'CPU/GPU render startup failed: Native render probe exited 1'):
                    backend.configure_backend(mode,run=run)
                self.assertEqual(run.call_count,1 if mode=='cpu' else 2)
                self.assertNotIn('__EGL_VENDOR_LIBRARY_FILENAMES',run.call_args.kwargs['env'])
                self.assertNotIn('BNV_RENDER_BACKEND_SELECTED',os.environ)

    def test_missing_manifest_accepts_only_actual_software(self):
        completed=lambda device:Mock(returncode=0,stdout='{"device":"'+device+'","drawn":true}',stderr='')
        for device in ('llvmpipe','NVIDIA RTX'):
            with self.subTest(device=device),patch.dict(os.environ,{},clear=True),patch.object(backend.sys,'platform','linux'),patch.object(backend.Path,'is_file',return_value=False):
                run=Mock(return_value=completed(device))
                if device=='llvmpipe':
                    self.assertEqual(backend.configure_backend('cpu',run=run)['selected'],'cpu')
                else:
                    with self.assertRaisesRegex(RuntimeError,'CPU render probe selected hardware'):
                        backend.configure_backend('cpu',run=run)
                self.assertNotIn('__EGL_VENDOR_LIBRARY_FILENAMES',run.call_args.kwargs['env'])

    def test_gpu_success_uses_one_probe_without_cpu_vendor(self):
        hardware=Mock(returncode=0,stdout='{"device":"NVIDIA RTX","drawn":true}',stderr='')
        inherited={'__EGL_VENDOR_LIBRARY_FILENAMES':'mesa.json','LIBGL_ALWAYS_SOFTWARE':'1',
                   'GALLIUM_DRIVER':'llvmpipe','VTK_DEFAULT_OPENGL_WINDOW':'vtkEGLRenderWindow'}
        with patch.dict(os.environ,inherited,clear=True):
            run=Mock(return_value=hardware)
            record=backend.configure_backend('gpu',run=run)
            self.assertEqual(record,{'requested':'gpu','selected':'gpu','device':'NVIDIA RTX','fallback':''})
            self.assertEqual(run.call_count,1)
            for key in ('__EGL_VENDOR_LIBRARY_FILENAMES','LIBGL_ALWAYS_SOFTWARE','GALLIUM_DRIVER'):
                self.assertNotIn(key,run.call_args.kwargs['env'])
                self.assertNotIn(key,os.environ)
            self.assertEqual(os.environ['VTK_DEFAULT_OPENGL_WINDOW'],'vtkEGLRenderWindow')

    def test_gpu_probe_failure_does_not_attempt_cpu(self):
        failed=Mock(returncode=1,stdout='',stderr='GPU unavailable')
        with patch.dict(os.environ,{},clear=True):
            run=Mock(return_value=failed)
            with self.assertRaisesRegex(RuntimeError,'Native render probe exited 1'):
                backend.configure_backend('gpu',run=run)
            self.assertEqual(run.call_count,1)
            self.assertNotIn('BNV_RENDER_BACKEND_SELECTED',os.environ)

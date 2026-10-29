"""Hardware-footer fallbacks and OS routing; no rendering regression suite."""
import ctypes
import importlib.util
import subprocess
import sys
from contextlib import nullcontext
from types import SimpleNamespace
import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from brainnet_viewer.hardware import mac_hardware, linux_hardware
HAS_DESKTOP = all(importlib.util.find_spec(name) is not None for name in ('PySide6', 'pyvistaqt'))
if HAS_DESKTOP:
    from brainnet_viewer.desktop import BrainNetWindow


class HardwareTests(unittest.TestCase):
    def test_mac_total_memory_and_brand(self):
        with patch('brainnet_viewer.hardware.subprocess.check_output', side_effect=['Apple M2\n','17179869184\n']) as query:
            self.assertEqual(mac_hardware(),('Apple M2',16*2**30))
            self.assertEqual([call.args[0] for call in query.call_args_list],[['/usr/sbin/sysctl','-n','machdep.cpu.brand_string'],['/usr/sbin/sysctl','-n','hw.memsize']])
            self.assertTrue(all(call.kwargs['timeout']==1 for call in query.call_args_list))

    def test_mac_cpu_failure_does_not_hide_memory(self):
        with patch('brainnet_viewer.hardware.subprocess.check_output', side_effect=[subprocess.TimeoutExpired('sysctl',1),'17179869184']):
            self.assertEqual(mac_hardware(),('',16*2**30))

    def test_mac_invalid_or_unavailable_memory_does_not_hide_cpu(self):
        for failure in ['not a number','0','-1',OSError('restricted')]:
            with self.subTest(failure=str(failure)), patch('brainnet_viewer.hardware.subprocess.check_output', side_effect=['Intel(R) Core(TM) i7',failure]):
                self.assertEqual(mac_hardware(),('Intel(R) Core(TM) i7',None))

    def footer(self):
        values=[]
        label=SimpleNamespace(setText=values.append,setToolTip=values.append)
        BrainNetWindow.update_resources(SimpleNamespace(plotter=None,resource_label=label))
        self.assertEqual(values[0],values[1])
        return values[0]

    @unittest.skipUnless(HAS_DESKTOP, 'Fixed desktop extra is not installed')
    def test_mac_footer_labels_total_not_available(self):
        with patch.object(sys,'platform','darwin'), patch('os.name','posix'), patch('brainnet_viewer.desktop.mac_hardware',return_value=('Apple M2',16*2**30)):
            text=self.footer()
        self.assertIn('CPU: Apple M2',text)
        self.assertIn('Memory: 16 GiB total',text)
        self.assertNotIn('GB available',text)

    @unittest.skipUnless(HAS_DESKTOP, 'Fixed desktop extra is not installed')
    def test_linux_does_not_query_mac(self):
        with patch.object(sys,'platform','linux'), patch('os.name','posix'), patch('brainnet_viewer.desktop.mac_hardware') as mac, patch('brainnet_viewer.desktop.linux_hardware',return_value=('',None,None,None,None)):
            self.assertIn('Memory: —',self.footer())
            mac.assert_not_called()

    def test_linux_proc_topology_and_available_memory(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            # Two sockets, two SMT threads per core; do not divide threads by 2.
            cpu='\n\n'.join(f'processor : {i}\nmodel name : Intel Test\nphysical id : {i//2}\ncore id : 0' for i in range(4))
            (root/'cpuinfo').write_text(cpu)
            (root/'meminfo').write_text('MemTotal: 16777216 kB\nMemFree: 100 kB\nMemAvailable: 6291456 kB\n')
            self.assertEqual(linux_hardware(root),('Intel Test',4,2,16*2**30,6*2**30))
            (root/'cpuinfo').write_text('processor : 0\nmodel name : ARM Test\n')
            (root/'meminfo').write_text('MemTotal: 16777216 kB\nMemFree: 100 kB\n')
            self.assertEqual(linux_hardware(root),('ARM Test',1,None,16*2**30,None))
            (root/'meminfo').write_text('MemTotal: 1 kB\nMemAvailable: 2 kB\n')
            self.assertIsNone(linux_hardware(root)[4])
            self.assertEqual(linux_hardware(root/'missing'),('',None,None,None,None))

    @unittest.skipUnless(HAS_DESKTOP, 'Fixed desktop extra is not installed')
    def test_linux_footer_uses_host_not_java_or_process_memory(self):
        with patch.object(sys,'platform','linux'), patch('os.name','posix'), patch('brainnet_viewer.desktop.linux_hardware',return_value=('Intel Host',16,8,32*2**30,12*2**30)):
            text=self.footer()
        self.assertIn('CPU: Intel Host · 8 cores / 16 logical processors',text)
        self.assertIn('Memory: 12.0 / 32.0 GiB available',text)

    @unittest.skipUnless(HAS_DESKTOP, 'Fixed desktop extra is not installed')
    def test_windows_existing_registry_and_available_memory_branch(self):
        registry=SimpleNamespace(HKEY_LOCAL_MACHINE=1,OpenKey=lambda *args:nullcontext(1),QueryValueEx=lambda *args:('Intel Test CPU',1))
        def memory_status(pointer):
            pointer._obj.total=16*2**30
            pointer._obj.available=6*2**30
            return 1
        dll=SimpleNamespace(kernel32=SimpleNamespace(GlobalMemoryStatusEx=memory_status))
        with patch.object(sys,'platform','win32'), patch('os.name','nt'), patch.dict(sys.modules,winreg=registry), patch.object(ctypes,'windll',dll,create=True), patch('brainnet_viewer.desktop.mac_hardware') as mac:
            text=self.footer()
            self.assertIn('CPU: Intel Test',text)
            self.assertIn('Memory: 6.0 / 16 GB available',text)
            mac.assert_not_called()


if __name__=='__main__': unittest.main()

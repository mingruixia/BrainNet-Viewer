# SPDX-License-Identifier: GPL-3.0-or-later
"""Bounded launcher checks with an enforcing fake Docker CLI; no real containers."""
import json,os
from pathlib import Path
import shutil,subprocess,tempfile,unittest

REPO=Path(__file__).resolve().parents[2]
BASH=Path("C:/Program Files/Git/bin/bash.exe") if os.name=="nt" else Path(shutil.which("sh") or "/missing/sh")
PWSH=shutil.which("pwsh") or shutil.which("powershell")
MOCK_SH = """#!/bin/sh
printf '%s\\n' "$*" >> "$BNV_MOCK_LOG"
case "$1:$2" in
container:ls) [ "$BNV_MOCK_CASE" != mismatch ] || echo brainnet-web;exit 0;;
image:inspect) echo sha256:expected;exit 0;;
inspect:brainnet-web) echo sha256:other;exit 0;;
info:--format) [ "$BNV_MOCK_CASE" != info-failure ] || exit 8;echo "$BNV_MOCK_NCPU";exit 0;;
esac
if [ "$1" = run ]; then
 previous=
 for item in "$@"; do
  if [ "$previous" = --cpus ]; then
   awk -v quota="$item" -v count="$BNV_MOCK_NCPU" 'BEGIN {exit !(quota+0>0 && quota+0<=count+0)}' || {
    echo "Range of CPUs exceeds engine capacity" >&2;exit 12;
   }
  fi
  previous=$item
 done
 case " $* " in
 *" --probe-gpu "*) [ "$BNV_MOCK_CASE" = gpu ] && exit 0;echo "fixture GPU unavailable" >&2;exit 9;;
 esac
 [ "$BNV_MOCK_CASE" != port-in-use ] || { echo "port is already allocated" >&2;exit 13; }
fi
echo fixture
exit 0
"""
MOCK_PS = r"""param([string]$Launcher,[string]$Backend)
$ErrorActionPreference='Stop'
function global:docker {
 $values=@($args)
 Add-Content -LiteralPath $env:BNV_MOCK_LOG -Value ($values | ConvertTo-Json -Compress)
 $global:LASTEXITCODE=0
 if ($values[0] -eq 'container') {
  if ($env:BNV_MOCK_CASE -eq 'mismatch') { return 'brainnet-web' };return ''
 }
 if ($values[0] -eq 'image') { return 'sha256:expected' }
 if ($values[0] -eq 'inspect') {
  return '[{"Image":"sha256:other","Config":{"Labels":{"org.brainnetviewer.application":"web"}},"HostConfig":{"PortBindings":{"1031/tcp":[{"HostIp":"127.0.0.1","HostPort":"1031"}]}}}]'
 }
 if ($values[0] -eq 'info') {
  if ($env:BNV_MOCK_CASE -eq 'info-failure') { $global:LASTEXITCODE=8;return 'unavailable' }
  return $env:BNV_MOCK_NCPU
 }
 if ($values[0] -eq 'run') {
  $at=[Array]::IndexOf($values,'--cpus')
  if ($at -lt 0) { throw 'Fixture expected a bounded CPU quota' }
  $quota=[decimal]::Parse($values[$at+1],[Globalization.CultureInfo]::InvariantCulture)
  if ($quota -le 0 -or $quota -gt [int]$env:BNV_MOCK_NCPU) {
   $global:LASTEXITCODE=12;return 'Range of CPUs exceeds engine capacity'
  }
  if ($values -contains '--probe-gpu') {
   if ($env:BNV_MOCK_CASE -ne 'gpu') { $global:LASTEXITCODE=9;return 'fixture GPU unavailable' }
   return '{"selected":"gpu","device":"fixture-only"}'
  }
  if ($env:BNV_MOCK_CASE -eq 'port-in-use') {
   $global:LASTEXITCODE=13;return 'port is already allocated'
  }
 }
 return 'fixture'
}
function global:Invoke-WebRequest { return [pscustomobject]@{StatusCode=200} }
if ($env:BNV_MOCK_CLI_CPUS) {
 & $Launcher -Action Start -Backend $Backend -CPUs $env:BNV_MOCK_CLI_CPUS
} else { & $Launcher -Action Start -Backend $Backend }
"""

class ReleaseLauncherTests(unittest.TestCase):
    def run_launcher(self,kind,case,backend,ncpu="8",cpus=None,cli_cpus=None):
        folder=tempfile.TemporaryDirectory();self.addCleanup(folder.cleanup)
        root=Path(folder.name);log=root/"docker.log"
        env={k:v for k,v in os.environ.items() if k not in {"BNV_CPUS","BNV_MOCK_CLI_CPUS"}}
        env.update(BNV_MOCK_CASE=case,BNV_MOCK_NCPU=str(ncpu),BNV_MOCK_LOG=str(log))
        if cpus is not None:env["BNV_CPUS"]=cpus
        if cli_cpus is not None:env["BNV_MOCK_CLI_CPUS"]=cli_cpus
        if kind=="shell":
            if not BASH.exists():self.skipTest("POSIX shell is unavailable")
            cli=root/"docker";cli.write_text(MOCK_SH,encoding="utf-8",newline="\n");cli.chmod(0o755)
            env["PATH"]=str(root)+os.pathsep+env["PATH"]
            command=[str(BASH),str(REPO/"tools/start_web.sh"),"--backend",backend.lower()]
            if cli_cpus is not None:command+=["--cpus",cli_cpus]
        else:
            if not PWSH:self.skipTest("PowerShell is unavailable")
            harness=root/"harness.ps1";harness.write_text(MOCK_PS,encoding="utf-8")
            command=[PWSH,"-NoProfile","-File",str(harness),"-Launcher",str(REPO/"tools/manage_brainnet_web.ps1"),"-Backend",backend]
        result=subprocess.run(command,env=env,text=True,encoding="utf-8",capture_output=True,timeout=20)
        calls=log.read_text(encoding="utf-8-sig") if log.exists() else ""
        return result,calls

    def runs(self,kind,calls):
        parsed=[json.loads(line) if kind=="powershell" else line.split() for line in calls.splitlines()]
        return [args for args in parsed if args[0]=="run"]

    def test_auto_gpu_and_no_gpu_fallback(self):
        for kind in ("shell","powershell"):
            for case in ("gpu","no-gpu"):
                with self.subTest(kind=kind,case=case):
                    result,calls=self.run_launcher(kind,case,"Auto",ncpu=4)
                    self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                    runs=self.runs(kind,calls)
                    self.assertEqual(len(runs),2)
                    self.assertTrue(all(args[args.index("--cpus")+1]=="4" for args in runs))
                    app=runs[-1]
                    self.assertIn("BNV_RENDER_BACKEND="+("auto" if case=="gpu" else "cpu"),app)
                    if case=="no-gpu":self.assertNotIn("--gpus",app)
                    self.assertTrue(all("--pull=never" in args for args in runs))

    def test_explicit_cpu_skips_gpu_and_explicit_gpu_fails_closed(self):
        for kind in ("shell","powershell"):
            with self.subTest(kind=kind,backend="CPU"):
                result,calls=self.run_launcher(kind,"no-gpu","CPU",ncpu=2)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                self.assertNotIn("--probe-gpu",calls)
                self.assertNotIn("--gpus",calls)
                self.assertIn("BNV_RENDER_BACKEND=cpu",calls)
            with self.subTest(kind=kind,backend="GPU"):
                result,calls=self.run_launcher(kind,"no-gpu","GPU",ncpu=2)
                self.assertNotEqual(result.returncode,0)
                self.assertNotIn("BNV_RENDER_BACKEND=",calls)
                self.assertEqual(len(self.runs(kind,calls)),1)

    def test_existing_mismatched_container_is_not_changed(self):
        for kind in ("shell","powershell"):
            with self.subTest(kind=kind):
                result,calls=self.run_launcher(kind,"mismatch","Auto")
                self.assertNotEqual(result.returncode,0)
                self.assertEqual(self.runs(kind,calls),[])
                self.assertNotIn('"start"',calls)
                self.assertNotIn('"stop"',calls)

    def test_default_quota_uses_docker_engine_cpu_count(self):
        for kind in ("shell","powershell"):
            for available in (1,2,4,8,16):
                with self.subTest(kind=kind,ncpu=available):
                    result,calls=self.run_launcher(kind,"gpu","GPU",ncpu=available)
                    self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                    runs=self.runs(kind,calls)
                    self.assertEqual(len(runs),2)
                    self.assertTrue(all(args[args.index("--cpus")+1]==str(min(8,available)) for args in runs))

    def test_cpu_override_and_cli_precedence(self):
        for kind in ("shell","powershell"):
            for env_value,cli_value,expected in (("0.5",None,"0.5"),("1.5",None,"1.5"),("8","1","1")):
                with self.subTest(kind=kind,value=env_value,cli=cli_value):
                    result,calls=self.run_launcher(kind,"gpu","GPU",ncpu=4,cpus=env_value,cli_cpus=cli_value)
                    self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                    self.assertTrue(all(args[args.index("--cpus")+1]==expected for args in self.runs(kind,calls)))

    def test_invalid_or_excess_quota_is_not_reported_as_gpu_failure(self):
        for kind in ("shell","powershell"):
            for quota in ("0","0.001","5","NaN","1,5","-1"):
                with self.subTest(kind=kind,quota=quota):
                    result,calls=self.run_launcher(kind,"gpu","Auto",ncpu=4,cpus=quota)
                    self.assertNotEqual(result.returncode,0)
                    self.assertEqual(self.runs(kind,calls),[])
                    self.assertNotIn("GPU unavailable",result.stderr)
                    self.assertNotIn("GPU startup unavailable",result.stdout)

    def test_engine_query_failure_stops_before_gpu_probe(self):
        for kind in ("shell","powershell"):
            for count,case in (("0","gpu"),("invalid","gpu"),("4","info-failure")):
                with self.subTest(kind=kind,count=count,case=case):
                    result,calls=self.run_launcher(kind,case,"Auto",ncpu=count)
                    self.assertNotEqual(result.returncode,0)
                    self.assertEqual(self.runs(kind,calls),[])

    def test_occupied_port_retains_error_and_guides_safe_upgrade(self):
        for kind in ("shell","powershell"):
            with self.subTest(kind=kind):
                result,calls=self.run_launcher(kind,"port-in-use","CPU",ncpu=1)
                self.assertNotEqual(result.returncode,0)
                self.assertIn("port is already allocated",result.stderr)
                self.assertIn("free port",result.stderr)
                self.assertNotIn('"stop"',calls)
                self.assertNotIn('"rm"',calls)

if __name__=="__main__":unittest.main()

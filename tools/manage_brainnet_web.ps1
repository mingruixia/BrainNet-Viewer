param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Start','Stop','Restart','Status','Logs')][string]$Action,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._:/@-]*$')][string]$Image='brainnet-viewer:web-local',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')][string]$ContainerName='brainnet-web',
    [ValidateRange(1024,65535)][int]$Port=1031
)
$ErrorActionPreference='Stop'

function Invoke-BnvDocker {
    param([string[]]$Arguments)
    $bnvOutput = & docker @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker failed: $($bnvOutput -join [Environment]::NewLine)" }
    return ($bnvOutput -join [Environment]::NewLine).Trim()
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker CLI is unavailable. Install/configure Docker first.' }
$bnvNames=Invoke-BnvDocker -Arguments @('container','ls','-a','--filter',('name=^'+[regex]::Escape($ContainerName)+'$'),'--format','{{.Names}}')
$bnvExists=$bnvNames -eq $ContainerName
if ($bnvExists) {
    $bnvExpected=Invoke-BnvDocker -Arguments @('image','inspect',$Image,'--format','{{.Id}}')
    $bnvRecord=Invoke-BnvDocker -Arguments @('inspect',$ContainerName)
    $bnvContainer=($bnvRecord | ConvertFrom-Json)[0]
    if ($bnvContainer.Image -ne $bnvExpected) {
        throw 'Existing container uses another image. No changes made. Choose its exact image or a different container name.'
    }
    $bnvBinding=$bnvContainer.HostConfig.PortBindings.'1031/tcp'
    if (-not $bnvBinding -or $bnvBinding.Count -ne 1 -or $bnvBinding[0].HostIp -ne '127.0.0.1' -or $bnvBinding[0].HostPort -ne [string]$Port) {
        throw 'Existing container has different port bindings. No changes made.'
    }
}

switch ($Action) {
    'Start' {
        if ($bnvExists) {
            if (-not $bnvContainer.State.Running) { Invoke-BnvDocker -Arguments @('start',$ContainerName) | Out-Null }
        } else {
            Invoke-BnvDocker -Arguments @('run','-d','--name',$ContainerName,
                '--label','org.brainnetviewer.application=web','--read-only',
                '--tmpfs','/tmp:size=512m,mode=1777','--cpus','8','--memory','8g',
                '--pids-limit','256','--cap-drop','ALL','--security-opt','no-new-privileges:true',
                '--env','LIBGL_ALWAYS_SOFTWARE=1','-p',"127.0.0.1:${Port}:1031",$Image) | Out-Null
        }
    }
    'Stop' { if ($bnvExists -and $bnvContainer.State.Running) { Invoke-BnvDocker -Arguments @('stop','--time','10',$ContainerName) | Out-Null } }
    'Restart' {
        if (-not $bnvExists) { throw 'Container does not exist. Use Start first.' }
        Invoke-BnvDocker -Arguments @('restart','--time','10',$ContainerName) | Out-Null
    }
    'Logs' {
        if (-not $bnvExists) { throw 'Container does not exist.' }
        Invoke-BnvDocker -Arguments @('logs','--tail','60',$ContainerName)
        return
    }
    'Status' { }
}
if ($Action -in @('Start','Restart')) {
    $bnvDeadline=(Get-Date).AddSeconds(30)
    $bnvReady=$false
    do {
        try {
            $bnvResponse=Invoke-WebRequest -Uri "http://127.0.0.1:${Port}/index.html" -UseBasicParsing -TimeoutSec 2
            $bnvReady=$bnvResponse.StatusCode -eq 200
        } catch { }
        if (-not $bnvReady) { Start-Sleep -Milliseconds 300 }
    } while (-not $bnvReady -and (Get-Date) -lt $bnvDeadline)
    if (-not $bnvReady) { throw "Container started but HTTP readiness was not confirmed in 30 seconds. Use Logs; do not start another copy." }
}
$bnvNames=Invoke-BnvDocker -Arguments @('container','ls','-a','--filter',('name=^'+[regex]::Escape($ContainerName)+'$'),'--format','{{.Names}}')
if ($bnvNames -ne $ContainerName) { Write-Output 'Container is not created.'; return }
Invoke-BnvDocker -Arguments @('inspect',$ContainerName,'--format','{{.Name}} | {{.State.Status}} | {{.Image}}')
if ($Action -ne 'Stop') { Write-Output "Browser: http://127.0.0.1:${Port}/index.html" }

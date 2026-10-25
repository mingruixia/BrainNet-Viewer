param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Start','Stop','Restart','Status','Logs')][string]$Action,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._:/@-]*$')][string]$Image='mingruixia/brainnet-viewer:2.0.0',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')][string]$ContainerName='brainnet-web',
    [ValidateRange(1024,65535)][int]$Port=1031,
    [ValidateSet('Auto','GPU','CPU')][string]$Backend='Auto',
    [string]$CPUs=$env:BNV_CPUS
)
$ErrorActionPreference='Stop'

function Invoke-BnvDocker {
    param([string[]]$Arguments)
    $bnvOutput = & docker @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker failed: $($bnvOutput -join [Environment]::NewLine)" }
    return ($bnvOutput -join [Environment]::NewLine).Trim()
}

function Get-BnvCpuLimit {
    $bnvAvailableText=Invoke-BnvDocker -Arguments @('info','--format','{{.NCPU}}')
    $bnvAvailable=0
    if (-not [int]::TryParse($bnvAvailableText,[ref]$bnvAvailable) -or $bnvAvailable -lt 1) {
        throw 'Cannot determine available Docker engine CPUs. No container created.'
    }
    if ([string]::IsNullOrEmpty($CPUs)) { $bnvValue=[decimal][Math]::Min(8,$bnvAvailable) }
    else {
        $bnvValue=[decimal]0
        if ($CPUs -notmatch '^[0-9]+(\.[0-9]+)?$' -or
            -not [decimal]::TryParse($CPUs,[Globalization.NumberStyles]::AllowDecimalPoint,
                [Globalization.CultureInfo]::InvariantCulture,[ref]$bnvValue)) {
            throw 'Invalid CPU limit. Use a decimal number such as 1 or 0.5.'
        }
    }
    if ($bnvValue -lt [decimal]0.01 -or $bnvValue -gt $bnvAvailable) {
        throw "CPU limit must be 0.01 through $bnvAvailable (Docker engine CPUs). No container created."
    }
    return [pscustomobject]@{
        Limit=$bnvValue.ToString('0.#########',[Globalization.CultureInfo]::InvariantCulture)
        Available=$bnvAvailable
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker CLI is unavailable. Install/configure Docker first.' }
$bnvNames=Invoke-BnvDocker -Arguments @('container','ls','-a','--filter',('name=^'+[regex]::Escape($ContainerName)+'$'),'--format','{{.Names}}')
$bnvExists=$bnvNames -eq $ContainerName
if ($bnvExists) {
    $bnvExpected=Invoke-BnvDocker -Arguments @('image','inspect',$Image,'--format','{{.Id}}')
    $bnvRecord=Invoke-BnvDocker -Arguments @('inspect',$ContainerName)
    $bnvContainer=($bnvRecord | ConvertFrom-Json)[0]
    if ($bnvContainer.Config.Labels.'org.brainnetviewer.application' -ne 'web') {
        throw 'Existing container is not managed by this launcher. No changes made; choose another name.'
    }
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
            Invoke-BnvDocker -Arguments @('image','inspect',$Image,'--format','{{.Id}}') | Out-Null
            $bnvQuota=Get-BnvCpuLimit
            Write-Output "CPU limit: $($bnvQuota.Limit); Docker engine CPUs: $($bnvQuota.Available)"
            # Docker cannot conditionally allocate a GPU inside Compose. Probe the
            # actual native render in a disposable container before choosing flags.
            $bnvGpuArguments=@('--gpus','all','--env','NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute')
            if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
                $bnvGpuArguments+=@('--mount','type=bind,source=/usr/lib/wsl/lib,target=/usr/lib/wsl/lib,readonly',
                    '--mount','type=bind,source=/usr/lib/wsl/drivers,target=/usr/lib/wsl/drivers,readonly')
            }
            $bnvSelected='cpu'
            if ($Backend -ne 'CPU') {
                try {
                    $bnvProbe=Invoke-BnvDocker -Arguments (@('run','--rm','--pull=never','--read-only',
                        '--tmpfs','/tmp:size=512m,mode=1777','--cpus',$bnvQuota.Limit,'--memory','8g',
                        '--pids-limit','256','--cap-drop','ALL','--security-opt','no-new-privileges:true',
                        '--entrypoint','python')+$bnvGpuArguments+@($Image,'-m','brainnet_viewer.web_backend','--probe-gpu'))
                    Write-Output $bnvProbe
                    $bnvSelected='gpu'
                } catch {
                    if ($Backend -eq 'GPU') { throw }
                    Write-Warning "GPU startup unavailable; using CPU. $($_.Exception.Message)"
                }
            }
            $bnvRuntimeBackend=$bnvSelected
            if ($Backend -eq 'Auto' -and $bnvSelected -eq 'gpu') { $bnvRuntimeBackend='auto' }
            $bnvRunArguments=@('run','-d','--pull=never','--name',$ContainerName,
                '--label','org.brainnetviewer.application=web','--read-only',
                '--tmpfs','/tmp:size=512m,mode=1777','--cpus',$bnvQuota.Limit,'--memory','8g',
                '--pids-limit','256','--cap-drop','ALL','--security-opt','no-new-privileges:true',
                '--env',"BNV_RENDER_BACKEND=$bnvRuntimeBackend",'-p',"127.0.0.1:${Port}:1031")
            if ($bnvSelected -eq 'gpu') { $bnvRunArguments+=$bnvGpuArguments }
            try { Invoke-BnvDocker -Arguments ($bnvRunArguments+@($Image)) | Out-Null }
            catch { throw "Application startup failed. If the port is occupied, save the old Scene and stop only its identified container, or use a new name AND a free port. $($_.Exception.Message)" }
            Write-Output "Requested backend: $Backend; selected: $bnvSelected"
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
    $bnvDeadline=(Get-Date).AddSeconds(90)
    $bnvReady=$false
    do {
        try {
            $bnvResponse=Invoke-WebRequest -Uri "http://127.0.0.1:${Port}/index.html" -UseBasicParsing -TimeoutSec 2
            $bnvReady=$bnvResponse.StatusCode -eq 200
        } catch { }
        if (-not $bnvReady) { Start-Sleep -Milliseconds 300 }
    } while (-not $bnvReady -and (Get-Date) -lt $bnvDeadline)
    if (-not $bnvReady) { throw "Container started but HTTP readiness was not confirmed in 90 seconds. Use Logs; do not start another copy." }
}
$bnvNames=Invoke-BnvDocker -Arguments @('container','ls','-a','--filter',('name=^'+[regex]::Escape($ContainerName)+'$'),'--format','{{.Names}}')
if ($bnvNames -ne $ContainerName) { Write-Output 'Container is not created.'; return }
Invoke-BnvDocker -Arguments @('inspect',$ContainerName,'--format','{{.Name}} | {{.State.Status}} | {{.Image}}')
if ($Action -ne 'Stop') { Write-Output "Browser: http://127.0.0.1:${Port}/index.html" }

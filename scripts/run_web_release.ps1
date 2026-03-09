param(
  [int]$Port = 7361,
  [string]$BindHost = '127.0.0.1',
  [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutter = Join-Path $repoRoot 'flutter\bin\flutter.bat'
$logPath = Join-Path $repoRoot 'web-release.log'
$url = "http://${BindHost}:${Port}"

function Test-PortBusy {
  param([int]$TargetPort)

  $listeners = Get-NetTCPConnection `
    -State Listen `
    -LocalPort $TargetPort `
    -ErrorAction SilentlyContinue

  return $null -ne $listeners
}

if (-not (Test-Path $flutter)) {
  throw "Flutter executable not found: $flutter"
}

if (Test-PortBusy -TargetPort $Port) {
  throw "Port $Port is already in use. Stop the existing server or choose another port."
}

$browserJob = $null
if (-not $NoBrowser) {
  $browserJob = Start-Job -ArgumentList $url -ScriptBlock {
    param($TargetUrl)

    for ($attempt = 0; $attempt -lt 120; $attempt++) {
      try {
        $response = Invoke-WebRequest `
          -Uri $TargetUrl `
          -UseBasicParsing `
          -TimeoutSec 2

        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
          Start-Process $TargetUrl
          return
        }
      } catch {
        Start-Sleep -Seconds 1
      }
    }
  }
}

Write-Host "Starting FridgeChef web release at $url"
Write-Host "Log file: $logPath"
Write-Host "Press Ctrl+C to stop the server."

try {
  & $flutter run `
    -d web-server `
    --release `
    --web-hostname $BindHost `
    --web-port $Port 2>&1 | Tee-Object -FilePath $logPath
} finally {
  if ($browserJob -ne $null) {
    Stop-Job $browserJob -ErrorAction SilentlyContinue
    Remove-Job $browserJob -Force -ErrorAction SilentlyContinue
  }
}

param(
  [string]$Device = 'chrome',
  [int]$Port = 4444
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutter = Join-Path $repoRoot 'flutter\bin\flutter.bat'
$chromedriverOutLog = Join-Path $repoRoot 'web-smoke-chromedriver.out.log'
$chromedriverErrLog = Join-Path $repoRoot 'web-smoke-chromedriver.err.log'

function Get-ChromeDriverPackage {
  param([string]$TargetDevice)

  if ($TargetDevice -ne 'chrome') {
    return 'chromedriver'
  }

  $chromeCandidates = @(
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
    (Join-Path $env:LocalAppData 'Google\Chrome\Application\chrome.exe')
  ) | Where-Object { $_ -and (Test-Path $_) }

  foreach ($chromePath in $chromeCandidates) {
    try {
      $versionOutput = (Get-Item $chromePath).VersionInfo.ProductVersion
      if ($versionOutput -match '(\d+)\.') {
        return "chromedriver@$($Matches[1])"
      }
    } catch {
    }
  }

  return 'chromedriver'
}

function Clear-StaleChromeDriver {
  param([int]$TargetPort)

  $listeners = Get-NetTCPConnection `
    -State Listen `
    -LocalPort $TargetPort `
    -ErrorAction SilentlyContinue

  foreach ($listener in $listeners) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
    if ($null -ne $process -and $process.Name -eq 'chromedriver.exe') {
      Stop-Process -Id $listener.OwningProcess -Force
    }
  }
}

if (-not (Test-Path $flutter)) {
  throw "Flutter executable not found: $flutter"
}

Write-Host "Starting ChromeDriver on port $Port"

$chromedriverPackage = Get-ChromeDriverPackage -TargetDevice $Device
Write-Host "Using $chromedriverPackage"

Clear-StaleChromeDriver -TargetPort $Port

$driver = Start-Process `
  -FilePath 'npx.cmd' `
  -ArgumentList @('-y', $chromedriverPackage, "--port=$Port") `
  -WorkingDirectory $repoRoot `
  -RedirectStandardOutput $chromedriverOutLog `
  -RedirectStandardError $chromedriverErrLog `
  -PassThru

try {
  $driverReady = $false
  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 500
    try {
      $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/status" -UseBasicParsing
      if ($response.StatusCode -eq 200) {
        $driverReady = $true
        break
      }
    } catch {
    }
  }

  if (-not $driverReady) {
    throw "ChromeDriver did not become ready on port $Port. See $chromedriverOutLog and $chromedriverErrLog"
  }

  Write-Host "Running browser smoke on $Device"

  & $flutter drive `
    --driver test_driver\integration_test.dart `
    --target integration_test\web_smoke_test.dart `
    -d $Device
} finally {
  if ($null -ne $driver -and -not $driver.HasExited) {
    Stop-Process -Id $driver.Id -Force
  }
}

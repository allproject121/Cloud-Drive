<#
  Naya build tab lagana jab purana Cloud-SSD.exe Windows ke andar "khatam ho raha" haal mein atka ho (17 Nov 2026:
  HasExited=True, End task se nahi jata) aur usne program files pakad rakhi hon.
  Tareeka: jo purani file likhne ke liye band hai aur nayi se alag hai, uska sirf NAAM badal do (".old-<samay>"), phir
  aam installer chalao, phir app chalu karo. Naam badli files baad ke kisi install / restart ke baad hata sakte ho.
  User ka data (%LOCALAPPDATA%\Cloud-SSD) nahi chhuta. Drives (rclone) chalti rehti hain.
    powershell -ExecutionPolicy Bypass -File .work\speed\install-over-stuck.ps1
#>
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$src = Join-Path $repo 'dist\Cloud-SSD-0.9.0-win-x64'
$dst = Join-Path $env:LOCALAPPDATA 'Programs\Cloud-SSD'
if (-not (Test-Path (Join-Path $src 'Install-CloudSSD.ps1'))) { throw "No release at $src" }

# Ek zinda (atka nahi) app chal raha ho to yeh script nahi: pehle use aam tareeke se band karo.
$live = Get-Process Cloud-SSD -ErrorAction SilentlyContinue | Where-Object { -not $_.HasExited }
if ($live) { 'A live Cloud-SSD app is running: close it normally first.'; exit 1 }

$stamp = (Get-Date).ToString('MMddHHmm')
$renamed = 0; $same = 0
foreach ($f in (Get-ChildItem -LiteralPath $src -Recurse -File)) {
    $rel = $f.FullName.Substring($src.Length + 1)
    $to = Join-Path $dst $rel
    if (-not (Test-Path -LiteralPath $to)) { continue }
    $old = Get-Item -LiteralPath $to
    if ($old.Length -eq $f.Length -and $old.LastWriteTimeUtc -eq $f.LastWriteTimeUtc) { $same++; continue }
    try { $h = [IO.File]::Open($to, 'Open', 'ReadWrite', 'None'); $h.Close() }
    catch {
        Rename-Item -LiteralPath $to -NewName ($old.Name + ".old-$stamp")
        $renamed++
    }
}
"files already the same: $same; held files moved aside: $renamed"

# Aam installer atke hue process ko "chal raha" samajh kar mana kar deta hai, isliye uska copy wala kadam yahin
# (wahi robocopy line). Shortcut / uninstall entry / PATH pehle ke install se maujood hain.
robocopy $src $dst /E /XF Install.cmd /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
"robocopy code: $LASTEXITCODE (8 se kam = theek)"
if ($LASTEXITCODE -ge 8) { 'Copying the program files failed; the app was not started.'; exit 2 }
"installed build: " + (Get-Item (Join-Path $dst 'CloudSSD.App.dll')).LastWriteTime.ToString('dd-MM HH:mm:ss')
Start-Process (Join-Path $dst 'Cloud-SSD.exe')
'app started'

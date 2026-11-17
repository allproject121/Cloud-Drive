# "Install jaisa" naap: ek install ho chuke app ki saari files (jaise MiniMax Code: 853 files, 143 folder, 970 MB)
# usi tarah ek-ek karke kisi jagah likhna jaise installer likhta hai, aur samay naapna.
#   1) laptop ki disk par (tulna)   2) cloud drive par   3) cloud drive par: Google tak upload poora hone tak
# Asli installer nahi chalta (registry / shortcut nahi badalte). Test folder aakhir mein hata diya jata hai.
# File ke naam nahi chhapte.
#   powershell -ExecutionPolicy Bypass -File .work\speed\install-sim.ps1 -Drive G -Folder "MiniMax Code"
param(
    [Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Drive,
    [string] $Folder = 'MiniMax Code',
    [switch] $KeepTestFolder
)
Add-Type -AssemblyName System.Security
$src = Join-Path $env:LOCALAPPDATA "Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD\$Folder"
if (-not (Test-Path -LiteralPath $src)) { "source not found in the drive's cache: $Folder"; exit 2 }
$files = @(Get-ChildItem -LiteralPath $src -Recurse -File -Force)
$dirs = @(Get-ChildItem -LiteralPath $src -Recurse -Directory -Force)
$mb = [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 1)
"source: $($files.Count) files, $($dirs.Count) folders, $mb MB"

$stamp = (Get-Date).ToString('HHmmss')
$log = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\logs\rclone-cloudssd.log'

function Copy-Tree([string] $to) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    # /MT:1 = ek-ek file (installer jaisa). /NFL /NDL /NP = naam aur progress mat chhapo.
    $null = robocopy $src $to /E /MT:1 /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
    $code = $LASTEXITCODE
    $sw.Stop()
    $n = @(Get-ChildItem -LiteralPath $to -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    [pscustomobject]@{ Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); Files = $n; Robocopy = $code }
}

# 1) laptop ki disk
$local = Join-Path $env:TEMP "cssd-install-sim-$stamp"
$r1 = Copy-Tree $local
"1) local disk : {0} s  ({1} files, robocopy code {2})" -f $r1.Seconds, $r1.Files, $r1.Robocopy
Remove-Item -LiteralPath $local -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue

# 2) cloud drive
$since = (Get-Date).ToString('HH:mm:ss')
$cloud = "$($Drive.ToUpper()):\_install-speed-test-$stamp"
$r2 = Copy-Tree (Join-Path $cloud $Folder)
"2) cloud drive: {0} s  ({1} files, robocopy code {2})  -> {3}" -f $r2.Seconds, $r2.Files, $r2.Robocopy, $cloud

# 3) upload poora hone tak (rclone se poochh kar)
$m = (Get-Content (Join-Path $env:LOCALAPPDATA 'Cloud-SSD\mounts.state.json') -Raw | ConvertFrom-Json) | Where-Object { "$($_.Letter)" -eq $Drive.ToUpper() } | Select-Object -First 1
$up = [Diagnostics.Stopwatch]::StartNew()
if ($m) {
    $pass = [Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($m.PassProtected), [Text.Encoding]::UTF8.GetBytes('CloudPlayX.v1.secret'), 'CurrentUser'))
    $h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($m.User):$pass")) }
    $deadline = (Get-Date).AddMinutes(60)
    while ((Get-Date) -lt $deadline) {
        try {
            $s = Invoke-RestMethod -Uri "http://127.0.0.1:$($m.Port)/vfs/stats" -Method Post -Headers $h -ContentType 'application/json' -Body '{}' -TimeoutSec 10
            $left = [int]$s.diskCache.uploadsInProgress + [int]$s.diskCache.uploadsQueued
            if ($left -eq 0) { break }
        } catch { }
        Start-Sleep -Seconds 3
    }
    $up.Stop()
    "3) all uploaded to Google: {0} s after the copy ended (total {1} s)" -f [math]::Round($up.Elapsed.TotalSeconds, 1), [math]::Round($up.Elapsed.TotalSeconds + $r2.Seconds, 1)
} else { "3) drive $Drive not found in mounts.state.json: upload time not measured" }

# Google ke "mana" (403) is dauraan
$fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite'); $sr = New-Object IO.StreamReader($fs); $all = $sr.ReadToEnd(); $fs.Close()
$day = (Get-Date).ToString('yyyy/MM/dd', [Globalization.CultureInfo]::InvariantCulture)
$e403 = 0; $ok = 0; $bad = 0; $eio = 0
foreach ($line in ($all -split "`n")) {
    if ($line.Length -lt 30 -or -not $line.StartsWith($day) -or $line.Substring(11, 8) -lt $since) { continue }
    if ($line.Contains('Error 403')) { $e403++ }
    if ($line.Contains('upload succeeded')) { $ok++ }
    if ($line.Contains('failed to upload')) { $bad++ }
    if ($line.Contains('errc=-5')) { $eio++ }
}
"during the test: 403 = $e403, uploads OK = $ok, upload failures = $bad, I/O errors = $eio"

if (-not $KeepTestFolder) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Remove-Item -LiteralPath $cloud -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    "test folder removed in {0} s (still there: {1})" -f [math]::Round($sw.Elapsed.TotalSeconds, 1), (Test-Path -LiteralPath $cloud)
}

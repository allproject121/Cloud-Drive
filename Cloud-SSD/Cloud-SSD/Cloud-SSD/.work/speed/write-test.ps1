# Does what an installer does when its target is the cloud drive: makes folders, writes many small files and one
# big one, reads one back, renames one. Reports the time of each step, the same on a local folder for comparison.
# The test folder is removed at the end (on the cloud drive it goes to the account's trash).
param(
    [string]$Target = 'Z:\',
    [int]$Folders = 6,
    [int]$FilesPerFolder = 10,
    [int]$SmallKB = 200,
    [int]$BigMB = 30,
    [string]$RcloneLog = "$env:LOCALAPPDATA\Cloud-SSD\logs\rclone-cloudssd.log"
)
$ErrorActionPreference = 'Stop'
function Count403($file) {
    if (-not (Test-Path $file)) { return 0 }
    $q = 0
    $fs = [IO.File]::Open($file, 'Open', 'Read', 'ReadWrite,Delete')
    try { $sr = New-Object IO.StreamReader($fs); while ($null -ne ($l = $sr.ReadLine())) { if ($l.Contains('Error 403')) { $q++ } } } finally { $fs.Dispose() }
    $q
}
function Run([string]$root, [string]$label) {
    $dir = Join-Path $root ("_cloudssd_speedtest_" + (Get-Date -Format 'HHmmss'))
    $small = New-Object byte[] ($SmallKB * 1024); (New-Object Random 7).NextBytes($small)
    $big = New-Object byte[] (1MB); (New-Object Random 9).NextBytes($big)
    $r = [ordered]@{ Where = $label }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    New-Item -ItemType Directory -Path $dir | Out-Null
    $r.MakeTopFolderS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    for ($d = 0; $d -lt $Folders; $d++) { New-Item -ItemType Directory -Path (Join-Path $dir "part$d\bin") -Force | Out-Null }
    $r.MakeFoldersS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    for ($d = 0; $d -lt $Folders; $d++) { for ($f = 0; $f -lt $FilesPerFolder; $f++) { [IO.File]::WriteAllBytes((Join-Path $dir "part$d\bin\file$f.dll"), $small) } }
    $r.WriteSmallFilesS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    $fs = [IO.File]::Create((Join-Path $dir 'big.bin'))
    try { for ($i = 0; $i -lt $BigMB; $i++) { $fs.Write($big, 0, $big.Length) } } finally { $fs.Dispose() }
    $r.WriteBigFileS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    [IO.File]::ReadAllBytes((Join-Path $dir 'big.bin')) | Out-Null
    $r.ReadBigBackS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    Rename-Item (Join-Path $dir 'part0\bin\file0.dll') 'file0-renamed.dll'
    $r.RenameS = [Math]::Round($sw.Elapsed.TotalSeconds, 2); $sw.Restart()
    $r.Files = $Folders * $FilesPerFolder + 1
    $r.TotalMB = [Math]::Round(($Folders * $FilesPerFolder * $SmallKB / 1024) + $BigMB, 1)
    $r.Dir = $dir
    [pscustomobject]$r
}
$local = Run $env:TEMP 'local disk (C:)'
Remove-Item $local.Dir -Recurse -Force
$q0 = Count403 $RcloneLog
$cloud = Run $Target "cloud drive ($Target)"
$q1 = Count403 $RcloneLog
$local, $cloud | Select-Object Where, MakeTopFolderS, MakeFoldersS, WriteSmallFilesS, WriteBigFileS, ReadBigBackS, RenameS, Files, TotalMB | Format-List
"Quota (403) answers during the cloud run: $($q1 - $q0)"
"TESTDIR=$($cloud.Dir)"

# Opens a zip the way Windows does to show its file list (reads the end of the file), and reports how many
# requests rclone needed, how much was downloaded into the cache and how many quota (403) answers came.
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$RcloneLog = "$env:LOCALAPPDATA\Cloud-SSD\logs\rclone-cloudssd.log",
    [string]$CacheMeta = "$env:LOCALAPPDATA\Cloud-SSD\cache\m-cloudssd\vfsMeta"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
function LogStats($file) {
    $q = 0; $opens = 0
    $fs = [IO.File]::Open($file, 'Open', 'Read', 'ReadWrite,Delete')
    try {
        $sr = New-Object IO.StreamReader($fs)
        while ($null -ne ($l = $sr.ReadLine())) {
            if ($l.Contains('Error 403')) { $q++ }
            if ($l.Contains('ChunkedReader.openRange')) { $opens++ }
        }
    } finally { $fs.Dispose() }
    [pscustomobject]@{ Quota403 = $q; RangeOpens = $opens }
}
function CachedBytes($name) {
    $f = Get-ChildItem $CacheMeta -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $f) { return 0 }
    $j = Get-Content $f.FullName -Raw | ConvertFrom-Json
    [long](($j.Rs | Measure-Object Size -Sum).Sum)
}
$name = Split-Path $Path -Leaf
$before = LogStats $RcloneLog
$cachedBefore = CachedBytes $name
$sw = [Diagnostics.Stopwatch]::StartNew()
$zip = [IO.Compression.ZipFile]::OpenRead($Path)
try { $count = $zip.Entries.Count } finally { $zip.Dispose() }
$sw.Stop()
Start-Sleep -Seconds 7   # rclone writes the cached ranges when the file handle really closes (5 s)
$after = LogStats $RcloneLog
[pscustomobject]@{
    SizeMB         = [Math]::Round((Get-Item -LiteralPath $Path).Length / 1MB, 1)
    Entries        = $count
    Seconds        = [Math]::Round($sw.Elapsed.TotalSeconds, 2)
    RangeOpens     = $after.RangeOpens - $before.RangeOpens
    Quota403       = $after.Quota403 - $before.Quota403
    CachedBeforeMB = [Math]::Round($cachedBefore / 1MB, 2)
    CachedAfterMB  = [Math]::Round((CachedBytes $name) / 1MB, 2)
} | Format-List

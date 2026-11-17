# Reads a file from start to end the way an installer / copy does, and reports the speed second by second.
# Also counts Google "quota" answers (403) rclone logged while the read was running.
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$RcloneLog = "$env:LOCALAPPDATA\Cloud-SSD\logs\rclone-cloudssd.log",
    [int]$BlockKB = 1024,
    [long]$MaxMB = 0
)
$ErrorActionPreference = 'Stop'
function LogStats($file) {
    $q = 0; $rl = 0; $n = 0; $opens = 0
    $fs = [IO.File]::Open($file, 'Open', 'Read', 'ReadWrite,Delete')
    try {
        $sr = New-Object IO.StreamReader($fs)
        while ($null -ne ($l = $sr.ReadLine())) {
            $n++
            if ($l.Contains('Error 403')) { $q++ }
            if ($l.Contains('Rate limited')) { $rl++ }
            if ($l.Contains('ChunkedReader.openRange') -or $l.Contains('ChunkedReader.Open')) { $opens++ }
        }
    } finally { $fs.Dispose() }
    [pscustomobject]@{ Lines = $n; Quota403 = $q; RateLimited = $rl; RangeOpens = $opens }
}
$before = LogStats $RcloneLog
$len = (Get-Item -LiteralPath $Path).Length
$buf = New-Object byte[] ($BlockKB * 1024)
$sw = [Diagnostics.Stopwatch]::StartNew()
$fs = New-Object IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite, 1, [IO.FileOptions]::SequentialScan)
$openMs = $sw.ElapsedMilliseconds
$total = 0L; $lastT = 0; $lastB = 0L; $firstByteMs = -1; $perSec = New-Object Collections.Generic.List[string]
try {
    while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) {
        if ($firstByteMs -lt 0) { $firstByteMs = $sw.ElapsedMilliseconds }
        $total += $n
        $t = [int]($sw.ElapsedMilliseconds / 1000)
        if ($t -gt $lastT) { $perSec.Add(('{0}s:{1:N1}' -f $t, (($total - $lastB) / 1MB / ($t - $lastT)))); $lastT = $t; $lastB = $total }
        if ($MaxMB -gt 0 -and $total -ge $MaxMB * 1MB) { break }
    }
} finally { $fs.Dispose() }
$sw.Stop()
$after = LogStats $RcloneLog
$sec = [Math]::Max(0.001, $sw.Elapsed.TotalSeconds)
[pscustomobject]@{
    SizeMB      = [Math]::Round($len / 1MB, 1)
    ReadMB      = [Math]::Round($total / 1MB, 1)
    Seconds     = [Math]::Round($sec, 2)
    MBperSec    = [Math]::Round($total / 1MB / $sec, 2)
    OpenMs      = $openMs
    FirstByteMs = $firstByteMs
    Quota403    = $after.Quota403 - $before.Quota403
    RateLimited = $after.RateLimited - $before.RateLimited
    RangeOpens  = $after.RangeOpens - $before.RangeOpens
    LogLines    = $after.Lines - $before.Lines
} | Format-List
'MB each second: ' + ($perSec -join '  ')

<#
  Cloud drive par file ko PEHLI baar kholne ka samay, hisson mein: handle kholna | pehle 64 KB | agla 1 MB.
  Sirf woh files jo abhi laptop ki cache mein nahi hain. Naam nahi chhapte (sirf size aur samay).
    powershell -ExecutionPolicy Bypass -File .work\speed\first-open.ps1 -Cloud G [-Count 10]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud, [int] $Count = 10, [int] $MinKB = 300)
$root = $Cloud.ToUpper() + ':\'
$cache = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD'
$picked = New-Object System.Collections.Generic.List[IO.FileInfo]
$queue = New-Object System.Collections.Generic.Queue[string]
$queue.Enqueue($root)
$seenDirs = 0
while ($queue.Count -gt 0 -and $picked.Count -lt $Count -and $seenDirs -lt 400) {
    $d = $queue.Dequeue(); $seenDirs++
    try {
        foreach ($s in [IO.Directory]::GetDirectories($d)) { $queue.Enqueue($s) }
        $took = 0
        foreach ($f in (New-Object IO.DirectoryInfo($d)).GetFiles()) {
            if ($f.Length -lt $MinKB * 1KB) { continue }
            $rel = $f.FullName.Substring($root.Length)
            if (Test-Path -LiteralPath (Join-Path $cache $rel)) { continue }   # cache mein hai: "pehli baar" nahi
            $picked.Add($f); $took++
            if ($took -ge 2 -or $picked.Count -ge $Count) { break }
        }
    } catch { }
}
"files not in the cache picked: $($picked.Count) (looked into $seenDirs folders)"
$buf = New-Object byte[] (1MB)
'{0,10} {1,10} {2,12} {3,12}   {4}' -f 'size MB', 'open ms', 'first 64KB', 'next 1MB', 'total ms'
$tot = @()
foreach ($f in $picked) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $s = [IO.File]::OpenRead($f.FullName); $tOpen = $sw.Elapsed.TotalMilliseconds
        [void]$s.Read($buf, 0, 65536); $tFirst = $sw.Elapsed.TotalMilliseconds
        [void]$s.Read($buf, 0, $buf.Length); $tNext = $sw.Elapsed.TotalMilliseconds
        $s.Close()
        '{0,10:0.0} {1,10:0} {2,12:0} {3,12:0}   {4:0}' -f ($f.Length / 1MB), $tOpen, ($tFirst - $tOpen), ($tNext - $tFirst), $tNext
        $tot += $tNext
    } catch { '{0,10:0.0}   error: {1}' -f ($f.Length / 1MB), $_.Exception.InnerException.Message }
}
if ($tot.Count) { $a = @($tot | Sort-Object); "median total {0:0} ms, slowest {1:0} ms, over 2 s: {2} of {3}" -f $a[[int][math]::Floor(($a.Count - 1) / 2)], $a[-1], @($a | Where-Object { $_ -ge 2000 }).Count, $a.Count }

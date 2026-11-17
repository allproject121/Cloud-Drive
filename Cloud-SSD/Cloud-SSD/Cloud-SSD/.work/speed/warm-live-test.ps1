<#
  Asli jaanch: "folder khulte hi uski files taiyaar".
   1) cloud drive par ek aisa folder dhoondhta hai jisme kai files abhi cache mein nahi hain
   2) use File Explorer mein kholta hai (Fast drive ke link ke raaste, agar -Fast diya ho)
   3) app ke log mein "Folder ready to open" ka intezaar
   4) us folder ki files kholne ka samay naapta hai (open | pehle 64 KB)
   5) Explorer ki wahi window band karta hai
  Naam nahi chhapte.
    powershell -ExecutionPolicy Bypass -File .work\speed\warm-live-test.ps1 -Cloud G [-Fast W]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud, [string] $Fast = '', [int] $MinFiles = 5, [int] $WaitSeconds = 120)
$root = $Cloud.ToUpper() + ':\'
$cache = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD'
$log = Join-Path $env:LOCALAPPDATA ("Cloud-SSD\logs\cloudssd-" + (Get-Date).ToString('yyyyMMdd') + '.log')
function LogLines { $fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite'); $sr = New-Object IO.StreamReader($fs); $t = $sr.ReadToEnd(); $fs.Close(); @($t -split "`n") }

# 1) folder with uncached files (not at the top: the fast drive's top holds links)
$pick = $null; $files = @()
$q = New-Object System.Collections.Generic.Queue[string]; $q.Enqueue($root); $n = 0
while ($q.Count -gt 0 -and -not $pick -and $n -lt 800) {
    $d = $q.Dequeue(); $n++
    try {
        foreach ($s in [IO.Directory]::GetDirectories($d)) { $q.Enqueue($s) }
        if ($d -eq $root) { continue }
        $cand = @((New-Object IO.DirectoryInfo($d)).GetFiles() | Where-Object { $_.Length -ge 100KB -and $_.Length -le 40MB -and -not (Test-Path -LiteralPath (Join-Path $cache $_.FullName.Substring($root.Length))) })
        if ($cand.Count -ge $MinFiles) { $pick = $d; $files = $cand }
    } catch { }
}
if (-not $pick) { "no folder with $MinFiles uncached files found (looked into $n)"; exit 1 }
$depth = $pick.Substring($root.Length).Split('\').Count
"folder chosen: depth $depth, uncached files in it: $($files.Count), sizes MB: " + (($files | Sort-Object Length | ForEach-Object { [math]::Round($_.Length / 1MB, 1) }) -join ', ')

# 2) open it in File Explorer
$show = if ($Fast) { ($Fast.ToUpper() + ':\') + $pick.Substring($root.Length) } else { $pick }
$before = (LogLines).Count
$t0 = Get-Date
Start-Process explorer.exe -ArgumentList ('"' + $show + '"')
"opened in File Explorer through drive " + $show.Substring(0, 2) + " at " + $t0.ToString('HH:mm:ss')

# 3) wait for the app
$sw = [Diagnostics.Stopwatch]::StartNew(); $line = $null
while ($sw.Elapsed.TotalSeconds -lt $WaitSeconds) {
    $line = @(LogLines | Select-Object -Skip $before) | Where-Object { $_ -match 'Folder ready to open' } | Select-Object -First 1
    if ($line) { break }
    Start-Sleep -Milliseconds 700
}
if ($line) { "app: " + ($line -replace '^.*ArchiveWarmer: ', '') + "   (seen {0:0.0} s after the folder was opened)" -f $sw.Elapsed.TotalSeconds }
else { "app did NOT report the folder within $WaitSeconds s" }

# 4) how long do its files take to open now?
$buf = New-Object byte[] 65536; $rows = @()
foreach ($f in ($files | Sort-Object Length)) {
    $x = [Diagnostics.Stopwatch]::StartNew()
    try { $s = [IO.File]::OpenRead($f.FullName); $o = $x.Elapsed.TotalMilliseconds; [void]$s.Read($buf, 0, $buf.Length); $r = $x.Elapsed.TotalMilliseconds; $s.Close(); $rows += [pscustomobject]@{ MB = [math]::Round($f.Length / 1MB, 1); OpenMs = [int]$o; First64Ms = [int]($r - $o) } } catch { }
}
$rows | Format-Table -AutoSize | Out-String
$a = @($rows | ForEach-Object { $_.OpenMs + $_.First64Ms } | Sort-Object)
if ($a.Count) { "open + first 64 KB: median {0} ms, slowest {1} ms, over 1 s: {2} of {3}" -f $a[[int][math]::Floor(($a.Count - 1) / 2)], $a[-1], @($a | Where-Object { $_ -ge 1000 }).Count, $a.Count }

# 5) close the Explorer window this test opened
try {
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in @($shell.Windows())) { try { if ($w.LocationURL -and ([Uri]$w.LocationURL).LocalPath.TrimEnd('\') -ieq $show.TrimEnd('\')) { $w.Quit() } } catch { } }
    'test window closed'
} catch { 'could not close the test window: ' + $_.Exception.Message }

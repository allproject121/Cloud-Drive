# Drive ke log se naapta hai ki har tarah ki call (folder banana, kholna, likhna ...) mein kitna samay gaya.
# Sirf padhta hai. File ke naam nahi chhapte.
#   powershell -ExecutionPolicy Bypass -File .work\speed\call-times.ps1 -Since "09:37:10" [-Until "09:50:00"]
param(
    [Parameter(Mandatory)] [string] $Since,
    [string] $Until = '23:59:59',
    [string] $Log = (Join-Path $env:LOCALAPPDATA 'Cloud-SSD\logs\rclone-cloudssd.log')
)

$fs = [IO.File]::Open($Log, 'Open', 'Read', 'ReadWrite')
$sr = New-Object IO.StreamReader($fs)
$all = $sr.ReadToEnd()
$fs.Close()

$ops = 'Getattr|Opendir|Releasedir|OpenEx|Open|Create|CreateEx|Mkdir|Write|Truncate|Utimens|Flush|Release|Readdir|Unlink|Rmdir|Rename|Fsync|Read|Statfs|Access|Chmod'
$rx = [regex]('^\d{4}/\d\d/\d\d (\d\d):(\d\d):(\d\d)[.](\d{6}) DEBUG : (.*?): (>?)(' + $ops + '):')
$open = @{}; $sum = @{}; $cnt = @{}; $max = @{}
$slow = New-Object System.Collections.Generic.List[object]

foreach ($line in ($all -split "`n")) {
    if ($line.Length -lt 40) { continue }
    $hms = $line.Substring(11, 8)
    if ($hms -lt $Since -or $hms -gt $Until) { continue }
    # Utimens do "shuru" line likhta hai (tmsp= aur SetModTime); doosri ko chhodo, warna jodi bigad jati hai.
    if ($line.Contains('Utimens: SetModTime')) { continue }
    $m = $rx.Match($line)
    if (-not $m.Success) { continue }
    $t = [int]$m.Groups[1].Value * 3600 + [int]$m.Groups[2].Value * 60 + [int]$m.Groups[3].Value + [int]$m.Groups[4].Value / 1e6
    $op = $m.Groups[7].Value
    $key = $m.Groups[5].Value + '|' + $op
    if ($m.Groups[6].Value -eq '') {
        if (-not $open.ContainsKey($key)) { $open[$key] = New-Object System.Collections.Generic.Queue[double] }
        $open[$key].Enqueue($t)
    }
    elseif ($open.ContainsKey($key) -and $open[$key].Count -gt 0) {
        $d = $t - $open[$key].Dequeue()
        $sum[$op] = [double]$sum[$op] + $d
        $cnt[$op] = [int]$cnt[$op] + 1
        if ($d -gt [double]$max[$op]) { $max[$op] = $d }
        if ($d -ge 1) { $slow.Add([pscustomobject]@{ At = $hms; Op = $op; Sec = [math]::Round($d, 1) }) }
    }
}

'NOW ' + (Get-Date).ToString('HH:mm:ss')
$rows = foreach ($k in $sum.Keys) {
    [pscustomobject]@{ Op = $k; Calls = $cnt[$k]; TotalSec = [math]::Round($sum[$k], 1); AvgMs = [math]::Round(1000 * $sum[$k] / $cnt[$k], 1); MaxSec = [math]::Round($max[$k], 1) }
}
$rows | Sort-Object TotalSec -Descending | Format-Table -AutoSize | Out-String

$tot = [math]::Round((($slow | Measure-Object Sec -Sum).Sum), 0)
"calls that took 1 s or more: $($slow.Count), together $tot s"
foreach ($g in ($slow | Group-Object Op)) {
    '{0,-10} {1,4} calls  {2,6} s' -f $g.Name, $g.Count, [math]::Round((($g.Group | Measure-Object Sec -Sum).Sum), 0)
}
'--- slow calls per minute'
foreach ($g in ($slow | Group-Object { $_.At.Substring(0, 5) })) {
    $kinds = (($g.Group | Group-Object Op | ForEach-Object { $_.Name + ':' + $_.Count }) -join ' ')
    '{0}  {1,3} calls {2,5} s  ({3})' -f $g.Name, $g.Count, [math]::Round((($g.Group | Measure-Object Sec -Sum).Sum), 0), $kinds
}
$stuck = 0
foreach ($q in $open.Values) { $stuck += $q.Count }
"calls still waiting for an answer right now: $stuck"

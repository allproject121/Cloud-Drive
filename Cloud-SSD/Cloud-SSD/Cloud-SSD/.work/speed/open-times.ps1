<#
  "Kholne mein der kahan lagti hai?" Sirf padhta hai, kuch badalta nahi. File / folder ke naam nahi chhapte (sirf number).
    1) har drive letter ko chhoone ka samay (mara hua letter Explorer ko rok sakta hai)
    2) cloud drive ke folder kholna: pehli baar (thanda) aur doosri baar
    3) cloud ki file kholna: pehle 64 KB padhna, pehli baar aur doosri baar
    powershell -ExecutionPolicy Bypass -File .work\speed\open-times.ps1 -Cloud G [-Fast W] [-Folders 12] [-Files 8]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud, [string] $Fast = '', [int] $Folders = 12, [int] $Files = 8)
function Ms([scriptblock] $b) { $sw = [Diagnostics.Stopwatch]::StartNew(); try { & $b | Out-Null } catch { }; [math]::Round($sw.Elapsed.TotalMilliseconds) }
function Stats($name, $list) {
    $a = @($list | Sort-Object)
    if ($a.Count -eq 0) { "$name : nothing to measure"; return }
    '{0,-46} n={1,-3} median {2,6} ms   slowest {3,6} ms   over 1 s: {4}' -f $name, $a.Count, $a[[int][math]::Floor(($a.Count - 1) / 2)], $a[-1], @($a | Where-Object { $_ -ge 1000 }).Count
}

'--- 1) touching each drive letter'
foreach ($d in [IO.DriveInfo]::GetDrives()) {
    $n = $d.Name
    $t1 = Ms { $d.IsReady }
    $t2 = Ms { [IO.Directory]::Exists($n) }
    $t3 = Ms { Get-ChildItem -LiteralPath $n -Force -ErrorAction Stop | Select-Object -First 1 }
    '{0}  ready-check {1,5} ms   exists {2,5} ms   first listing {3,5} ms   ({4})' -f $n, $t1, $t2, $t3, $(if ($d.IsReady) { 'ok' } else { 'NOT READY' })
}

$root = $Cloud.ToUpper() + ':\'
'--- 2) opening folders on the cloud drive ' + $root
$top = @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue)
$pick = New-Object System.Collections.Generic.List[string]
foreach ($t in $top) { $pick.Add($t.FullName) }
foreach ($t in $top) {
    if ($pick.Count -ge $Folders * 3) { break }
    foreach ($s in @(Get-ChildItem -LiteralPath $t.FullName -Directory -Force -ErrorAction SilentlyContinue | Select-Object -First 4)) { $pick.Add($s.FullName) }
}
$sub = @($pick | Select-Object -Skip $top.Count | Select-Object -First $Folders)
$cold = foreach ($p in $sub) { Ms { [IO.Directory]::GetFileSystemEntries($p) } }
$warm = foreach ($p in $sub) { Ms { [IO.Directory]::GetFileSystemEntries($p) } }
Stats 'folder, first open' $cold
Stats 'folder, second open' $warm

'--- 3) opening files on the cloud drive (first 64 KB)'
$sample = New-Object System.Collections.Generic.List[IO.FileInfo]   # ($files nahi: woh -Files wala number hai)
foreach ($p in $pick) {
    if ($sample.Count -ge $Files) { break }
    $f = Get-ChildItem -LiteralPath $p -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 200KB } | Select-Object -First 1
    if ($f) { $sample.Add($f) }
}
$buf = New-Object byte[] 65536
$c1 = foreach ($f in $sample) { Ms { $s = [IO.File]::OpenRead($f.FullName); [void]$s.Read($buf, 0, $buf.Length); $s.Close() } }
$c2 = foreach ($f in $sample) { Ms { $s = [IO.File]::OpenRead($f.FullName); [void]$s.Read($buf, 0, $buf.Length); $s.Close() } }
Stats 'file, first open' $c1
Stats 'file, second open' $c2
'   sizes (MB): ' + (($sample | ForEach-Object { [math]::Round($_.Length / 1MB, 1) }) -join ', ')

if ($Fast) {
    $fr = $Fast.ToUpper() + ':\'
    '--- 4) the fast drive ' + $fr
    $t = Ms { Get-ChildItem -LiteralPath $fr -Force }
    "listing its top folder: $t ms"
    $links = @(Get-ChildItem -LiteralPath $fr -Directory -Force -ErrorAction SilentlyContinue | Select-Object -First 8)
    $l1 = foreach ($l in $links) { Ms { [IO.Directory]::GetFileSystemEntries($l.FullName) } }
    Stats 'cloud folder through its link' $l1
}

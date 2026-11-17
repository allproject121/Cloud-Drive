<#
  TAJURBA: "pehle laptop par likho, Google par baad mein" (local staging).
  Ek alag test drive (default Q:) jodta hai jo wahi teen Google account dikhati hai, par NAYI cheezein (file / folder)
  laptop ke ek staging folder mein banti hain (rclone union: staging pehla upstream, Google wale ":nc" = wahan kuch naya nahi).
  Phir usi par "install jaisa" kaam (ek install hue app ki saari files ek-ek karke likhna) naapta hai.
  Asli drives (G:/Y:/Z:) ko nahi chhuta. Google par kuch nahi likhta. Aakhir mein test drive, staging aur cache hata deta hai.
  File ke naam nahi chhapte. Config ka password sirf child process ke environment mein jata hai.
    powershell -ExecutionPolicy Bypass -File .work\speed\stage-test.ps1 [-Letter Q] [-Folder "MiniMax Code"] [-Refresh]
#>
param([string] $Letter = 'Q', [string] $Folder = 'MiniMax Code', [switch] $Refresh, [int] $Tps = 10,
    [ValidateSet('union', 'local')] [string] $Mode = 'union')   # local = sirf laptop ka folder (Google bilkul nahi): sabse tez mumkin
$ErrorActionPreference = 'Stop'
$inst = Join-Path $env:LOCALAPPDATA 'Programs\Cloud-SSD'
$rclone = Join-Path $inst 'tools\rclone\rclone.exe'
$data = Join-Path $env:LOCALAPPDATA 'Cloud-SSD'
$conf = Join-Path $data 'rclone.conf'
$letter = $Letter.TrimEnd(':').ToUpper()
if (Test-Path "${letter}:\") { "letter ${letter}: is in use"; exit 1 }

$src = Join-Path $data "cache\m-cloudssd\vfs\CloudSSD\$Folder"
if (-not (Test-Path -LiteralPath $src)) { "source not found in the drive's cache: $Folder"; exit 2 }
$files = @(Get-ChildItem -LiteralPath $src -Recurse -File -Force)
$dirs = @(Get-ChildItem -LiteralPath $src -Recurse -Directory -Force)
"source: $($files.Count) files, $($dirs.Count) folders, $([math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 1)) MB"

$work = Join-Path $env:TEMP 'cssd-stage-test'
# Is app ke raaste 260 akshar se lambe hain; Remove-Item unhe nahi hata pata, .NET "\\?\" ke saath hata deta hai.
function Remove-Work { if ($work -like '*\cssd-stage-test' -and (Test-Path $work)) { try { [IO.Directory]::Delete('\\?\' + $work, $true) } catch { } } }
Remove-Work
$stage = Join-Path $work 'staging'; $cache = Join-Path $work 'cache'; $log = Join-Path $work 'rclone.log'
$null = New-Item -ItemType Directory -Force -Path $stage, $cache

$p = New-Object Diagnostics.ProcessStartInfo (Join-Path $inst 'cpx.exe'), "secret emit-config-pass --home `"$data`""
$p.UseShellExecute = $false; $p.RedirectStandardOutput = $true; $p.CreateNoWindow = $true
$c = [Diagnostics.Process]::Start($p); $pass = $c.StandardOutput.ReadToEnd(); $c.WaitForExit()

$stageFwd = $stage -replace '\\', '/'
$remote = if ($Mode -eq 'local') { $stage } else { ":union,upstreams='$stageFwd gdrive::nc gdrive2::nc gdrive3::nc',action_policy=epall,create_policy=ff,search_policy=ff:" }
"mode: $Mode"
$a = @('mount', $remote, "${letter}:",
    '--vfs-cache-mode', 'full', '--cache-dir', $cache, '--vfs-write-back', '5s', '--dir-cache-time', '72h', '--attr-timeout', '24h',
    '--poll-interval', '1m', '--vfs-fast-fingerprint', '--no-checksum', '--links', '--file-perms', '0777', '--dir-perms', '0777',
    '--filter', '- Cloud-SSD Devices/**', '--drive-pacer-min-sleep', '100ms', '--drive-pacer-burst', '10',
    '--volname', 'stage test', '--log-file', $log, '--log-format', 'date,time,microseconds', '-vv')
if ($Tps -gt 0) { $a += @('--tpslimit', "$Tps") }
if ($Refresh) { $a += '--vfs-refresh' }
$psi = New-Object Diagnostics.ProcessStartInfo $rclone
$psi.Arguments = ($a | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
$psi.EnvironmentVariables['RCLONE_CONFIG'] = $conf
$psi.EnvironmentVariables['RCLONE_ASK_PASSWORD'] = 'false'
$psi.EnvironmentVariables['RCLONE_CONFIG_PASS'] = $pass
$sw = [Diagnostics.Stopwatch]::StartNew()
$m = [Diagnostics.Process]::Start($psi)
try {
    while ($sw.Elapsed.TotalSeconds -lt 240 -and -not $m.HasExited) { if (Test-Path "${letter}:\") { break }; Start-Sleep -Milliseconds 200 }
    if (-not (Test-Path "${letter}:\")) { "test drive did not appear (rclone exited: $($m.HasExited))"; if (Test-Path $log) { Get-Content $log -Tail 5 | ForEach-Object { $_.Substring(0, [math]::Min(200, $_.Length)) } }; exit 3 }
    "test drive ${letter}: visible in {0:0.0} s; top-level items it shows: {1}" -f $sw.Elapsed.TotalSeconds, @(Get-ChildItem "${letter}:\" -Force -ErrorAction SilentlyContinue).Count

    $to = "${letter}:\_stage-test\$Folder"
    $sw.Restart()
    $null = robocopy $src $to /E /MT:1 /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
    $code = $LASTEXITCODE
    $secs = $sw.Elapsed.TotalSeconds
    "INSTALL-LIKE WRITE: {0:0.0} s  (robocopy code {1})" -f $secs, $code
    Start-Sleep -Seconds 8   # 5 s write-back: files staging mein pahunch jayein
    $onDrive = @(Get-ChildItem -LiteralPath $to -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    $inStage = @(Get-ChildItem -LiteralPath $stage -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    $dirStage = @(Get-ChildItem -LiteralPath $stage -Recurse -Directory -Force -ErrorAction SilentlyContinue).Count
    "files visible on the test drive: $onDrive; landed in local staging: $inStage files, $dirStage folders"

    # kis call mein samay gaya
    $lf = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite'); $lr = New-Object IO.StreamReader($lf); $all = $lr.ReadToEnd(); $lf.Close()
    $rx = [regex]'(?m)^\d{4}/\d\d/\d\d (\d\d):(\d\d):(\d\d)[.](\d{6}) DEBUG : (.*?): (>?)(Mkdir|Readdir|Opendir|Getattr|CreateEx|Open|Release|Write|Utimens):'
    $open = @{}; $sum = @{}; $cnt = @{}
    foreach ($x in $rx.Matches($all)) {
        if ($x.Value.Contains('SetModTime')) { continue }
        $t = [int]$x.Groups[1].Value * 3600 + [int]$x.Groups[2].Value * 60 + [int]$x.Groups[3].Value + [int]$x.Groups[4].Value / 1e6
        $op = $x.Groups[7].Value; $key = $x.Groups[5].Value + '|' + $op
        if ($x.Groups[6].Value -eq '') { if (-not $open.ContainsKey($key)) { $open[$key] = New-Object System.Collections.Generic.Queue[double] }; $open[$key].Enqueue($t) }
        elseif ($open.ContainsKey($key) -and $open[$key].Count -gt 0) { $d = $t - $open[$key].Dequeue(); $sum[$op] = [double]$sum[$op] + $d; $cnt[$op] = [int]$cnt[$op] + 1 }
    }
    foreach ($k in ($sum.Keys | Sort-Object { -$sum[$_] })) { '   {0,-9} {1,5} calls {2,7:0.0} s  avg {3,7:0.0} ms' -f $k, $cnt[$k], $sum[$k], (1000 * $sum[$k] / $cnt[$k]) }
    "   log lines: " + ($all.Split([char]10)).Count + "   lines per kind (top): " + ((([regex]::Matches($all, '(?m)^.{27}(DEBUG|INFO|NOTICE|ERROR)\s*: [^:]*: (>?[A-Za-z_]+)') | ForEach-Object { $_.Groups[2].Value } | Group-Object | Sort-Object Count -Descending | Select-Object -First 12 | ForEach-Object { $_.Name + '=' + $_.Count }) -join ' '))
    "   Google 403 in this test: " + ([regex]::Matches($all, 'Error 403')).Count
}
finally {
    if (-not $m.HasExited) { $m.Kill(); $null = $m.WaitForExit(8000) }
    Start-Sleep -Seconds 2
    "test drive removed: " + (-not (Test-Path "${letter}:\"))
    Remove-Work
    "test files removed: " + (-not (Test-Path $work))
}

<#
  Jab cloud drive par ek file PEHLI baar khulti hai to poori file kaun padhta hai?
  Ek cache-se-bahar file chunta hai, kholne se pehle aur baad har process ke "kitna padha" counter dekhta hai, aur sabse zyada
  padhne wale process dikhata hai. Sirf padhta hai. File ka naam nahi chhapta.
    powershell -ExecutionPolicy Bypass -File .work\speed\who-reads.ps1 -Cloud G [-MinMB 6] [-MaxMB 30]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud, [double] $MinMB = 6, [double] $MaxMB = 30, [switch] $OpenOnly)
$root = $Cloud.ToUpper() + ':\'
$cache = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD'
$file = $null
$queue = New-Object System.Collections.Generic.Queue[string]; $queue.Enqueue($root); $n = 0
while ($queue.Count -gt 0 -and -not $file -and $n -lt 600) {
    $d = $queue.Dequeue(); $n++
    try {
        foreach ($s in [IO.Directory]::GetDirectories($d)) { $queue.Enqueue($s) }
        foreach ($f in (New-Object IO.DirectoryInfo($d)).GetFiles()) {
            if ($f.Length -lt $MinMB * 1MB -or $f.Length -gt $MaxMB * 1MB) { continue }
            if (Test-Path -LiteralPath (Join-Path $cache $f.FullName.Substring($root.Length))) { continue }
            $file = $f; break
        }
    } catch { }
}
if (-not $file) { 'no suitable file outside the cache found'; exit 1 }
"file: {0:0.0} MB, extension {1}" -f ($file.Length / 1MB), $file.Extension

function Snap { $h = @{}; foreach ($p in (Get-CimInstance Win32_Process)) { $h[[int]$p.ProcessId] = [pscustomobject]@{ Name = $p.Name; Read = [double]$p.ReadTransferCount; Other = [double]$p.OtherTransferCount; Ops = [double]$p.ReadOperationCount } }; $h }
$before = Snap
$sw = [Diagnostics.Stopwatch]::StartNew()
$s = [IO.File]::Open($file.FullName, 'Open', 'Read', 'ReadWrite')
$tOpen = $sw.Elapsed.TotalMilliseconds
if (-not $OpenOnly) { $buf = New-Object byte[] 65536; [void]$s.Read($buf, 0, $buf.Length) }
$tRead = $sw.Elapsed.TotalMilliseconds
$s.Close()
Start-Sleep -Milliseconds 500
$after = Snap
"open took {0:0} ms; first 64 KB after that {1:0} ms" -f $tOpen, ($tRead - $tOpen)
$inCache = Join-Path $cache $file.FullName.Substring($root.Length)
if (Test-Path -LiteralPath $inCache) {
    # sparse file: asli kitna utra
    $sig = '[DllImport("kernel32.dll", CharSet=CharSet.Unicode)] public static extern uint GetCompressedFileSizeW(string n, out uint high);'
    $k = Add-Type -MemberDefinition $sig -Name K32 -Namespace CssdWho -PassThru
    $hi = [uint32]0; $lo = $k::GetCompressedFileSizeW($inCache, [ref]$hi)
    "downloaded into the cache during this: {0:0.0} MB of {1:0.0} MB" -f ((([uint64]$hi -shl 32) + $lo) / 1MB), ($file.Length / 1MB)
}
'--- processes that read the most during the open (MB read, read calls)'
$rows = foreach ($procId in $after.Keys) {
    if (-not $before.ContainsKey($procId)) { continue }
    $d = $after[$procId].Read - $before[$procId].Read
    $o = $after[$procId].Ops - $before[$procId].Ops
    if ($d -gt 200KB -or $o -gt 50) { [pscustomobject]@{ Process = $after[$procId].Name; Pid = $procId; ReadMB = [math]::Round($d / 1MB, 1); ReadCalls = [int]$o } }
}
$rows | Sort-Object ReadMB -Descending | Select-Object -First 8 | Format-Table -AutoSize | Out-String

# Drive ke log ki aakhri "badi" calls dikhata hai (folder banana, file banana, dheemi call), naam chhupa kar:
# raaste ki jagah sirf gehraai (kitne folder andar) aur file ka extension.
#   powershell -ExecutionPolicy Bypass -File .work\speed\last-ops.ps1 -Since "09:44:00" [-Last 60]
param(
    [Parameter(Mandatory)] [string] $Since,
    [int] $Last = 60,
    [string] $Log = (Join-Path $env:LOCALAPPDATA 'Cloud-SSD\logs\rclone-cloudssd.log')
)
$fs = [IO.File]::Open($Log, 'Open', 'Read', 'ReadWrite')
$sr = New-Object IO.StreamReader($fs)
$all = $sr.ReadToEnd()
$fs.Close()

$rx = [regex]'^\d{4}/\d\d/\d\d (\d\d:\d\d:\d\d)[.]\d{6} (DEBUG|INFO|ERROR|NOTICE)\s*: (.*?): (>?(Mkdir|CreateEx|Create|Rename|Unlink|Rmdir|Opendir|Readdir)):(.*)$'
$out = New-Object System.Collections.Generic.List[string]
$pace = @{}
foreach ($line in ($all -split "`n")) {
    if ($line.Length -lt 40) { continue }
    $hms = $line.Substring(11, 8)
    if ($hms -lt $Since) { continue }
    if ($line.Contains('pacer:')) {
        $k = $hms.Substring(0, 5)
        if ($line.Contains('Rate limited')) { $pace[$k] = [int]$pace[$k] + 1 }
        continue
    }
    $m = $rx.Match($line)
    if (-not $m.Success) { continue }
    $op = $m.Groups[4].Value
    if ($op -like '*Opendir' -or $op -like '*Readdir') { continue }
    $path = $m.Groups[3].Value.Trim('/')
    $depth = if ($path) { $path.Split('/').Count } else { 0 }
    $ext = [IO.Path]::GetExtension($path)
    $tail = $m.Groups[6].Value.Trim()
    if ($tail.Length -gt 40) { $tail = $tail.Substring(0, 40) }
    $out.Add(('{0}  {1,-10} depth={2,-2} ext={3,-6} {4}' -f $hms, $op, $depth, $ext, $tail))
}
'NOW ' + (Get-Date).ToString('HH:mm:ss') + "  (big calls since $Since : $($out.Count))"
$out | Select-Object -Last $Last
'--- "Rate limited" (403 ke baad rukna) per minute'
foreach ($k in ($pace.Keys | Sort-Object)) { '{0}  {1}' -f $k, $pace[$k] }

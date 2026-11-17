# Chalte hue installer ko naapta hai jo Z: (Cloud-SSD) par likh raha hai. Sirf padhta hai, kuch badalta nahi.
# Har 30 s: installer ne kitna likha, drive ki local cache mein kitni files, Google tak kitni pahunchi, kitne 403.
# File ke naam kahin nahi chhapte (sirf ginti).
#   powershell -ExecutionPolicy Bypass -File .work\speed\install-watch.ps1 -InstallerPid 12768 -Folder "MiniMax Code" -Since "09:37:10"
param(
    [Parameter(Mandatory)] [int] $InstallerPid,
    [Parameter(Mandatory)] [string] $Folder,
    [Parameter(Mandatory)] [string] $Since,          # HH:mm:ss, installer kab shuru hua
    [string] $Out = '',                              # khaali = is script ke paas install-watch.csv
    [int] $EverySeconds = 30,
    [int] $MaxMinutes = 90,
    [int] $QuietRounds = 6                           # itne round tak kuch na badle to "ruk gaya" maano
)

# PS 5.1 mein param ke default ke andar $PSScriptRoot khaali hota hai (file C:\ par jaane lagti thi), isliye yahan.
if (-not $Out) { $Out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'install-watch.csv' }
$cache = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\cache\m-cloudssd\vfs'
$log   = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\logs\rclone-cloudssd.log'
# Invariant: is PC ki bhasha mein '/' ki jagah '-' aa jata hai, aur log mein '/' hota hai.
$day   = (Get-Date).ToString('yyyy/MM/dd', [Globalization.CultureInfo]::InvariantCulture)

function Read-Shared([string] $path) {
    $fs = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
    try { $sr = New-Object IO.StreamReader($fs); return $sr.ReadToEnd() } finally { $fs.Close() }
}

'time,installerAlive,installerWriteMB,cacheFiles,cacheFolders,cacheMB,queued,uploadedOK,err403,sleeps' | Set-Content -Path $Out -Encoding utf8
$stopAt = (Get-Date).AddMinutes($MaxMinutes)
$last = ''; $quiet = 0

while ((Get-Date) -lt $stopAt) {
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$InstallerPid" -ErrorAction SilentlyContinue
    $alive = [bool]$proc
    $wmb = if ($proc) { [math]::Round($proc.WriteTransferCount / 1MB, 1) } else { -1 }

    $files = 0; $dirs = 0; $mb = 0
    foreach ($root in (Get-ChildItem $cache -Directory -ErrorAction SilentlyContinue)) {
        $p = Join-Path $root.FullName $Folder
        if (Test-Path -LiteralPath $p) {
            $f = @(Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue)
            $files += $f.Count
            $dirs  += @(Get-ChildItem -LiteralPath $p -Recurse -Directory -Force -ErrorAction SilentlyContinue).Count
            $mb    += [math]::Round((($f | Measure-Object Length -Sum).Sum) / 1MB, 1)
        }
    }

    $q = 0; $ok = 0; $e403 = 0; $sl = 0
    foreach ($line in ((Read-Shared $log) -split "`n")) {
        if ($line.Length -lt 20 -or -not $line.StartsWith($day)) { continue }
        if ($line.Substring(11, 8) -lt $Since) { continue }
        if ($line.Contains('queuing for upload')) { $q++ }
        elseif ($line.Contains('upload succeeded')) { $ok++ }
        if ($line.Contains('Error 403')) { $e403++ }
        if ($line.Contains('increasing sleep')) { $sl++ }
    }

    $row = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}' -f (Get-Date).ToString('HH:mm:ss'), $alive, $wmb, $files, $dirs, $mb, $q, $ok, $e403, $sl
    Add-Content -Path $Out -Value $row -Encoding utf8

    $now = "$wmb|$files|$ok|$q"
    if ($now -eq $last) { $quiet++ } else { $quiet = 0 }
    $last = $now
    # Khatam: installer band ho gaya AUR saari queued files upar pahunch gayi, ya bahut der se kuch nahi badla.
    if (-not $alive -and $ok -ge $q -and $quiet -ge 2) { Add-Content $Out 'DONE: installer closed and every queued file is uploaded' ; break }
    if ($quiet -ge $QuietRounds -and $ok -ge $q) { Add-Content $Out 'DONE: nothing changed for a while and the upload queue is empty'; break }
    Start-Sleep -Seconds $EverySeconds
}
Get-Content $Out | Select-Object -Last 3

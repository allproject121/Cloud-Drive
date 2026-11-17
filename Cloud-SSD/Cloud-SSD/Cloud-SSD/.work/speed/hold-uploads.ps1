# TAJURBA (17 Nov 2026): jab tak koi installer drive par naye folder / files bana raha hai, tab tak us drive ke
# upload thodi der ke liye taal do. Wajah: shared Google key par har 403 ke baad rclone sab calls ko 1-16 s rokta hai;
# 4 upload ek saath chalte hain to "naya folder banao" wali call unki line mein 36-120 s phansti hai aur kabhi fail (EIO).
#
# Kya karta hai: rclone ke apne rc (vfs/queue, vfs/queue-set-expiry) se line mein lagi files ka "kab upload ho" samay
# aage khiskata hai. Koi file hatti / badalti nahi; files drive ki local cache mein rehti hain aur baad mein upload hoti hain.
# Rok apne aap khatam hoti hai: har rok sirf -HoldSeconds ki hai, script mar bhi jaye to uske baad upload chal padte hain.
# Password sirf memory mein rehta hai, kahin chhapta nahi. File ke naam nahi chhapte.
#
#   powershell -ExecutionPolicy Bypass -File .work\speed\hold-uploads.ps1 -Letter Z -InstallerPid 12768
#   powershell -ExecutionPolicy Bypass -File .work\speed\hold-uploads.ps1 -Letter Z -ReleaseNow      # sab rok abhi hatao
param(
    [string] $Letter = 'Z',
    [int] $InstallerPid = 0,
    [int] $HoldSeconds = 300,        # ek baar mein kitna taalna
    [int] $QuietSeconds = 90,        # itni der koi nayi file na aaye to upload chhod do
    [int] $MaxMinutes = 60,
    [switch] $ReleaseNow
)

Add-Type -AssemblyName System.Security
$state = Join-Path $env:LOCALAPPDATA 'Cloud-SSD\mounts.state.json'
$m = (Get-Content $state -Raw | ConvertFrom-Json) | Where-Object { "$($_.Letter)" -eq $Letter } | Select-Object -First 1
if (-not $m) { "Drive $Letter`: mounts.state.json mein nahi mili."; exit 2 }
$entropy = [Text.Encoding]::UTF8.GetBytes('CloudPlayX.v1.secret')
$pass = [Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($m.PassProtected), $entropy, 'CurrentUser'))
$auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($m.User):$pass"))
$base = "http://127.0.0.1:$($m.Port)/"

function Rc([string] $path, $body) {
    $json = if ($body) { $body | ConvertTo-Json -Compress } else { '{}' }
    Invoke-RestMethod -Uri ($base + $path) -Method Post -Headers @{ Authorization = $auth } -ContentType 'application/json' -Body $json -TimeoutSec 10
}

function Set-Expiry($items, [double] $seconds) {
    $n = 0
    foreach ($it in $items) {
        try { [void](Rc 'vfs/queue-set-expiry' @{ id = $it.id; expiry = $seconds }); $n++ } catch { }
    }
    $n
}

function Waiting { @((Rc 'vfs/queue' $null).queue | Where-Object { -not $_.uploading }) }

if ($ReleaseNow) {
    $w = Waiting
    $n = Set-Expiry $w 5
    "{0}  rok hatayi: {1} files ab 5 s mein upload ke liye taiyaar" -f (Get-Date).ToString('HH:mm:ss'), $n
    exit 0
}

$stopAt = (Get-Date).AddMinutes($MaxMinutes)
$maxId = -1; $lastNew = Get-Date; $holding = $true; $lastPrint = [datetime]::MinValue
"{0}  shuru: drive {1}: (rc port {2}), installer PID {3}" -f (Get-Date).ToString('HH:mm:ss'), $Letter, $m.Port, $InstallerPid

try {
    while ((Get-Date) -lt $stopAt) {
        if ($InstallerPid -gt 0 -and -not (Get-Process -Id $InstallerPid -ErrorAction SilentlyContinue)) { 'installer band ho gaya'; break }
        try { $q = @((Rc 'vfs/queue' $null).queue) } catch { Start-Sleep 3; continue }
        $wait = @($q | Where-Object { -not $_.uploading })
        $up = $q.Count - $wait.Count
        $top = if ($q.Count) { ($q | Measure-Object id -Maximum).Maximum } else { $maxId }
        if ($top -gt $maxId) { $maxId = $top; $lastNew = Get-Date }
        $quietFor = ((Get-Date) - $lastNew).TotalSeconds

        $did = 0
        if ($quietFor -lt $QuietSeconds) {
            # Kaam chal raha hai: jo files jald upload hone wali hain unhe aage khiskao.
            $soon = @($wait | Where-Object { $_.expiry -lt ($HoldSeconds / 2) })
            if ($soon.Count) { $did = Set-Expiry $soon $HoldSeconds }
            $holding = $true
        }
        elseif ($holding) {
            # Shaanti: installer kuch naya nahi likh raha, ab upload chalne do.
            $did = Set-Expiry $wait 5
            $holding = $false
            "{0}  {1} s se koi nayi file nahi: {2} files upload ke liye chhodi" -f (Get-Date).ToString('HH:mm:ss'), [int]$quietFor, $did
        }

        if (((Get-Date) - $lastPrint).TotalSeconds -ge 30) {
            "{0}  line mein {1}, upload chal rahe {2}, abhi taale {3}, rok {4}" -f (Get-Date).ToString('HH:mm:ss'), $wait.Count, $up, $did, $(if ($holding) { 'lagi' } else { 'hati' })
            $lastPrint = Get-Date
        }
        Start-Sleep -Seconds 2
    }
}
finally {
    try { $n = Set-Expiry (Waiting) 5; "{0}  khatam: {1} files upload ke liye chhodi" -f (Get-Date).ToString('HH:mm:ss'), $n } catch { 'khatam (rok 5 minute mein apne aap hat jayegi)' }
}

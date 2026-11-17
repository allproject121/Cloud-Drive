<#
  Asli app ke "Fast drive" (Hybrid) ki jaanch. App mein Fast drive ON hona chahiye.
    A) install jaisa likhna: 853 files tez drive ke ek naye folder mein -> samay; folder turant hata diya jata hai (upload shuru hone se pehle).
    B) chhota folder (default "locales") tez drive par -> app ke log mein "upload finished" ka intezaar -> cloud drive par ginti milao -> dono jagah se hatao.
    C) cloud ka purana folder link ke raaste kholna.
  File ke naam nahi chhapte.
    powershell -ExecutionPolicy Bypass -File .work\speed\fast-live-test.ps1 -Fast W -Cloud G
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Fast, [Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud,
      [string] $Folder = 'MiniMax Code', [string] $Small = 'locales', [int] $WaitUploadSeconds = 420)
$F = $Fast.ToUpper() + ':\'; $C = $Cloud.ToUpper() + ':\'
$src = Join-Path $env:LOCALAPPDATA "Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD\$Folder"
$log = Join-Path $env:LOCALAPPDATA ("Cloud-SSD\logs\cloudssd-" + (Get-Date).ToString('yyyyMMdd') + '.log')
function Remove-Long([string] $p) { if ($p -match '_fast-test-[AB]' -and (Test-Path -LiteralPath $p)) { [IO.Directory]::Delete('\\?\' + $p, $true) } }
function LogLines { $fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite'); $sr = New-Object IO.StreamReader($fs); $t = $sr.ReadToEnd(); $fs.Close(); @($t -split "`n" | Where-Object { $_ -match 'HybridDriveService' }) }

"fast drive $F : type=$((New-Object IO.DriveInfo($F)).DriveType) free=$([math]::Round((New-Object IO.DriveInfo($F)).AvailableFreeSpace / 1GB, 1)) GB; items: $(@(Get-ChildItem $F -Force).Count)"

# C) purana cloud folder link ke raaste
$sw = [Diagnostics.Stopwatch]::StartNew()
$n = @(Get-ChildItem -LiteralPath (Join-Path $F $Folder) -Force -ErrorAction SilentlyContinue).Count
"C) existing cloud folder through its link: $n items in {0:0.00} s" -f $sw.Elapsed.TotalSeconds

# A) install jaisa likhna
$a = Join-Path $F '_fast-test-A'
$sw.Restart()
$null = robocopy $src (Join-Path $a $Folder) /E /MT:1 /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
$secs = $sw.Elapsed.TotalSeconds
$count = @(Get-ChildItem -LiteralPath $a -Recurse -File -Force).Count
"A) INSTALL-LIKE WRITE on the fast drive: {0:0.0} s ({1} files, robocopy code {2})" -f $secs, $count, $LASTEXITCODE
$real = Join-Path (Join-Path $env:USERPROFILE 'Cloud-SSD\All Accounts') '_fast-test-A'
"   it is a real folder on this PC: " + (Test-Path -LiteralPath $real)
Remove-Long $real
"   test folder A removed: " + (-not (Test-Path -LiteralPath $a))

# B) chhota folder -> upload
$before = (LogLines).Count
$b = Join-Path $F '_fast-test-B'
$null = robocopy (Join-Path $src $Small) (Join-Path $b $Small) /E /MT:1 /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
$made = @(Get-ChildItem -LiteralPath $b -Recurse -File -Force).Count
$mb = [math]::Round(((Get-ChildItem -LiteralPath $b -Recurse -File -Force | Measure-Object Length -Sum).Sum) / 1MB, 1)
"B) small folder written: $made files, $mb MB; waiting for the app to upload it (it waits 20 s of quiet first)..."
$sw.Restart(); $done = $false
while ($sw.Elapsed.TotalSeconds -lt $WaitUploadSeconds) {
    $new = @(LogLines | Select-Object -Skip $before)
    if ($new -match 'upload finished') { $done = $true; break }
    if ($new -match 'did not finish') { break }
    Start-Sleep -Seconds 3
}
$new = @(LogLines | Select-Object -Skip $before)
"   app log since then: " + (($new | ForEach-Object { ($_ -replace '^.*HybridDriveService: ', '') }) -join '  |  ')
"   upload finished: $done after {0:0} s" -f $sw.Elapsed.TotalSeconds
$onCloud = Join-Path $C '_fast-test-B'
$cloudCount = 0
foreach ($try in 1..10) { if (Test-Path -LiteralPath $onCloud) { $cloudCount = @(Get-ChildItem -LiteralPath $onCloud -Recurse -File -Force -ErrorAction SilentlyContinue).Count; if ($cloudCount -ge $made) { break } }; Start-Sleep -Seconds 3 }
"   on the cloud drive ($C): $cloudCount of $made files"

# safai: pehle laptop wala, phir cloud wala (sirf yahi test folder)
Remove-Long (Join-Path (Join-Path $env:USERPROFILE 'Cloud-SSD\All Accounts') '_fast-test-B')
$sw.Restart()
if (Test-Path -LiteralPath $onCloud) { Remove-Item -LiteralPath $onCloud -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue }
"   cleaned up: local gone=$(-not (Test-Path -LiteralPath (Join-Path (Join-Path $env:USERPROFILE 'Cloud-SSD\All Accounts') '_fast-test-B'))), cloud gone=$(-not (Test-Path -LiteralPath $onCloud)) ({0:0} s)" -f $sw.Elapsed.TotalSeconds

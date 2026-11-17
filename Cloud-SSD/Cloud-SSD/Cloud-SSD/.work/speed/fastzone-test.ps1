<#
  TAJURBA: "tez folder". Cloud drive ke andar ek folder jo asal mein laptop ki disk ka folder hai (Windows ka symlink).
  Us folder ke andar ka har kaam seedha laptop ki disk par hota hai (rclone / Google beech mein nahi), isliye Files jaisi raftaar.
  Yeh script: drive par ek test symlink banata hai -> laptop ke TEMP ka folder, usme "install jaisa" kaam naapta hai, phir sab hata deta hai.
  Cloud par sirf ek chhoti ".rclonelink" file banti hai (symlink ka pata), woh bhi aakhir mein hatt jati hai.
    powershell -ExecutionPolicy Bypass -File .work\speed\fastzone-test.ps1 -Drive G [-Folder "MiniMax Code"]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Drive, [string] $Folder = 'MiniMax Code')
$src = Join-Path $env:LOCALAPPDATA "Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD\$Folder"
if (-not (Test-Path -LiteralPath $src)) { "source not found: $Folder"; exit 2 }
$stamp = (Get-Date).ToString('HHmmss')
$local = Join-Path $env:TEMP "cssd-fastzone-$stamp"
$link = "$($Drive.ToUpper()):\_fastzone-test-$stamp"
$null = New-Item -ItemType Directory -Force -Path $local
function Remove-Long([string] $p) { if ($p -like '*cssd-fastzone-*' -and (Test-Path -LiteralPath $p)) { try { [IO.Directory]::Delete('\\?\' + $p, $true) } catch { } } }

try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $out = cmd /c "mklink /D `"$link`" `"$local`"" 2>&1
    "symlink made in {0:0.0} s: {1}" -f $sw.Elapsed.TotalSeconds, ("$out" -replace [regex]::Escape($local), '<local>')
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if (-not $item) { 'the drive did not accept a symlink'; exit 3 }
    "on the drive it is: attributes=$($item.Attributes)  linkType=$($item.LinkType)  target ok=$("$($item.Target)" -eq $local)"

    $to = Join-Path $link $Folder
    $sw.Restart()
    $null = robocopy $src $to /E /MT:1 /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
    "INSTALL-LIKE WRITE through the fast folder: {0:0.0} s (robocopy code {1})" -f $sw.Elapsed.TotalSeconds, $LASTEXITCODE
    "files seen through the drive path: " + @(Get-ChildItem -LiteralPath $to -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    "files really on the laptop disk:   " + @(Get-ChildItem -LiteralPath (Join-Path $local $Folder) -Recurse -File -Force -ErrorAction SilentlyContinue).Count

    # ek exe ko drive ke raaste se "khol" kar dekho (sirf padhna, chalana nahi)
    $exe = Get-ChildItem -LiteralPath $to -Filter '*.exe' -File -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 1
    if ($exe) { $sw.Restart(); $fs = [IO.File]::OpenRead($exe.FullName); $buf = New-Object byte[] (4MB); $n = 0; while (($r = $fs.Read($buf, 0, $buf.Length)) -gt 0) { $n += $r }; $fs.Close(); "read the biggest exe ({0:0} MB) through the drive path in {1:0.00} s" -f ($n / 1MB), $sw.Elapsed.TotalSeconds }
}
finally {
    # pehle link hatao (rmdir sirf link hatata hai, andar ki cheez nahi), phir laptop ka folder
    if (Test-Path -LiteralPath $link) { cmd /c "rmdir `"$link`"" 2>&1 | Out-Null }
    "test link removed from the drive: " + (-not (Test-Path -LiteralPath $link))
    Remove-Long $local
    "local test folder removed: " + (-not (Test-Path -LiteralPath $local))
}

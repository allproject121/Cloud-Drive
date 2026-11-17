<#
  Jaanch ("hybrid drive" ka vichaar): ek laptop ka folder jisme
    - cloud ke purane folder LINK ban kar dikhte hain (link -> cloud drive ka folder), aur
    - naye folder asli laptop ke folder hote hain (Files jaisi raftaar).
  Yeh script TEMP mein aisa ek chhota namoona banata hai, ek test letter (default R:) us par lagata hai (subst),
  naapta hai, aur sab hata deta hai. Cloud par kuch nahi likhta.
    powershell -ExecutionPolicy Bypass -File .work\speed\hybrid-check.ps1 -Cloud G [-Letter R] [-Folder "MiniMax Code"]
#>
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Cloud, [string] $Letter = 'R', [string] $Folder = 'MiniMax Code')
$cloudRoot = $Cloud.ToUpper() + ':\'
$L = $Letter.TrimEnd(':').ToUpper()
if (Test-Path "${L}:\") { "letter ${L}: is in use"; exit 1 }
$src = Join-Path $env:LOCALAPPDATA "Cloud-SSD\cache\m-cloudssd\vfs\CloudSSD\$Folder"
$base = Join-Path $env:TEMP 'cssd-hybrid-check'
if (Test-Path $base) { try { [IO.Directory]::Delete('\\?\' + $base, $true) } catch { } }
$null = New-Item -ItemType Directory -Force -Path $base

try {
    # 1) cloud ke har upar wale folder ke liye ek link
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $made = 0; $failed = 0
    foreach ($d in (Get-ChildItem -LiteralPath $cloudRoot -Directory -Force -ErrorAction SilentlyContinue)) {
        $null = cmd /c "mklink /D `"$(Join-Path $base $d.Name)`" `"$($d.FullName)`"" 2>&1
        if ($LASTEXITCODE -eq 0) { $made++ } else { $failed++ }
    }
    "links to the cloud folders: made $made, failed $failed, in {0:0.0} s" -f $sw.Elapsed.TotalSeconds

    # 2) us folder par ek drive letter
    $null = cmd /c "subst ${L}: `"$base`"" 2>&1
    "test drive ${L}: ready: " + (Test-Path "${L}:\") + "; items it shows: " + @(Get-ChildItem "${L}:\" -Force -ErrorAction SilentlyContinue).Count
    $di = New-Object IO.DriveInfo("${L}:")
    "it reports: type=$($di.DriveType) format=$($di.DriveFormat) free=$([math]::Round($di.AvailableFreeSpace / 1GB, 1)) GB"

    # 3) link ke raaste cloud ka folder padhna
    $viaLink = "${L}:\$Folder"
    if (Test-Path -LiteralPath $viaLink) {
        $sw.Restart(); $n = @(Get-ChildItem -LiteralPath $viaLink -Force -ErrorAction SilentlyContinue).Count
        "open an existing cloud folder through its link: $n items in {0:0.00} s" -f $sw.Elapsed.TotalSeconds
    } else { "cloud folder '$Folder' is not visible through the link" }

    # 4) naya folder = asli laptop ka folder: install jaisa kaam
    $to = "${L}:\_new-app-test\$Folder"
    $sw.Restart()
    $null = robocopy $src $to /E /MT:1 /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
    "INSTALL-LIKE WRITE into a new folder on the hybrid drive: {0:0.0} s (robocopy code {1}, {2} files)" -f $sw.Elapsed.TotalSeconds, $LASTEXITCODE, @(Get-ChildItem -LiteralPath $to -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}
finally {
    $null = cmd /c "subst ${L}: /D" 2>&1
    "test drive removed: " + (-not (Test-Path "${L}:\"))
    # pehle saare link hatao (sirf link; cloud ka folder nahi chhuta), phir namoona
    foreach ($i in (Get-ChildItem -LiteralPath $base -Force -ErrorAction SilentlyContinue)) {
        if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($i.FullName) }
    }
    $left = @(Get-ChildItem -LiteralPath $base -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count
    if ($left -eq 0) { try { [IO.Directory]::Delete('\\?\' + $base, $true) } catch { } }
    "sample removed: " + (-not (Test-Path $base)) + "  (links left: $left)"
}

# Jaanch: kya Windows ke link (symlink / junction) laptop ki disk par aur cloud drive par ban sakte hain?
# Jo banta hai use turant hata deta hai (sirf link, andar ki cheez nahi). Naam pakke likhe hain.
#   powershell -ExecutionPolicy Bypass -File .work\speed\link-check.ps1 -Drive G
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Drive)
$d = $Drive.ToUpper() + ':\'
$t = Join-Path $env:TEMP 'cssd-linkcheck'
$null = New-Item -ItemType Directory -Force -Path (Join-Path $t 'target')
$target = Join-Path $t 'target'

function Try-Link([string] $kind, [string] $path, [string] $to) {
    $flag = if ($kind -eq 'junction') { '/J' } else { '/D' }
    $out = cmd /c "mklink $flag `"$path`" `"$to`"" 2>&1
    $made = Test-Path -LiteralPath $path
    $info = ''
    if ($made) { $i = Get-Item -LiteralPath $path -Force; $info = " attributes=$($i.Attributes) linkType=$($i.LinkType)"; [IO.Directory]::Delete($path) }
    '{0,-28} made={1}{2}  ({3})' -f "$kind at $($path.Substring(0,3))", $made, $info, (("$out" -replace [regex]::Escape($t), '<temp>') -replace '\s+', ' ').Trim()
}

Try-Link 'symlink'  (Join-Path $t 'sym')  $target
Try-Link 'junction' (Join-Path $t 'junc') $target
Try-Link 'symlink'  (Join-Path $d '_cssd-linkcheck-sym')  $target
Try-Link 'junction' (Join-Path $d '_cssd-linkcheck-junc') $target
[IO.Directory]::Delete($t, $true)
'developer mode: ' + (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense

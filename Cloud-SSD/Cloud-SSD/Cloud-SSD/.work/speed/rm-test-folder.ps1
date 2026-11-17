# install-sim.ps1 ka bacha hua test folder hatata hai. SIRF "_install-speed-test-<6 ank>" naam wale folder, aur kuch nahi.
#   powershell -ExecutionPolicy Bypass -File .work\speed\rm-test-folder.ps1 -Drive G
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Drive)
$root = "$($Drive.ToUpper()):\"
$hits = @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^_install-speed-test-\d{6}$' })
if ($hits.Count -eq 0) { 'no test folder left'; exit 0 }
foreach ($d in $hits) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    # Sabse gehre folder pehle (khaali folder hi hatte hain; koi file bachi ho to woh bhi isi test ki hai).
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    '{0}: removed in {1} s; still there: {2}' -f $d.Name, [math]::Round($sw.Elapsed.TotalSeconds, 0), (Test-Path -LiteralPath $d.FullName)
}

# Cloud-SSD PC app ke khule sawaal-box (Win32 MessageBox, class #32770) ko padhna / jawab dena.
# UI Automation in buttons ko daba nahi pata, isliye WM_COMMAND bheja jata hai (jaise tools\live-test\pc-close.ps1).
# Sirf user ki saaf haan ke baad (17 Nov 2026: "tum sab kar sakte ho", key switch ke liye).
#   dlg.ps1                 jo box khula hai uska text
#   dlg.ps1 -Answer OK      OK | Cancel | Yes | No
param([ValidateSet('', 'OK', 'Cancel', 'Yes', 'No')] [string] $Answer = '')
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeyDlg {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
'@
$AE = [System.Windows.Automation.AutomationElement]
# Ek purana atka hua (HasExited) process bhi ho sakta hai: zinda wala lo.
$app = Get-Process Cloud-SSD -ErrorAction SilentlyContinue | Where-Object { -not $_.HasExited } | Sort-Object StartTime -Descending | Select-Object -First 1
if (-not $app) { 'Cloud-SSD app is not running'; exit 2 }
$cond = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $app.Id)),
    (New-Object System.Windows.Automation.PropertyCondition($AE::ClassNameProperty, '#32770')))
$dlg = $AE::RootElement.FindFirst('Descendants', $cond)
if (-not $dlg) { 'no question box is open'; exit 1 }
"box: " + $dlg.Current.Name
foreach ($e in $dlg.FindAll('Descendants', [System.Windows.Automation.Condition]::TrueCondition)) {
    $n = $e.Current.Name
    if ($n -and $n -notmatch '^(OK|Cancel|Yes|No)$') { '  ' + ($n -replace "`r?`n", ' | ') }
}
if ($Answer) {
    $id = @{ OK = 1; Cancel = 2; Yes = 6; No = 7 }[$Answer]
    [void][KeyDlg]::PostMessage([IntPtr]$dlg.Current.NativeWindowHandle, 0x0111, [IntPtr]$id, [IntPtr]::Zero)
    "answered: $Answer"
}

# Closes the Cloud-SSD window the way the X button does and answers the app's own question
# "Keep the cloud drives mounted after closing Cloud Drive?"  (-Answer Yes = drives stay, No = drives are unmounted).
param([ValidateSet('Yes', 'No')][string]$Answer = 'Yes', [int]$WaitSeconds = 150)
$ErrorActionPreference = 'Stop'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public static class CssdClose {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    public static IntPtr Find(uint pid, string classStart, string title) {
        IntPtr f = IntPtr.Zero;
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            var c = new StringBuilder(128); GetClassName(h, c, 128);
            var t = new StringBuilder(200); GetWindowText(h, t, 200);
            if (c.ToString().StartsWith(classStart) && t.ToString() == title) { f = h; return false; }
            return true;
        }, IntPtr.Zero);
        return f;
    }
}
"@
$p = Get-Process Cloud-SSD -ErrorAction SilentlyContinue | Where-Object { -not $_.HasExited } | Select-Object -First 1   # ek atka hua purana process bhi ho sakta hai
if (-not $p) { 'app is not running'; return }
$main = [CssdClose]::Find([uint32]$p.Id, 'HwndWrapper[Cloud-SSD', 'Cloud-SSD')
if ($main -eq [IntPtr]::Zero) { throw 'main window not found' }
[CssdClose]::PostMessage($main, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null   # WM_CLOSE
$sw = [Diagnostics.Stopwatch]::StartNew(); $answered = $false
while ($sw.Elapsed.TotalSeconds -lt $WaitSeconds -and (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) {
    if (-not $answered) {
        $dlg = [CssdClose]::Find([uint32]$p.Id, '#32770', 'Close Cloud Drive')
        if ($dlg -ne [IntPtr]::Zero) {
            $id = if ($Answer -eq 'Yes') { 6 } else { 7 }
            [CssdClose]::PostMessage($dlg, 0x0111, [IntPtr]$id, [IntPtr]::Zero) | Out-Null   # WM_COMMAND IDYES / IDNO
            $answered = $true
            "answered the close question with $Answer"
        }
    }
    Start-Sleep -Milliseconds 300
}
$still = [bool](Get-Process -Id $p.Id -ErrorAction SilentlyContinue)
"app still running: $still (after $([int]$sw.Elapsed.TotalSeconds) s)"


# Google key banate waqt screen dekhne / click karne ka chhota auzaar (user ke saath baith kar, user ki haan ke baad).
# Photo git ke BAHAR jati hai (usme e-mail dikh sakta hai): %USERPROFILE%\Downloads\Cloud-Drive\key-photos\
#   ui.ps1 -Shot naam                 poori screen ki photo
#   ui.ps1 -Click 640,380 -Shot naam  wahan ek click, 1.5 s baad photo
#   ui.ps1 -Type "Cloud-SSD"          jo window saamne hai usme likhna (pehle -Click se box chuno)
#   ui.ps1 -Keys "{ENTER}"            SendKeys wale button
# Kabhi Google ka login / password / "Allow" is se mat dabao: woh user khud dabata hai.
param(
    [string] $Shot = '',
    [int[]] $Click = @(),
    [string] $Type = '',
    [string] $Keys = '',
    [int] $WaitMs = 1500,
    [string] $OutDir = (Join-Path $env:USERPROFILE 'Downloads\Cloud-Drive\key-photos')
)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeyUi {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
}
'@
[void][KeyUi]::SetProcessDPIAware()

function Front {
    $sb = New-Object System.Text.StringBuilder 300
    [void][KeyUi]::GetWindowText([KeyUi]::GetForegroundWindow(), $sb, 300)
    $sb.ToString()
}

if ($Click.Count -eq 2) {
    [void][KeyUi]::SetCursorPos($Click[0], $Click[1])
    Start-Sleep -Milliseconds 120
    [KeyUi]::mouse_event(0x2, 0, 0, 0, [UIntPtr]::Zero)
    [KeyUi]::mouse_event(0x4, 0, 0, 0, [UIntPtr]::Zero)
    "clicked $($Click[0]),$($Click[1])"
    Start-Sleep -Milliseconds 300
}
if ($Type) {
    # SendKeys ke khaas akshar ({ } + ^ % ~ ( )) ko saada text banao.
    $safe = [regex]::Replace($Type, '[+^%~(){}\[\]]', { param($m) '{' + $m.Value + '}' })
    [System.Windows.Forms.SendKeys]::SendWait($safe)
    "typed $($Type.Length) chars"
}
if ($Keys) { [System.Windows.Forms.SendKeys]::SendWait($Keys); "keys $Keys" }

if ($Shot) {
    Start-Sleep -Milliseconds $WaitMs
    [void](New-Item -ItemType Directory -Force -Path $OutDir)
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $path = Join-Path $OutDir ($Shot + '.png')
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    "shot $path  ($($b.Width)x$($b.Height))  front: " + (Front)
}

# Ek "mari hui" drive ka letter dekhna / chhudana (17 Nov 2026: Z: ka rclone band ho gaya par Z: letter atka raha,
# kyunki Z: se chal raha ek program Windows ke andar atak gaya tha; tab app drive ko Z: ki jagah doosre letter par jodta).
#   dosdev.ps1 -Letter Z            letter kis cheez se juda hai (sirf padhna)
#   dosdev.ps1 -Letter Z -Remove    letter ka naam hatao (sirf tab jab drive "ready" na ho aur uska rclone chal na raha ho)
# Sirf naam (DOS device link) hatta hai; koi file, cache ya cloud ki cheez nahi chhui jati.
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Letter, [switch] $Remove)
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class DosDev {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern uint QueryDosDevice(string name, StringBuilder target, int max);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool DefineDosDevice(uint flags, string name, string target);
}
'@
$name = $Letter.ToUpper() + ':'
$sb = New-Object System.Text.StringBuilder 1024
$n = [DosDev]::QueryDosDevice($name, $sb, 1024)
if ($n -eq 0) { "$name is not defined (free)"; exit 0 }
$target = $sb.ToString()
"$name -> $target"
$ready = $false
try { $ready = (New-Object IO.DriveInfo($name)).IsReady } catch { }
"ready: $ready"
if (-not $Remove) { exit 0 }
if ($ready) { "$name is a working drive: not removing"; exit 3 }
# DDD_RAW_TARGET_PATH (1) | DDD_REMOVE_DEFINITION (2) | DDD_EXACT_MATCH_ON_REMOVE (4): hatao sirf yahi link.
$ok = [DosDev]::DefineDosDevice(7, $name, $target)
"removed: $ok" + $(if (-not $ok) { '  (error ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error() + ')' } else { '' })
$sb2 = New-Object System.Text.StringBuilder 1024
if ([DosDev]::QueryDosDevice($name, $sb2, 1024) -eq 0) { "$name is free now" } else { "$name still -> " + $sb2.ToString() }

# Ek drive letter ko laptop ke ek folder par lagana / hatana (jaise "subst", par us letter par bhi jo mara hua atka ho).
# Hybrid Z: ke liye jaanch. Sirf naam ka rishta banta / hatta hai; koi file nahi chhui jati.
#   letter-overlay.ps1 -Letter Z -Folder "C:\Users\...\Cloud-SSD\All Accounts"            lagao
#   letter-overlay.ps1 -Letter Z -Folder "C:\Users\...\Cloud-SSD\All Accounts" -Remove    hatao (sirf yahi rishta)
#   letter-overlay.ps1 -Letter Z                                                          dekho
param([Parameter(Mandatory)] [ValidatePattern('^[D-Zd-z]$')] [string] $Letter, [string] $Folder = '', [switch] $Remove)
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class LetterOverlay {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern uint QueryDosDevice(string name, char[] target, int max);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool DefineDosDevice(uint flags, string name, string target);
}
'@
$name = $Letter.ToUpper() + ':'
function Defs { $b = New-Object char[] 8192; $r = [LetterOverlay]::QueryDosDevice($name, $b, 8192); if ($r -eq 0) { return @() }; return @((New-Object string($b, 0, [int]$r)).Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)) }
function Show { $d = @(Defs); if ($d.Count -eq 0) { "$name is free" } else { "$name -> " + ($d -join '  |  ') }; $ready = $false; try { $ready = (New-Object IO.DriveInfo($name)).IsReady } catch { }; "$name ready: $ready" }

if ($Folder) {
    $full = [IO.Path]::GetFullPath($Folder).TrimEnd('\')
    $target = '\??\' + $full
    if ($Remove) {
        # DDD_RAW_TARGET_PATH (1) | DDD_REMOVE_DEFINITION (2) | DDD_EXACT_MATCH_ON_REMOVE (4)
        "remove: " + [LetterOverlay]::DefineDosDevice(7, $name, $target)
    } else {
        if (-not (Test-Path -LiteralPath $full)) { $null = New-Item -ItemType Directory -Force -Path $full }
        # DDD_RAW_TARGET_PATH (1): naya rishta sabse upar lagta hai
        "define: " + [LetterOverlay]::DefineDosDevice(1, $name, $target) + '  (error ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error() + ')'
    }
}
Show

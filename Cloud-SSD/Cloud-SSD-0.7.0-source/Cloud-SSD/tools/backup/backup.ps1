<#
.SYNOPSIS
  Backups of the project's source, kept inside the project (folder "backup", so they go to GitHub with everything else).

  One folder per piece of work:
    backup\<date>_<time>_<name>\
      before\      the source as it was BEFORE the work started. Never changed afterwards.
      complete\    made when the work is finished: the files the work added or changed (complete\files\...),
                   CHANGED-FILES.txt (the list), and README.md (what it is, what was done, how it is used, how the
                   connection works, how to go back) written by whoever did the work.

.EXAMPLE
  tools\backup\backup.ps1 start -Name "app-icon"                      # before the first change
  tools\backup\backup.ps1 complete -Folder "2026-11-14_0906_app-icon"  # when the work is ready; then write complete\README.md
  tools\backup\backup.ps1 list

.NOTES
  Only source is copied: build output, the cloud tools' big programs (rclone.exe, the WinFsp installer), APKs, zips and
  files over 2 MB are left out, so a backup is a few megabytes. -From takes "before" from another copy of the project
  (an older backup made outside the project); -Current compares against another copy instead of the project as it is now.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidateSet('start', 'complete', 'list')][string]$Mode,
    [string]$Name,
    [string]$Folder,
    [string]$From,
    [string]$Current,
    [string[]]$Files,
    [string]$Stamp
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'backup'
$skipDirs = @('bin', 'obj', 'dist', 'build', '.git', 'node_modules', '.vs', '.work', 'backup', 'releases')
$skipExt = @('.exe', '.apk', '.msi', '.zip', '.dll', '.pdb')

# The source files of a copy of the project, as paths relative to it.
function Get-SourceFiles([string]$base) {
    $base = (Resolve-Path $base).Path.TrimEnd('\')
    Get-ChildItem $base -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length + 1)
        $parts = $rel.Split('\')
        if ($parts | Where-Object { $skipDirs -contains $_ }) { return }
        if ($skipExt -contains $_.Extension.ToLowerInvariant()) { return }
        if ($_.Length -gt 2MB) { return }
        $rel
    }
}

function Copy-Rel([string]$fromBase, [string]$rel, [string]$toBase) {
    $to = Join-Path $toBase $rel
    New-Item -ItemType Directory -Force (Split-Path $to -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $fromBase $rel) -Destination $to -Force
}

function Resolve-Backup([string]$folder) {
    if (-not $folder) { throw '-Folder is needed (the name of a folder in backup\).' }
    $p = if (Test-Path $folder) { (Resolve-Path $folder).Path } else { Join-Path $root $folder }
    if (-not (Test-Path (Join-Path $p 'before'))) { throw "No backup with a 'before' folder at $p" }
    $p
}

if ($Mode -eq 'list') {
    if (-not (Test-Path $root)) { 'No backups yet.'; return }
    Get-ChildItem $root -Directory | Sort-Object Name | ForEach-Object {
        $done = Test-Path (Join-Path $_.FullName 'complete')
        $doc = Test-Path (Join-Path $_.FullName 'complete\README.md')
        '{0,-58} {1}' -f $_.Name, $(if ($done -and $doc) { 'complete (with README)' } elseif ($done) { 'complete, README missing' } else { 'work in progress: do not touch' })
    }
    return
}

if ($Mode -eq 'start') {
    if (-not $Name) { throw '-Name is needed (a short name of the work, e.g. "app-icon").' }
    $safe = ($Name -replace '[^A-Za-z0-9._-]+', '-').Trim('-')
    if (-not $Stamp) { $Stamp = Get-Date -Format 'yyyy-MM-dd_HHmm' }
    $dir = Join-Path $root "${Stamp}_$safe"
    if (Test-Path $dir) { throw "$dir is there already. A backup is never written over." }
    $src = if ($From) { (Resolve-Path $From).Path.TrimEnd('\') } else { $repo }
    $before = Join-Path $dir 'before'
    $n = 0; $bytes = 0L
    foreach ($rel in Get-SourceFiles $src) { Copy-Rel $src $rel $before; $n++; $bytes += (Get-Item -LiteralPath (Join-Path $src $rel)).Length }
    Set-Content (Join-Path $dir 'BEFORE.txt') -Encoding utf8 -Value @(
        "Work: $Name",
        "Source as it was before the work started: $n files, $([math]::Round($bytes / 1MB, 1)) MB.",
        "Taken: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" + $(if ($From) { " from the older copy $(Split-Path $From -Leaf)" } else { '' }),
        'The folder "before" is never changed. When the work is ready, run:',
        "  tools\backup\backup.ps1 complete -Folder `"$(Split-Path $dir -Leaf)`"",
        'and write complete\README.md.'
    )
    "backup: $dir ($n files, $([math]::Round($bytes / 1MB, 1)) MB)"
    return
}

# complete
$dir = Resolve-Backup $Folder
$before = Join-Path $dir 'before'
$now = if ($Current) { (Resolve-Path $Current).Path.TrimEnd('\') } else { $repo }
$complete = Join-Path $dir 'complete'
if (Test-Path (Join-Path $complete 'files')) { throw "$complete\files is there already. A finished backup is not written over." }
$hash = { param($p) (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
$was = @{}; foreach ($rel in Get-SourceFiles $before) { $was[$rel] = $true }
$new = @(); $changed = @(); $gone = @()
if ($Files) {
    # Only these files belong to the work (someone else may be changing other files at the same time).
    foreach ($rel in $Files) {
        $rel = $rel.Replace('/', '\')
        if (-not (Test-Path -LiteralPath (Join-Path $now $rel))) { if ($was[$rel]) { $gone += $rel }; continue }
        if (-not $was[$rel]) { $new += $rel }
        elseif ((& $hash (Join-Path $now $rel)) -ne (& $hash (Join-Path $before $rel))) { $changed += $rel }
    }
} else {
    $is = @{}
    foreach ($rel in Get-SourceFiles $now) {
        $is[$rel] = $true
        if (-not $was[$rel]) { $new += $rel }
        elseif ((& $hash (Join-Path $now $rel)) -ne (& $hash (Join-Path $before $rel))) { $changed += $rel }
    }
    foreach ($rel in $was.Keys) { if (-not $is[$rel]) { $gone += $rel } }
}
foreach ($rel in $new + $changed) { Copy-Rel $now $rel (Join-Path $complete 'files') }
$lines = @("Work finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm')", '', "NEW files ($($new.Count)):") + ($new | Sort-Object | ForEach-Object { "  $_" }) +
    @('', "CHANGED files ($($changed.Count)):") + ($changed | Sort-Object | ForEach-Object { "  $_" }) +
    @('', "REMOVED files ($($gone.Count)):") + ($gone | Sort-Object | ForEach-Object { "  $_" }) +
    @('', 'The finished version of every new and changed file is in complete\files\ (same path as in the project).',
      'To go back to how it was: copy the same paths from before\ over the project, and delete the NEW files.')
New-Item -ItemType Directory -Force $complete | Out-Null
Set-Content (Join-Path $complete 'CHANGED-FILES.txt') -Encoding utf8 -Value $lines
"complete: $complete (new $($new.Count), changed $($changed.Count), removed $($gone.Count))"
if (-not (Test-Path (Join-Path $complete 'README.md'))) { 'Now write complete\README.md: what it is, what was done, how it is used, how the connection works, how to go back.' }

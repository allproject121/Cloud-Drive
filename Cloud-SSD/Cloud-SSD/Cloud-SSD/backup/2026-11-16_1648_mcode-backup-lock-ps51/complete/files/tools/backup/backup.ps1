<#
.SYNOPSIS
  Backups of the project's source, kept inside the project (folder "backup", so they go to GitHub with everything else).

  One folder per piece of work:
    backup\<date>_<time>_<name>\
      before\             the source as it was BEFORE the work started. Never changed afterwards.
      TASK_INFO.json      metadata: Agent, Model, Task ID, prompt, timestamp
      VALIDATION.txt      status: APPROVED / FAILED_VALIDATION / PARTIALLY_VALIDATED
      complete\           made when the work is finished: the files the work added or changed (complete\files\...),
                          CHANGED-FILES.txt (the list), and README.md

.EXAMPLE
  tools\backup\backup.ps1 start -Name "app-icon" -Agent "Antigravity" -TaskId "TASK-001"
  tools\backup\backup.ps1 validate -Folder "2026-11-14_0906_app-icon"
  tools\backup\backup.ps1 complete -Folder "2026-11-14_0906_app-icon"
  tools\backup\backup.ps1 restore -Folder "2026-11-14_0906_app-icon"
  tools\backup\backup.ps1 list
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidateSet('start', 'complete', 'list', 'validate', 'restore')][string]$Mode,
    [string]$Name,
    [string]$Folder,
    [string]$From,
    [string]$Current,
    [string[]]$Files,
    [string]$Stamp,
    [string]$Agent = "Antigravity",
    [string]$TaskId = "",
    [string]$Prompt = "",
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

# -Files accepts a list. When the script is started with "powershell -File ... -Files a,b,c" the whole
# "a,b,c" arrives as ONE string, so the comma list has to be split here. Without this the complete step
# silently reported "new 0, changed 0" and copied nothing into complete\files.
if ($Files) {
    $Files = @($Files | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$root = Join-Path $repo 'backup'
$docRoot = Join-Path $repo 'docs'
$taskLockFile = Join-Path $docRoot 'CURRENT_TASK.json'
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

# Reads the task lock file (docs\CURRENT_TASK.json) into a plain hashtable.
# Windows PowerShell 5.1 has no "ConvertFrom-Json -AsHashtable" (that came with PowerShell 6), so on
# 5.1 the lock file could not be read at all - and the catch-all around it hid the error. Result: the
# lock stayed "active" forever, the validation status was never written, and the "another task is
# running" warning never appeared. This works the same on 5.1 and on 7+.
function Read-TaskLock([string]$path) {
    $map = @{}
    try {
        $parsed = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        foreach ($prop in $parsed.PSObject.Properties) { $map[$prop.Name] = $prop.Value }
    } catch { }
    $map
}

function Get-DotNetPath() {
    $local = "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"
    if (Test-Path $local) {
        return $local
    }
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        return (Get-Command dotnet).Source
    }
    return "dotnet"
}

if ($Mode -eq 'list') {
    if (-not (Test-Path $root)) { 'No backups yet.'; return }
    Get-ChildItem $root -Directory | Sort-Object Name | ForEach-Object {
        $done = Test-Path (Join-Path $_.FullName 'complete')
        $doc = Test-Path (Join-Path $_.FullName 'complete\README.md')
        $valFile = Join-Path $_.FullName 'VALIDATION.txt'
        $val = if (Test-Path $valFile) { Get-Content $valFile -Raw } else { '' }
        $valBadge = if ($val -match 'APPROVED') { '[APPROVED]' } elseif ($val -match 'FAILED') { '[FAILED]' } else { '' }
        '{0,-58} {1} {2}' -f $_.Name, $(if ($done -and $doc) { 'complete (with README)' } elseif ($done) { 'complete, README missing' } else { 'work in progress: do not touch' }), $valBadge
    }
    return
}

if ($Mode -eq 'start') {
    if (-not $Name) { throw '-Name is needed (a short name of the work, e.g. "app-icon").' }
    
    # Conflict check via CURRENT_TASK.json
    if (Test-Path $taskLockFile) {
        $currentTask = Read-TaskLock $taskLockFile
        if ($currentTask.Count -gt 0 -and $currentTask['active'] -and -not $Force) {
            Write-Warning "Another task '$($currentTask['taskId'])' by agent '$($currentTask['agent'])' is currently in progress."
            Write-Warning "Use -Force to override if this is a continuation or intentional concurrent step."
        }
    }

    $safe = ($Name -replace '[^A-Za-z0-9._-]+', '-').Trim('-')
    if (-not $Stamp) { $Stamp = Get-Date -Format 'yyyy-MM-dd_HHmm' }
    $dir = Join-Path $root "${Stamp}_$safe"
    if (Test-Path $dir) { throw "$dir is there already. A backup is never written over." }
    $src = if ($From) { (Resolve-Path $From).Path.TrimEnd('\') } else { $repo }
    $before = Join-Path $dir 'before'
    $n = 0; $bytes = 0L
    foreach ($rel in Get-SourceFiles $src) { Copy-Rel $src $rel $before; $n++; $bytes += (Get-Item -LiteralPath (Join-Path $src $rel)).Length }
    
    $nowStr = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    Set-Content (Join-Path $dir 'BEFORE.txt') -Encoding utf8 -Value @(
        "Work: $Name",
        "Agent: $Agent",
        "TaskId: $TaskId",
        "Source as it was before the work started: $n files, $([math]::Round($bytes / 1MB, 1)) MB.",
        "Taken: $nowStr" + $(if ($From) { " from the older copy $(Split-Path $From -Leaf)" } else { '' }),
        'The folder "before" is never changed. When the work is ready, run:',
        "  tools\backup\backup.ps1 complete -Folder `"$(Split-Path $dir -Leaf)`"",
        'and write complete\README.md.'
    )
    
    # Write TASK_INFO.json
    $taskInfo = [PSCustomObject]@{
        name = $Name
        agent = $Agent
        taskId = $TaskId
        prompt = $Prompt
        startTime = (Get-Date -Format 'o')
        backupDir = (Split-Path $dir -Leaf)
        fileCount = $n
    }
    $taskInfo | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $dir 'TASK_INFO.json') -Encoding utf8

    # Update docs/CURRENT_TASK.json
    if (-not (Test-Path $docRoot)) { New-Item -ItemType Directory -Force $docRoot | Out-Null }
    $lockObj = [PSCustomObject]@{
        active = $true
        taskId = if ($TaskId) { $TaskId } else { $safe }
        taskTitle = $Name
        agent = $Agent
        startTime = (Get-Date -Format 'o')
        backupFolder = (Split-Path $dir -Leaf)
        targetFiles = if ($Files) { $Files } else { @() }
        status = "IN_PROGRESS"
    }
    $lockObj | ConvertTo-Json -Depth 5 | Set-Content $taskLockFile -Encoding utf8

    "backup: $dir ($n files, $([math]::Round($bytes / 1MB, 1)) MB) [Locked in CURRENT_TASK.json]"
    return
}

if ($Mode -eq 'validate') {
    $dir = Resolve-Backup $Folder
    "Validating project health for backup: $(Split-Path $dir -Leaf)"
    $dn = Get-DotNetPath
    $buildOk = $false
    $testsOk = $false
    $details = @()

    # 1. Build check
    if (Test-Path (Join-Path $repo 'CloudSSD.slnx')) {
        "Running: $dn build CloudSSD.slnx..."
        & $dn build (Join-Path $repo 'CloudSSD.slnx')
        if ($LASTEXITCODE -eq 0) {
            $buildOk = $true
            $details += "C# Build: PASS (0 errors)"
        } else {
            $details += "C# Build: FAILED (ExitCode $LASTEXITCODE)"
        }
    } else {
        $buildOk = $true
        $details += "C# Build: Skipped (no slnx)"
    }

    # 2. Test check
    $testProj = Join-Path $repo 'tests\CloudSSD.Tests'
    if (Test-Path $testProj) {
        "Running: $dn test tests\CloudSSD.Tests..."
        & $dn test $testProj
        if ($LASTEXITCODE -eq 0) {
            $testsOk = $true
            $details += "C# Unit Tests: PASS"
        } else {
            $details += "C# Unit Tests: FAILED (ExitCode $LASTEXITCODE)"
        }
    } else {
        $testsOk = $true
    }

    $finalStatus = if ($buildOk -and $testsOk) { "APPROVED" } elseif ($buildOk) { "PARTIALLY_VALIDATED" } else { "FAILED_VALIDATION" }
    
    $valContent = @(
        "Validation Status: $finalStatus",
        "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Details:",
        ($details | ForEach-Object { "  - $_" })
    )
    Set-Content (Join-Path $dir 'VALIDATION.txt') -Encoding utf8 -Value $valContent

    # Update lock file status
    if (Test-Path $taskLockFile) {
        $currentTask = Read-TaskLock $taskLockFile
        $currentTask['validationStatus'] = $finalStatus
        $currentTask | ConvertTo-Json -Depth 5 | Set-Content $taskLockFile -Encoding utf8
    }

    "Result: $finalStatus"
    return
}

if ($Mode -eq 'restore') {
    $dir = Resolve-Backup $Folder
    $before = Join-Path $dir 'before'
    $complete = Join-Path $dir 'complete'
    $folderLeaf = Split-Path $dir -Leaf
    
    "Initiating safe restore from: $folderLeaf"
    
    # Pre-restore safety snapshot
    $restoreStamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
    $safetyDir = Join-Path $root "${restoreStamp}_before-restore-from-$folderLeaf"
    "Creating pre-restore safety snapshot: $safetyDir..."
    $safetyBefore = Join-Path $safetyDir 'before'
    $nSafety = 0
    foreach ($rel in Get-SourceFiles $repo) {
        Copy-Rel $repo $rel $safetyBefore
        $nSafety++
    }
    Set-Content (Join-Path $safetyDir 'BEFORE.txt') -Encoding utf8 -Value @(
        "Safety backup taken before restoring $folderLeaf",
        "Files: $nSafety",
        "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )

    # Perform restoration
    # If CHANGED-FILES.txt exists, selectively restore CHANGED and delete NEW
    $changedFile = Join-Path $complete 'CHANGED-FILES.txt'
    if (Test-Path $changedFile) {
        $lines = Get-Content $changedFile
        $modeGroup = ''
        $restored = 0
        $deleted = 0
        foreach ($line in $lines) {
            if ($line -match '^NEW files') { $modeGroup = 'NEW'; continue }
            if ($line -match '^CHANGED files') { $modeGroup = 'CHANGED'; continue }
            if ($line -match '^REMOVED files') { $modeGroup = 'REMOVED'; continue }
            if ($line.Trim().Length -eq 0 -or $line.StartsWith('Work finished:') -or $line.StartsWith('The finished version') -or $line.StartsWith('To go back')) { continue }
            
            $f = $line.Trim()
            if ($modeGroup -eq 'NEW') {
                $targetPath = Join-Path $repo $f
                if (Test-Path $targetPath) {
                    Remove-Item -LiteralPath $targetPath -Force -Recurse
                    $deleted++
                }
            } elseif ($modeGroup -eq 'CHANGED' -or $modeGroup -eq 'REMOVED') {
                $sourcePath = Join-Path $before $f
                if (Test-Path $sourcePath) {
                    Copy-Rel $before $f $repo
                    $restored++
                }
            }
        }
        "Selectively restored $restored changed/removed files, removed $deleted new files."
    } else {
        # Full restore from before/
        $restored = 0
        foreach ($rel in Get-SourceFiles $before) {
            Copy-Rel $before $rel $repo
            $restored++
        }
        "Fully restored $restored source files from $before."
    }

    # Log in docs/RESTORE_LOG.md
    $restoreLog = Join-Path $docRoot 'RESTORE_LOG.md'
    if (Test-Path $restoreLog) {
        $logLine = "| $(Get-Date -Format 'yyyy-MM-dd HH:mm') | $folderLeaf | $Agent | Restored historical version | $(Split-Path $safetyDir -Leaf) | RESTORED_OK |"
        Add-Content -LiteralPath $restoreLog -Value $logLine
    }

    # Update lock in CURRENT_TASK.json
    if (Test-Path $taskLockFile) {
        $currentTask = Read-TaskLock $taskLockFile
        $currentTask['active'] = $false
        $currentTask['status'] = "RESTORED"
        $currentTask['completionTime'] = (Get-Date -Format 'o')
        $currentTask | ConvertTo-Json -Depth 5 | Set-Content $taskLockFile -Encoding utf8
    }

    "Restore complete! Historical backups remain 100% intact."
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

# Read validation status if present
$valFile = Join-Path $dir 'VALIDATION.txt'
$valStatus = if (Test-Path $valFile) { (Get-Content $valFile)[0] } else { 'Validation: UNVERIFIED' }

# Release lock in CURRENT_TASK.json
if (Test-Path $taskLockFile) {
    $currentTask = Read-TaskLock $taskLockFile
    $currentTask['active'] = $false
    $currentTask['status'] = "COMPLETED"
    $currentTask['completionTime'] = (Get-Date -Format 'o')
    $currentTask | ConvertTo-Json -Depth 5 | Set-Content $taskLockFile -Encoding utf8
}

"complete: $complete (new $($new.Count), changed $($changed.Count), removed $($gone.Count)) [$valStatus]"
if (-not (Test-Path (Join-Path $complete 'README.md'))) {
    # Generate structured README template
    $tmpl = @(
        "# $(Split-Path $dir -Leaf) — Work Summary",
        "",
        "- **Agent:** $Agent",
        "- **TaskId:** $TaskId",
        "- **Status:** $valStatus",
        "- **Completed At:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
        "",
        "## Changes Summary",
        "- New files: $($new.Count)",
        "- Changed files: $($changed.Count)",
        "- Removed files: $($gone.Count)",
        "",
        "## How to revert",
        "Run:",
        "  tools\backup\backup.ps1 restore -Folder `"$(Split-Path $dir -Leaf)`""
    )
    Set-Content (Join-Path $complete 'README.md') -Encoding utf8 -Value $tmpl
    'Generated default complete\README.md'
}

# RULE.md — Central AI Coordination, Project Rules & Backup System

> **Mandatory Notice for All AI Agents:**  
> This file is the primary rulebook for every AI coding agent working in this repository (Antigravity, Codex, Claude Code, Gemini, and future agents).  
> **You MUST read and adhere strictly to these rules before reading, modifying, or creating any files.**  
> No AI agent may ignore, bypass, or override these rules.

---

## 1. Project Overview & Locations

* **Workspace Root:** `C:\Users\Roshan\Downloads\Cloud-Drive`
* **Git Repository Root:** `C:\Users\Roshan\Downloads\Cloud-Drive\Cloud-Drive` (Branch: `feature/multi-device`)
* **Active Codebase & Solution:** `C:\Users\Roshan\Downloads\Cloud-Drive\Cloud-Drive\Cloud-SSD\Cloud-SSD\Cloud-SSD`
* **Solution File:** `CloudSSD.slnx` (.NET 10 WPF + Windows Service + WinFsp + rclone)
* **Mobile App:** `mobile-android/` (Android APK + WebView JS)
* **Central Documentation Directory:** `docs/` (Inside the active codebase directory)
* **Backup Tool:** `tools\backup\backup.ps1`

---

## 2. Mandatory Pre-Work Inspection (Read Before Touch)

Before modifying any file, every AI agent must execute this sequence:

1. **Read `RULE.md`** (this file).
2. **Inspect Active Task Lock:** Check `docs/CURRENT_TASK.json` and `docs/CHALU_KAAM.md`. If another agent has an active incomplete task, stop and reconcile.
3. **Read Work History:** Read your tool's history file (`docs/antigravity.md`, `docs/codex.md`, `docs/CLAUDE.md`, or `docs/GEMINI.md`) and recent entries from other agents to understand context.
4. **Inspect Git Status:** Run `git status --short` from Git root (`Cloud-Drive`). Never overwrite uncommitted or in-progress work without understanding why it exists.
5. **Inspect Target Files & Existing Tests:** Understand the existing implementation, dependencies, and reasons behind existing code before planning any changes.
6. **Check .NET Runtime:** The .NET 10 SDK is located at:
   ```powershell
   $dn = if (Get-Command dotnet -ErrorAction SilentlyContinue) { (Get-Command dotnet).Source } else { "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe" }
   ```

---

## 3. Multi-Agent Concurrency & Conflict Prevention

Multiple AI agents (Antigravity, Claude, Codex, Gemini) collaborate on this project:

1. **State Lock (`docs/CURRENT_TASK.json`):**
   - Whenever an AI starts a task, it must record the active task status:
     ```json
     {
       "active": true,
       "taskId": "TASK-XXX",
       "agent": "Antigravity",
       "startTime": "2026-11-14T20:00:00",
       "targetFiles": ["src/CloudSSD.Desktop/MainWindow.xaml.cs"],
       "status": "IN_PROGRESS"
     }
     ```
   - On completion, `active` is set to `false` and status is set to `COMPLETED` / `APPROVED`.
2. **Human-Readable Live Handoff (`docs/CHALU_KAAM.md`):**
   - Keep the "Abhi ka haal" section updated after each significant milestone.
3. **Conflict Detection:**
   - If a target file has been modified by another agent or has an uncompleted backup in `backup/`, do NOT overwrite it blindly. Re-read the file, resolve conflicts, or wait.

---

## 4. Documentation & AI Tool Work Histories (`docs/`)

All AI work histories are organized in `docs/`:
* `docs/antigravity.md` — Antigravity (Google DeepMind) task log
* `docs/codex.md` — OpenAI Codex / ChatGPT task log
* `docs/CLAUDE.md` — Anthropic Claude Code task log
* `docs/GEMINI.md` — Google Gemini task log
* `docs/CHALU_KAAM.md` — Live task state & handover across sessions

### Required Log Schema for Every Completed Task:
```markdown
### [Task ID] Task Title
- **Date & Time:** YYYY-MM-DD HH:mm
- **Agent & Model:** <AgentName> (<Model>)
- **Prompt:** <Original User Prompt>
- **Files Inspected:** <List of files>
- **Files Created / Modified:** <List of files>
- **Backup Folder:** `backup/<folder_name>`
- **Validation Result:** APPROVED / FAILED_VALIDATION (X tests passed, 0 warnings)
- **Summary of Changes:** <What was changed and why>
- **Next Steps / Remaining Work:** <If any>
```

---

## 5. Automatic Versioned Backup System (`tools/backup/backup.ps1`)

**CRITICAL RULE:** Never modify, move, or delete any project file before creating a backup.

### 5.1 Starting a Backup (Pre-Edit Snapshot)
Before touching any code or files:
```powershell
powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 start -Name "<task-slug>" -Agent "<AgentName>" -TaskId "<TaskID>"
```
* Creates `backup/<timestamp>_<task-slug>/before/` containing complete source copies of affected files before modification.
* Preserves original relative folder hierarchy and file extensions.
* Excludes build artifacts (`bin`, `obj`, `dist`, `.git`, `.work`, `releases`, and files > 2MB) to prevent disk bloat.
* Updates `docs/CURRENT_TASK.json` with active lock.

### 5.2 Completing a Backup & Calculating Diffs
After files are modified:
```powershell
powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 complete -Folder "<timestamp>_<task-slug>" [-Files "file1,file2"]
```
* Compares SHA256 hashes against `before/`.
* Stores final copies of all `NEW` and `CHANGED` files in `complete/files/`.
* Writes `complete/CHANGED-FILES.txt` and updates task status.

### 5.3 Immutability
* Historical backups are permanent.
* **NEVER** overwrite, rename, or delete existing folders inside `backup/`.

---

## 6. Automated Validation & Version Approval

A task is never complete until validated with actual execution.

### 6.1 Validation Command
```powershell
powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 validate -Folder "<timestamp>_<task-slug>"
```
* Executes:
  1. `$dn build CloudSSD.slnx` (PC Desktop App & Services)
  2. `$dn test tests\CloudSSD.Tests` (C# Unit Tests)
  3. `node --test tests/mobile-js/*.test.js` (if mobile files changed)
* **Status Tags:**
  * `APPROVED`: All required builds and tests pass (0 errors, 0 warnings).
  * `FAILED_VALIDATION`: Any compilation, syntax, or test failure occurs.
  * `PARTIALLY_VALIDATED`: Some checks passed, but full environment check unavailable.
  * `UNVERIFIED`: Tests were not executed.

---

## 7. Restore & Rollback System

To revert changes back to any exact historical version:

```powershell
powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 restore -Folder "<timestamp>_<task-slug>" [-Files "file1,file2"]
```
**Safety Protocol during Restore:**
1. Automatically takes a `before-restore` safety snapshot of current files.
2. Restores original files from `before/` over the project.
3. Deletes any `NEW` files created by that task.
4. Preserves all historical backups in `backup/`.
5. Logs the restoration event in `docs/RESTORE_LOG.md`.

---

## 8. Git & GitHub Upload Rules

1. **No Unrequested Pushes:** Never execute `git push` unless the user explicitly commands it in their prompt.
2. **Secret & Credential Protection:**
   - NEVER stage or push `client_secret*.json`, `installer\google-client.json`, `mobile-android\google-oauth.json`, or any API keys.
   - Run the staged secret scanner before committing:
     ```powershell
     node .work\scan-staged.js roshan rosha I2221
     ```
3. **Commit Integrity:** Check git status with `git status --short`. Only commit the files related to the specific task.

---

## 9. 18 Strict Rules — Must Never Violate

1. **Never modify an existing file before creating a complete pre-edit backup.**
2. **Never overwrite or delete any historical backup in `backup/`.**
3. **Never delete historical versions automatically.**
4. **Never modify unrelated project files outside your task scope.**
5. **Never touch or modify `src\CloudSSD.Desktop\App.xaml.cs` (Critical Core File).**
6. **Never reorganize the entire project or change folder structures unnecessarily.**
7. **Never create duplicate AI work-history files for the same tool.**
8. **Never ignore `RULE.md`.**
9. **Never ignore relevant previous AI work or overwrite another agent's active work.**
10. **Never claim a test passed without actually executing it.**
11. **Never mark an unverified version as `APPROVED`.**
12. **Never restore an older version without backing up the current state first.**
13. **Never push to GitHub without explicit user instruction.**
14. **Never commit secrets, tokens, credentials, or private keys to Git.**
15. **Never push files larger than 100MB to GitHub.**
16. **Never report an incomplete task as complete.**
17. **Never hide a backup failure or continue editing if a backup fails.**
18. **Never sacrifice existing project data or delete documentation.**

# 2026-11-16_1918_mcode-backup-readme-identity-fix — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-007
- **Status:** Validation Status: APPROVED (build 0 warning / 0 error, C# test **472/472**)
- **Complete hua:** 16-11-2026 19:20

## Asli gadda

Pichle backup (TASK-MCODE-006) ka `complete\README.md` me likha tha:

```
- **Agent:** Antigravity
- **TaskId:**
```

Ye galat tha. `backup.ps1` me agent/task id sirf `start` step par likhe jaate hain (`TASK_INFO.json` me),
aur `complete` / `restore` steps apna **command line** value use karte the — jo default `Antigravity` hai aur
TaskId khali. Matlab jo bhi kaam MiniMax Code ne kiya, uski README me Antigravity likha jaata tha — audit
trail galat naam ke saath.

## Kya badla (`tools/backup/backup.ps1`)

1. Naya helper `Get-BackupMeta(dir)` — `TASK_INFO.json` ko 5.1-compatible tareeke se padhta hai
   (`ConvertFrom-Json -AsHashtable` PS 5.1 me nahi hai — wahi gadda TASK-MCODE-003 me bana tha).
2. Naya helper `Resolve-Identity(dir)` — agent aur task id ko backup ke apne metadata se uthata hai.
   **Command line par diya hua value hamesha pehle:** command line > `TASK_INFO.json` > default.
3. `complete` aur `restore` modes ab `Resolve-Identity` call karte hain:
   - `complete\README.md` → sahi Agent + TaskId
   - `docs\RESTORE_LOG.md` → sahi Agent
4. `-Agent` ka default ab `"Antigravity"` se `""` kar diya (taaki pata chale ki user ne diya ya nahi);
   `start` mode me default ab wahi pehla behaviour hai.

## Proof (sandbox me end-to-end)

Script ko ek throwaway repo me copy karke (`$PSScriptRoot\..\..` se `repo/backup`, `repo/docs` bante hain)
poora cycle chala:

```
complete -Folder '2026-11-16_9999_fake-task'
  → README me: Agent: MiniMax Code | TaskId: TASK-TEST-999   ✅
restore  -Folder '2026-11-16_9999_fake-task'
  → RESTORE_LOG.md: | 2026-11-16 19:20 | 2026-11-16_9999_fake-task | MiniMax Code | ... | RESTORED_OK |   ✅
```

Sandbox baad me hata diya gaya (repo ke andar koi test folder nahi chhoda).

Live proof: is backup ka `complete\README.md` **khud script ne** banaya — aur usme sahi likha hai:
`Agent: MiniMax Code`, `TaskId: TASK-MCODE-007`. Pehle wala (006 ka) galat README haath se theek kar diya gaya.

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1918_mcode-backup-readme-identity-fix"

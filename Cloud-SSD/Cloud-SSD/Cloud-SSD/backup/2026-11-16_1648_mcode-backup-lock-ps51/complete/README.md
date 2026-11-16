# 2026-11-16_1648_mcode-backup-lock-ps51 — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-003
- **Status:** Validation Status: APPROVED (build 0 warning/0 error, C# test 470/470)
- **Complete hua:** 16-11-2026 16:51

## Kaam kya tha

TASK-MCODE-002 ka backup band karte waqt pata chala ki `tools\backup\backup.ps1` ka task-lock
(`docs\CURRENT_TASK.json`) Windows PowerShell 5.1 par **kabhi update hi nahi hota**.

## Asli gadda (evidence)

`backup.ps1` me `ConvertFrom-Json -AsHashtable` use ho raha tha. Ye option **PowerShell 6+ me hai,
Windows PowerShell 5.1 me nahi**. Script `powershell` (5.1) se chalti hai → `try/catch` ne error chhupa diya →
lock file silently update nahi hui. Nateeja:

- `active` kabhi `false` nahi hua → har naye task ko "Another task ... is currently in progress" warning milta tha.
- `validationStatus` kabhi likha hi nahi gaya → `VALIDATION.txt` ban'ti thi par lock me nahi.
- `complete` ka status update bhi chup-chaap fail hota tha (lock manually band karna padta tha).

## Kya fix hua

`tools\backup\backup.ps1` me naya helper **`Read-TaskLock`** — lock file ko plain hashtable me padhta hai
(`$parsed.PSObject.Properties` se), jo 5.1 aur 7+ dono par chalta hai. Chaar jagah laga diya gaya:

1. `start` — conflict check ("another task running" warning ab sach me dikhti hai)
2. `validate` — `validationStatus` likhta hai
3. `restore` — `status: RESTORED`
4. `complete` — lock release (`active: false`, `status: COMPLETED`)

## Proof (isi task me)

- `validate` chalane par `docs\CURRENT_TASK.json` me khud-ba-khud `validationStatus: "APPROVED"` likha gaya
  (pehle kabhi nahi hota tha).
- `complete` chalane par lock apne aap `active: false` + `status: "COMPLETED"` ho gaya (pehle manual karna padta tha).

## Badle hue files

- `tools/backup/backup.ps1` (changed)
- `docs/MCODE.md` (changed — TASK-MCODE-003 entry)
- `docs/CHALU_KAAM.md` (changed — naya "COMPLETE" entry)
- `docs/CURRENT_TASK.json` (changed — lock file)

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1648_mcode-backup-lock-ps51"

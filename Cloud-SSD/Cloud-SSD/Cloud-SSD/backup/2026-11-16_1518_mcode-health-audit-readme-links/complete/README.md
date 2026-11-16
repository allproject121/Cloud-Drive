# 2026-11-16_1518_mcode-health-audit-readme-links — Kaam ka poora record

- **Agent:** MiniMax Code (MCode)
- **TaskId:** TASK-MCODE-001
- **Status:** Validation: **APPROVED** (build 0 errors, C# 465/465 tests pass)
- **Kaam:** Project health audit — sirf padha, **koi source code nahi badla**
- **User Command:** "ha tum bhi aapane name ka file banakr usme kam karna or abhi isme kya kya chije tik se work nahi kar raha hai ... wo deko or batao"

## Kya kya badla

| File | Kya hua |
|---|---|
| `docs/MCODE.md` | **NAYI file** — MiniMax Code ka apna work log (RULE.md rule 4: har tool ka alag log) |
| `docs/CHALU_KAAM.md` | Sirf ek naya entry — "Project Health Audit (MiniMax Code) - READ-ONLY, COMPLETE" |
| `docs/CURRENT_TASK.json` | Backup script ne lock kiya tha, ab `active: false`, status COMPLETED |

**Koi `.cs`, `.java`, `.js`, `.xaml` file nahi chhedhi gayi.** Poora kaam read-only tha.

## Andar kya kya cheda (audit se pata chala)

1. **App abhi band/crashed hai** — `Z:`/`Y:` mounted nahi, `Cloud-SSD.exe`/`rclone.exe` nahi chal rahe, aakhri activity 15:01:28. Windows Event Log: WER `AppTermFailureEvent` (14:52, 14:55, 15:02, 15:05) → clean exit nahi hua.
2. **7.3 GB ka upload adhoora chhoot gaya** — `Cloud-Drive.zip` (7,335,944,963 bytes) 24% par ruka, `errors:89`, `lastError: couldn't list directory: context canceled`, resume nahi hua.
3. **Mount auto-restore fail** — `Could not restore mount All Accounts: Drive Z: did not appear within N s`, `Each Account: Drive Y:` bhi fail, `mountpoint "Z:" didn't became available on mount`, retry loop.
4. **`--links` flag missing** — `symlinks not supported without the --links flag: /` (7×). Code check kiya: `src` mein kahin bhi `--links` pass nahi ho raha.
5. **Union remote ka statfs nahi chalta** — `union root '': Statfs failed: this usage field is not supported` → Explorer mein Z: ki disk-space info galat.
6. **Google API timeout** — `HTTP token bucket error: context deadline exceeded`.
7. **Poori C: drive ka tree walk** — 180+ `Failed to copy: couldn't list directory: context canceled` (`MiniMax Code/...`, `node_modules/...`). `settings.json`: `Mirror.IncludeSystem = true`, `OnlyFolders = []` (Mirror abhi `Paused = true` hai — sahi).
8. **README ke relative links toote** — workspace README 40 me se 37 broken, codebase README 40/40 broken. Wajah: folder structure `Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD` → `Cloud-SSD/Cloud-SSD/Cloud-SSD` hua tha, README update nahi hua. Docs ab `docs/archive/` mein hain (`KNOWN_LIMITATIONS.md`, `WHEN_OFF_PLAN.md`, `WHEN_OFF_BINA_KEY_PLAN.md`); `SETUP.md`, `ARCHITECTURE.md`, `SECURITY.md`… codebase root par exist hi nahi karte.
9. **`CHALU_KAAM.md` ka plan-path stale** — `docs\WHEN_OFF_BINA_KEY_PLAN.md` ab `docs\archive\` mein hai.
10. **Branch mismatch** — RULE.md/CHALU_KAAM `feature/multi-device` bolte hain, repo abhi `main` par hai.
11. **Ek adhoora backup** — `backup/2026-11-14_2003_before-restore-from-2026-11-14_2000_system-verification` (sirf `before/`).
12. **Version drift** — README badge PC 0.7.0 / phone 0.8.0, par build 0.9.0 (`dist\Cloud-SSD-0.9.0-win-x64`).
13. **Purana brand log naam** — `logs\cloudplayx-20261116.log` (baaki sab `Cloud-SSD`).
14. **Plain-text secrets** — `settings.json` mein `PairingToken` aur `MediaKey` raw (rclone.conf DPAPI se encrypted hai, settings.json nahi).
15. **Phone se 2 din se link nahi** — paired "vivo I2221" ka `LastSeen` 14 Nov 17:11 → Phase 3 ka asli test (3.7) abhi tak nahi hua.
16. **`.work` ke purane patch scripts** — `.work\p3-*.js`, `.work\k1-pc.js` par "dobara mat chalao" likha hai, par machine-readable marker nahi.

## Jaanch (kya chala)

```
dotnet build CloudSSD.slnx                -> 0 Warning(s), 0 Error(s)
dotnet test tests\CloudSSD.Tests          -> 465 passed, 0 failed
node --test tests\mobile-js\*.test.js     -> 45 pass, 0 fail
phone page dono copies (assets vs wwwroot) -> SHA256 same
```

`tools\backup\backup.ps1 validate` → **APPROVED** (`VALIDATION.txt`).

## Wapas kaise jaayein (restore)

```
tools\backup\backup.ps1 restore -Folder "2026-11-16_1518_mcode-health-audit-readme-links"
```

* `docs/MCODE.md` (nayi file) → delete ho jayegi
* `docs/CHALU_KAAM.md`, `docs/CURRENT_TASK.json` → `before/` wali copy wapas aa jayegi
* Purane backup folders bilkul nahi badlenge

## Aage ka kaam

Sirf tab jab user kahe. Fix ka order (suggested):
1. Mount restore fail + app crash (sabse zyada nuksaan-deh)
2. `--links` flag missing
3. README ke 40 broken links + stale plan-path
4. Phone par asli jaanch (Phase 3 step 3.7)

Har fix ke liye pehle naya `backup.ps1 start`, phir code → build → test → asli device jaanch → `complete` + `docs/MCODE.md` mein entry.

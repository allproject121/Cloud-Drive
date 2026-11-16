# MCODE.md — MiniMax Code Work Log & Action Registry

> **Purpose:** MiniMax Code (MCode) agent dwara Cloud-SSD project mein kiye gaye sabhi kaam (audit, bug fixes, code edits, maintenance) ka central work history log.
> **App Name:** Cloud-SSD (Virtual Drive: Cloud Drive)
> **Agent:** MiniMax Code (MCode)
> **Central Rules:** See `RULE.md`
> **Note:** Yeh file sirf MCode ka apna log hai — Antigravity / Codex / Claude / Gemini ke logs bilkul alag hain (RULE.md rule 7).

---

## 🛠️ Summary of Work Done by MiniMax Code

---

### [TASK-MCODE-001] Project Health Audit — Build/Test + Runtime Logs + Broken README Links

- **Date & Time:** 2026-11-16 15:05 – 15:20
- **Agent & Model:** MiniMax Code (MCode, MiniMax-M3.1-Flash)
- **Prompt:** "ha tum bhi aapane name ka file banakr usme kam karna or abhi isme kya kya chije tik se work nahi kar raha hai kisme chijo me error hai ya work nahi kar raha hai wo deko or batao"
- **Files Inspected:**
  - `RULE.md` (root + codebase — dono byte-identical), `docs/CHALU_KAAM.md`, `docs/CURRENT_TASK.json`, `docs/antigravity.md`, `docs/CLAUDE.md`, `.work/haal.txt`
  - `README.md` (workspace root + codebase dono), `src/CloudSSD.App/LocalMobileBridgeService.Files.cs`, `src/CloudSSD.App/LocalMobileBridgeService.Security.cs`, `src/CloudSSD.Mount/RcloneConfigService.cs`
  - Runtime: `%LOCALAPPDATA%\Cloud-SSD\settings.json`, `mounts.state.json`, `startup_debug.txt`, `logs\cloudplayx-20261116.log`, `logs\rclone-cloudssd.log`
  - Windows Event Log (Application + System, last 24h), `Get-PSDrive`, `Get-Service`, `tasklist`
- **Files Created / Modified:**
  - `docs/MCODE.md` (nayi — yeh file)
  - `docs/CHALU_KAAM.md` (sirf haal ka naya entry — koi code nahi)
  - `docs/CURRENT_TASK.json` (backup script ne lock kiya)
  - `backup/2026-11-16_1518_mcode-health-audit-readme-links/` (before/ + complete/)
- **Backup Folder:** `backup/2026-11-16_1518_mcode-health-audit-readme-links`
- **Validation Result:** APPROVED (build 0 errors / 0 warnings, C# tests 465/465 pass, JS tests 45/45 pass) — **sirf code ke liye; project ki runtime health ke liye FAILING**
- **Summary of Changes:**
  - **Koi source code nahi badla.** Yehm kaam sirf jaanch (audit) tha: build, dono test suites, runtime logs, README links aur settings — sab padha gaya, kuch likha nahi gaya.
  - Naya work-history file `docs/MCODE.md` bana (RULE.md rule 4 ke mutabiq per-tool log).
  - Neeche "Mil ki jaanch" mein har finding evidence ke saath darj hai.

#### Mil ki jaanch — jo SAHI chal raha hai (verified)

| Check | Result |
|---|---|
| `dotnet build CloudSSD.slnx` (.NET SDK 10.0.404) | ✅ Build succeeded — 0 Warning(s), 0 Error(s) |
| `dotnet test tests\CloudSSD.Tests` | ✅ 465 passed, 0 failed, 0 skipped |
| `node --test tests\mobile-js\*.test.js` | ✅ 45 pass, 0 fail |
| Phone page ki dono copies (`mobile-android/src/main/assets` vs `src/CloudSSD.Desktop/wwwroot/mobile`) | ✅ SHA256 same — `app.js`, `data.js`, `i18n-words.js`, `index.html` sab match |
| WinFsp | ✅ `WinFsp.Launcher` service Running |
| App startup flow | ✅ `startup_debug.txt`: "Startup completed successfully!" (16 Nov 14:53:45) |

#### Mil ki jaanch — jo TOOTA hua hai (evidence ke saath)

1. **Z: aur Y: drive abhi mounted NAHI hain.**
   `Test-Path Z:\` = False, `Get-PSDrive FileSystem` mein sirf `C:`. `tasklist` mein `Cloud-SSD.exe` aur `rclone.exe` koi nahi. Aakhri rclone activity 16 Nov **15:01:28** (ab ~15:20) — matlab app ab band/crashed hai.

2. **App ne gracefully exit nahi kiya (crash/kill).**
   Windows Event Log mein WER `AppTermFailureEvent` baar baar: 14:52:53, 14:55:52, 15:02:28, 15:02:32, 15:05:18 + `crashpad_log` (15:03:22). App log mein band hone ka koi entry nahi.

3. **Is ki direct nuksaani: 7.3 GB ka upload adhoora chhoot gaya.**
   `rclone-cloudssd.log` ke `core/stats` mein `errors:89`, `lastError:"couldn't list directory: context canceled"`, `retryError:true`; transfer `Claude-SSD Folder/New folder/Cloud-Drive.zip` (7,335,944,963 bytes) sirf **24%** par ruka. Transfer resume nahi hua.

4. **Mount auto-restore dono drives ke liye fail.**
   `cloudplayx-20261116.log`:
   - `ERR AppHost: Could not restore mount All Accounts: Drive Z: did not appear within N s`
   - `ERR AppHost: Could not restore mount Each Account: Drive Y: did not appear within N s`
   - `WRN rclone: mountpoint "Z:" didn't became available on mount - continuing anyway`
   - `INF AppHost: Mount cloudssd: Failed Timed out waiting for the drive to appear` + `Restarting mount in N s (attempt N)` (retry loop)

5. **Symlinks mount par fail ho rahe hain.**
   `Error: symlinks not supported without the --links flag: /` (7 baar, dono remotes). Code check kiya — `src` mein kahin bhi `--links` flag pass nahi ho raha. Node_modules/junction jaise folders isi wajah se error dete hain.

6. **Union remote ki statfs support nahi hai → Z: ki disk-space info galat.**
   `Error: union root '': Statfs failed: this usage field is not supported` — Explorer mein drive ki Total/Free size sahi nahi dikhegi.

7. **Google API ke saath timeout.**
   `Error: HTTP token bucket error: context deadline exceeded` (upload chalte hue).

8. **Mount poori C: drive ka tree walk kar raha hai (noise + slow).**
   180+ `Failed to copy: couldn't list directory: context canceled` — `MiniMax Code/...`, `node_modules/...` ke files. `settings.json` mein `Mirror.IncludeSystem = true`, `Mirror.OnlyFolders = []` — CHALU_KAAM ke "Mirror apne aap poori disk upload karne lage" warning ki wajah yahi hai. Mirror abhi `Paused = true` hai (sahi setting).

9. **README ke saare relative links toote hain.**
   - Workspace root `README.md`: 40 relative links me se **37 broken**
   - Codebase `README.md`: 40 me se **40 broken**
   - Wajah: folder structure `Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD` se badal kar `Cloud-SSD/Cloud-SSD/Cloud-SSD` ho gaya tha, README update nahi hua.
   - Toote hue: 12 `src/*` links, "Folder map", "All documents" table ki poori list (`SETUP.md`, `ARCHITECTURE.md`, `BENCHMARKS.md`, `COMPATIBILITY.md`, `KNOWN_LIMITATIONS.md`, `RAM.md`, `SECURITY.md`, `CONTRIBUTING.md`, `THIRD_PARTY_NOTICES.md`, `docs/GOOGLE_DRIVE_SETUP.md`, `docs/TROUBLESHOOTING.md`, `docs/GAME_AWARE_PROTOCOL.md`), `installer/`, `mobile-android/`, `releases/`, `Cloud-SSD-5TB/`, `LICENSE`, aur archify ke teen screenshots (`archify-system-design.svg` / `-dark.png` / `-light.png`) + logo image.
   - Asli docs ab `docs/archive/` mein hain (`KNOWN_LIMITATIONS.md`, `WHEN_OFF_PLAN.md`, `WHEN_OFF_BINA_KEY_PLAN.md`); baaki (`SETUP.md`, `ARCHITECTURE.md`, `SECURITY.md`…) codebase root par **exist hi nahi** karte. Yaani GitHub par repo ka poora "Docs" section dead hai.

10. **`docs/CHALU_KAAM.md` ka plan-file path stale.**
    File `docs\WHEN_OFF_BINA_KEY_PLAN.md` (aur `docs\WHEN_OFF_PLAN.md`) ko point karti hai, lekin ab wo `docs\archive\` mein hain. Naya agent plan padhne ki koshish karega to fail hoga.

11. **Branch mismatch.** `RULE.md` aur `CHALU_KAAM.md` dono kehta hain branch `feature/multi-device`, lekin repo abhi `main` par hai.

12. **Ek backup folder adhoora.** `backup/2026-11-14_2003_before-restore-from-2026-11-14_2000_system-verification` mein sirf `before/` hai, `complete/` nahi (restore safety snapshot — phir bhi RULE.md ke hisaab se `complete` chahiye tha).

13. **Version drift.** README badge: PC **0.7.0**, phone **0.8.0`. CHALU_KAAM ke hisaab se PC build **0.9.0** (`dist\Cloud-SSD-0.9.0-win-x64`). Installed build 14 Nov 2026 16:01 ka hai.

14. **Purana brand naam log file mein.** Log abhi bhi `logs\cloudplayx-20261116.log` naam se banta hai (baaki sab jagah `Cloud-SSD`). Branding drift.

15. **`settings.json` mein pairing token aur media key plain-text mein** hain (`MobileBridge.PairingToken`, `MobileBridge.MediaKey`). `rclone.conf` DPAPI se encrypted hai, settings.json nahi. (File user-scoped hai aur repo ke bahar hai — low risk, par RULE.md rule 14 ke nazariye se note kiya ja raha hai.)

16. **Phone se real verification 2 din se nahi hui.** Paired device "vivo I2221" ka `LastSeen` **2026-11-14T17:11** hai (aaj 16 Nov). Phase 3 ka asli test (3.7 — "PC app band karke phone se folder kholna") aaj tak nahi hua, isliye wo feature abhi bhi "code ready, verified nahi" hai.

17. **`.work` mein purane patch scripts** (`.work\p3-*.js`, `.work\k1-pc.js`) hain jinke upar "dobara mat chalao" likha hai, lekin koi machine-readable marker nahi — naya agent galti se chala sakta hai.

#### Next Steps / Remaining Work

- **Koi code change is task mein nahi kiya gaya** — sirf audit. Fix ka faisla user ka hai.
- Fix karne ka suggested order (agar user kahe):
  1. Mount restore fail + crash → app log + rclone log ke basis par reproduce (app start karke Z:/Y: dekhna).
  2. `--links` flag missing → symlink error ka seedha fix.
  3. README ke 40 broken links → naye folder structure ke hisaab se path badalna + `docs/archive` wale docs ko sahi jagah link karna.
  4. `CHALU_KAAM.md` mein stale plan-file path (`docs\archive\...`).
  5. Phone par asli jaanch (Phase 3, step 3.7) — abhi 2 din se device link nahi hua.
- Har fix ke liye pehle `tools\backup\backup.ps1 start`, phir code → build → test → asli device jaanch → `complete` + is file mein entry.

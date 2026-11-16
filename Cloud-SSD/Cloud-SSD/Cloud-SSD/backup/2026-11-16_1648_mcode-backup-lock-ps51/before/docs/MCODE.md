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

---

### [TASK-MCODE-002] Sab kuch theek: mount, docs, release build, settings

- **Date & Time:** 16 Nov 2026, 15:30 – 17:00
- **Agent & Model:** MiniMax Code (MCode, MiniMax-M3.1-Flash)
- **Prompt:** "fix karo sari chije" (TASK-MCODE-001 ki audit ke 17 points)
- **Files Inspected:** `src/CloudSSD.Mount/{MountPlanning,MountService,RcloneConfigService}.cs`, `src/CloudSSD.Diagnostics/Logging.cs`, `src/CloudSSD.Core/Settings.cs`, `src/CloudSSD.Desktop/ViewModels/ConfigViewModels.cs`, `src/CloudSSD.Desktop/App.xaml.cs` (sirf padha — RULE.md rule 5 me banned hai), `installer/build-release.ps1`, `tools/backup/backup.ps1`, `tools/live-test/pc-close.ps1`, runtime logs + Windows Event Log + `settings.json`
- **Backup Folder:** `backup/2026-11-16_1532_mcode-fix-batch-1`
- **Validation Result:** APPROVED (build 0 errors / 0 warnings, C# tests **470/470** pass (465 + 5 naye), JS tests 45/45 pass, **asli PC par install + Z:/Y: jaanch**)

#### Asli gadda kya tha (root cause, guess nahi)

| # | Problem | Asli wajah (evidence) |
|---|---|---|
| 1 | `symlinks not supported without the --links flag: /` har mount par | `MountFlagBuilder.Build` me `--links` kabhi add hi nahi hua tha. `--links` ke bina drive ka root symlink rehta hai → rclone har mount par ye error deta tha |
| 2 | Drive letter 45 s me nahi aata → "Could not restore mount" | `--vfs-refresh` poore drive ka tree walk karta hai; Google Drive API us waqt **403 Quota exceeded** de raha tha (ek session me 377 baar) → listing late hoti thi → 45 s ka timeout beech me kat deta tha, app rclone maar kar dobara shuru karta tha |
| 3 | Explorer me drive ki space galat/0 (`union root '': Statfs failed`) | Wahi symlink: root theek se resolve nahi hua → statfs fail. `--links` ke baad statfs chalta hai (16.5 TB total, 15.7 TB free) |
| 4 | Release build toot chuka tha | `installer\build-release.ps1` root par `THIRD_PARTY_NOTICES.md` maangta tha, jo restructure ke baad `docs\archive\` me chala gaya tha → `Copy-Item ... does not exist` → **release banana hi nahi ho raha tha** |
| 5 | README ke 40/40 links toote | Folder structure `Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD` → `Cloud-SSD/Cloud-SSD/Cloud-SSD` badla tha, README update nahi hua |
| 6 | Log file `cloudplayx-*.log` | Purana brand naam code me bacha tha |
| 7 | `backup.ps1 complete -Files a,b,c` "0 files" batata | `powershell -File` se comma-list ek hi string banta hai → array nahi banti → kuch copy hi nahi hota tha |
| 8 | Mirror poori disk upload karne lagta hai | `settings.json`: `IncludeSystem = true`, `OnlyFolders = []` → poora C: drive (7.3 GB ka zip, node_modules) cloud me chala gaya tha |
| 9 | `settings.json` me pairing token aur media key plain-text | DPAPI use nahi ho raha tha |
| 10 | `pc-close.ps1` app ko band nahi kar pata | WPF ka MessageBox **top-level** window hai, main window ka child nahi → UIA `TreeScope::Children` se main window ke andar dhoondha hi nahi gaya; saath hi `CloseMainWindow()` `False` return karta hai (WM_CLOSE post nahi hota) |
| 11 | WER "AppTermFailureEvent" | Ye Cloud-SSD ka crash **nahi** tha — event ka payload khaali hai, `crashpad_log` wala to `MicrosoftEdgeUpdate.exe` ka hai. Pehle ka "app crash" claim galat tha; sach: app band hua tha aur 7.3 GB ka upload adhoora chhoda |

#### Kya theek kiya

**Code (C#)**
- `src/CloudSSD.Mount/MountPlanning.cs` — `--links` flag add (purane rclone par warning ke saath skip).
- `src/CloudSSD.Mount/MountService.cs` — drive-appear timeout **45 s → 120 s** (`DriveAppearTimeout`), timeout par ab Google-quota wala actionable message.
- `src/CloudSSD.Mount/RcloneConfigService.cs` — `ExplainError`: Google ke 403 quota pe "apni OAuth key banao" wala message (generic rate-limit se pehle check hota hai).
- `src/CloudSSD.Diagnostics/Logging.cs` — log file `cloudssd-<date>.log` (purane `cloudplayx-*.log` bhi prune hote hain).
- `src/CloudSSD.Core/SecretProtector.cs` (nayi) — DPAPI wrapper; `src/CloudSSD.Core/Settings.cs` — `JsonSettingsStore` save par token/media key protect, load par unprotect (purane plain files bhi chalti hain); `src/CloudSSD.Desktop/ViewModels/ConfigViewModels.cs` — diagnostics zip me disk wali (protected) settings.json.
- `src/CloudSSD.Core/CloudSSD.Core.csproj` — `System.Security.Cryptography.ProtectedData` (already cached).

**Scripts**
- `installer/build-release.ps1` — `Find-Doc` helper: doc root ya `docs\archive` dono me dhoondhta hai → **release build phir se chalta hai** (95.3 MB zip, SHA256 `1105a640…`).
- `tools/backup/backup.ps1` — `-Files "a,b,c"` comma-list ab sahi split hota hai.
- `tools/live-test/pc-close.ps1` — MessageBox desktop level par dhoondha jaata hai.

**Docs**
- README ke **teeno copies** (workspace root, git root, codebase) ke links apne base path ke hisaab se theek: **0 broken** (pehle 37/40 aur 40/40). Badge: PC **0.9.0**, phone **0.12.0** (AndroidManifest). Download links naye repo path + naye files par.
- `docs/DEV_TESTING.md`, `docs/PROJECT_POLICIES.md`, `docs/archive/SETUP.md` ke 6 toote links (0 broken ab).
- `docs/CHALU_KAAM.md` — plan paths `docs\archive\...`; `RULE.md` (3 copies) — branch `main` + `feature/multi-device` dono.
- `.work/README-DO-NOT-RERUN.md` (nayi) — kaam se lag chuke patch scripts ka list, "dobara mat chalao".
- `backup/2026-11-14_2003_…/complete/README.md` (nayi) — ye folder restore safety snapshot tha, "adhoora" nahi.

**Runtime config (user ki app data)**
- `settings.json` → `Mirror.OnlyFolders = ["C:\\Users\\Roshan\\Documents"]`, `Mirror.IncludeSystem = false`, `Mirror.Paused = true` (poori disk upload ka risk band).

**Naye tests (5)**
`Symlink_support_is_on_so_the_drive_root_is_not_a_symlink`, `The_drive_may_take_longer_than_45_seconds_to_appear`, `A_google_drive_quota_error_says_what_to_do`, `The_pairing_token_and_the_media_key_are_not_written_in_plain_text`, `An_older_settings_file_with_plain_secrets_still_loads`.

#### Asli PC par jaanch (16 Nov, naya build install karke)

| Check | Nateeja |
|---|---|
| Build + install | ✅ `Cloud-SSD 0.9.0` install hua |
| Naya log file | ✅ `cloudssd-20261116.log` bana (purana naam gaya) |
| `--links` command me | ✅ rclone command line me `--links` dikh raha hai |
| Symlink error | ✅ **0** (pehle har mount par aata tha) |
| Y: drive | ✅ 16:07:32 par "Mounted at Y:" |
| Z: drive | ⚠️ quota 403 storm (52–60 per session) me 120 s me nahi aaya; retry chal raha hai |
| Naya error message | ✅ "Google Drive API quota khatam ho gaya (403). Apni OAuth key use karo: … Switch to my own Google key" |

#### A/B test: `--vfs-refresh` hi wajah hai? (nahi — test kiya, reject hua)

`.work\mount-flagtest.ps1` se app ke bilkul wahi flags do mounts par (pehle quoting galat thi — `--filter "- …"` aur
`--volname "…"` me space wali value split ho jaati thi, rclone "malformed rule" ke saath turant exit kar deta tha):

| Mount | Drive letter aaya | Quota 403 | Symlink error |
|---|---|---|---|
| `--vfs-refresh` ke saath (app jaisa) | ✅ **6 s** | 0 | 0 |
| `--vfs-refresh` ke bina | ✅ **3.5 s** | 0 | 0 |

Matlab `--vfs-refresh` sasti cheez hai (2.5 s ka fark), asli blocker nahi — **Google Drive API ka shared rclone
client_id** hai. Usi waqt quota khatam hota hai (ek session me 377 baar "403 Quota exceeded"), tab listing late hoti
hai aur drive letter 120 s me bhi nahi aata. Quota khul jane par drive 3.5–6 s me aa jaati hai.
Isliye `--vfs-refresh` **nahi** hataya gaya (galti ka fix nahi kiya) — fix wahi hai jo ab message me bata raha hai:
apni OAuth key. Sirf apni key se ye solve hota hai; code se nahi.

#### Jo ab bhi user ke haath me hai

1. **Apni Google key** (Cloud Drives → "How do I get a key?" → "Switch to my own Google key"). Bina iske rclone ka shared client_id 2026 me retire ho raha hai aur uski per-minute quota khatam rehti hai → drive late aati hai. Ye code se nahi, user ke Google Cloud Console se banegi.
2. **Phone par jaanch** (Phase 3, step 3.7): paired "vivo I2221" ka `LastSeen` 14 Nov 17:11 hai — 2 din se link nahi.

#### Next Steps / Remaining Work

- `pc-close.ps1`: `CloseMainWindow()` `False` deta hai (custom title bar WM_CLOSE nahi leta) → ab asli X click ka fallback hai; MessageBox desktop level par dhoondha jaata hai.
- Push sirf user ke kehne par (RULE.md rule 13).

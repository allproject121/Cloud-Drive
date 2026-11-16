# 2026-11-16_1834_mcode-fast-browsing-mode — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-005
- **Status:** Validation Status: APPROVED (build 0 warning / 0 error, C# test **472/472**)
- **Complete hua:** 16-11-2026 18:50

## User ka shikayat

*"zip abhi bhi bahot slow open ho raha hai ya bol do open hi nahi ho raha hai"* (quiz se confirm: **"Zip open
hi nahi hota / bahut slow"**).

## Asli gadda (measured)

Windows koi bhi zip kholte waqt uska **end** padhta hai (zip ka "file list" wahan hota hai). Par drive
`--vfs-cache-mode full` par chalti thi, aur us mode me rclone koi bhi file kholte hi **poora file** download
kar leta hai. A/B test (same file, same machine, same second):

| Mount | 1 MiB ka end padha | Actually kitna data utra |
|---|---|---|
| `--vfs-cache-mode full` (pehle) | **38.8 s** | **460 MB** (poora zip) |
| `--vfs-cache-mode writes` | **5.3 s** | **0 MB** (sirf maanga gaya range) |

rclone ke log me bhi confirm: `vfs cache: stopping download thread as it timed out` (poora file gir raha tha).

**Do bade nuksan ek hi wajah se:**
1. Zip/installer kholna = poori file ka download (460 MB zip = 460 MB) → "zip khulta hi nahi".
2. Har folder listing par ArchiveWarmer har archive ka end padhta hai → full mode me usse bhi **poora archive**
   download ho jaata tha → quota jharta tha (log 305,051 lines, cache 13.7 GB) → phir sab kuch crawl karta tha.

## Kya fix hua

- `CacheSettings.VfsCacheMode` (naya): `"full"` (default — games ke liye: file disk par rehti hai) ya `"writes"`
  (fast browsing — sirf likhi hui file disk par, reads seedhe cloud se).
- `MountPlanning` usi hisaab se `--vfs-cache-mode` set karta hai; unknown value → `"full"`.
- **UI toggle**: Cloud Drives page par naya "Drive mode" card → checkbox "Fast browsing" + button
  "Apply and reconnect" (cache mode mount shuru hone par tay hota hai, is liye button drives reconnect karta hai).
- Is PC par `VfsCacheMode = "writes"` set kar diya (user ka kaam: drive se install karna).

## Proof (naya build, Z: par)

- `--vfs-cache-mode writes` rclone command me dikh raha hai ✅
- 460 MB zip ka end padhna: **21.5 s** aur **0 MB** extra cache (pehle 38.8 s + 460 MB)
- Dusra read (buffer me): **47 ms** — local file jaisa
- Z: ready 15 s me; `--vfs-refresh` abhi bhi hai (khaali-folder wala bug na aaye)

## Bacha hua wait (code se nahi)

Google ke **shared rclone quota** ka backoff: log me `Rate limited, increasing sleep to 16.4s`. Ye apni OAuth key
se khatam hota hai (Cloud Drives → "How do I get a key?" → "Switch to my own Google key").

## Release build

`dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB),
SHA256 `cb4960b8fa07791b16e5568d944b56fabfdd1fd5b752c035280e3f626c2f1bd1` — install ho chuka hai.

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1834_mcode-fast-browsing-mode"

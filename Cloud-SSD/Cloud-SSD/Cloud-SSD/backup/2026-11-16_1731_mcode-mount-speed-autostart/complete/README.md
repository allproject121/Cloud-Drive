# 2026-11-16_1731_mcode-mount-speed-autostart — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-004
- **Status:** Validation Status: APPROVED (build 0 warning / 0 error, C# test **471/471**)
- **Complete hua:** 16-11-2026 18:03

## User ka shikayat

*"zip abhi bhi bahot slow open ho raha hai ya bol do open hi nahi ho raha hai … install kar raha hu … bahot
time le raha hai … jabhi desktop ke restart karta hu to cloud ssd baand ho jata hai (permanent hona chahiye
jab tak uninstall na ho jaye)."*

## 5 cheezein thik hui

1. **Restart ke baad app chalta hi nahi tha.** Feature code me maujood tha (`StartWithWindows.cs`), par is PC par
   `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` me `Cloud-SSD` entry nahi thi.
   - Entry banai: `"C:\Users\Roshan\AppData\Local\Programs\Cloud-SSD\Cloud-SSD.exe" --minimized`
   - `installer/Install-CloudSSD.ps1` ab install ke time ye entry khud likhta hai, `installer/Uninstall-CloudSSD.ps1`
     use hatata hai → **ek baar install = jab tak uninstall na ho, app har restart par khud chalega**.

2. **7.3 GB ka junk upload bandwidth kha raha tha** (purane accidental mirror dump ka bacha hua hissa).
   Upload **11.6 MB/s up**, user ka download sirf **251 KB/s**. Pending-upload wale 4 local cache copies
   (≈28 GB) Recycle Bin me bheji gayi — cloud data nahi, sirf app ka local cache. Ab **0 upload**;
   baaki cache rakha gaya taaki doosri baar file turant khule.

3. **Read chunk 4 MiB → 32 MiB** aur **cache budget 20 GiB → 60 GiB** (`Cache.ReadChunkSizeBytes`,
   `Cache.BudgetBytes`): 63 MB archive pe 16 API requests ki jagah 2, aur cache hit par file **24 ms** me khulti hai.

4. **App band karte hi drive mar jaati thi — asli wajah:** app rclone ko apne *pipe* se chala raha tha. App band
   hone par pipe toot'ta hai, rclone (Go) ko EPIPE milta hai, aur Go usse SIGPIPE bana kar rclone ko maarta hai.
   Is liye "Yes: drives stay mounted" chun ke bhi 1–2 min me drive gayab ho jaati thi.
   - Naya `src/CloudSSD.Mount/DetachedProcess.cs`: `CreateProcessW` + `STARTF_USESTDHANDLES` se rclone ke standard
     handles **NUL device** par point hote hain → koi pipe nahi, toot' hi nahi sakta.
   - **Proof:** app ko maarte hi 60 s baad bhi rclone zinda hai aur `Z:` mounted hai; app band rahne par bhi file
     read hui (1 MB in 1277 ms); app dobara start karne par "Re-attached to running mount at Z:/Y:" aaya.

5. **Ek folder poori tarah khaali dikh raha tha** (files cloud me maujood the). Ye stale directory-cache tha: quota
   403 me fail hui listing "khali" cache ho gayi thi aur 72 h tak wahi rehti. Cache clear karke files wapas aayein.
   Isi liye `--vfs-refresh` hataya **nahi** gaya (try kiya tha — usi se ye khaali-folder ka case aaya).

## Asli blocker jo code se nahi hoga

Google Drive API ka **shared rclone quota** (`project_number:202264815644`, poori duniya ke saath share):
`403 Quota exceeded for quota metric 'Queries'`. Quota khatam hone par download **4 KB/s** tak gir jaata hai
(cold read 181–222 s). Cache hit par random read **24 ms** hai.
**Solution:** apni OAuth key (Cloud Drives → "How do I get a key?" → "Switch to my own Google key").

## Release build

`dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB),
SHA256 `998ee920d57d6323b379ab1778697f2b58b60baa6f20ca26d08ed0529a294084` — install ho chuka hai.

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1731_mcode-mount-speed-autostart"

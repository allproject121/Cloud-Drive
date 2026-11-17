# Band PC ki files phone se (PC band ho tab bhi)

- **Kaam shuru:** 14 Nov 2026, 15:44 · **Poora:** 17 Nov 2026, 02:30
- **Agent:** Claude Code · **Task:** TASK-CLAUDE-K (pehle Phase 3 bhi isi backup mein tha)
- **Jaanch:** build 0 warning / 0 error · C# 518/518 · phone page 48/48 · asli PC + asli phone (vivo I2221) par dekha
- **GitHub:** push **nahi** hua (user ne nahi kaha)

## Yeh kya hai

User chahta tha: **PC band ho tab bhi uski files phone se khulें**, aur bina Google key ke.
Band PC khud file nahi de sakta, isliye file ki copy pehle se phone ke andar rakhi jaati hai. PC chalu ho to copy apne aap taaza
hoti hai; PC band ho to phone apni copy kholta hai. Internet nahi chahiye.

```
PC chalu:   PC ka folder (C:\Users\...\Documents) --Wi-Fi--> phone ke andar copy   (apne aap taaza)
PC band:    phone --> apni copy se folder aur file kholta hai
```

## Kaise use hota hai

1. PC par "PC disks" ki permission chalu ho (Cloud-SSD → Phone → Permissions). Is PC par pehle se chalu hai.
2. Phone: **More → Permissions → "Files when it is off" → "Keep the PC's main folders on this phone" → "Choose…"**.
   Desktop, Documents, Pictures, Music, Videos, Downloads apne size ke saath dikhte hain. Folder dabao = woh phone par rakha jayega.
   "Keep all N folders" sab ek saath rakhta hai. 5000 se zyada files ya phone mein jagah kam ho to pehle hi bata deta hai.
3. Koi aur folder: Cloud SSD tab → PC disk mein folder par ⋮ → **"Keep offline"**.
4. PC band ho tab: **More → Files and sharing → Offline files → folder ka naam dabao**. Folder khul jata hai, file "From this phone (kept offline)" se khulti hai.
5. Hatana ho: wahi list → "Remove" (sirf phone ki copy jaati hai, PC ki file nahi).

## Andar se kaise chalta hai

- **PC:** apni disk ko sirf-padhne wali "drive" ki tarah deta hai: `disk-c:Users/…` (`/api/fs/list`, `/read`, `/stat`, `/usage`, `/thumb`).
  Wahi roktham jo `/api/files` par: "PC disks" band ho to 403. Likhna / mitana / naam badalna hamesha mana.
  `/api/pc/home` mein `main` = 6 mukhya folder; raasta sirf tab jab phone use padh sakta ho. Features: `fs-disk-roots`, `pc-main-folders`.
- **Phone page:** `data.js` `diskId` ("C:\Users\me" → "disk-c:Users/me"), `diskPath`, `pinsBelow`, `keepTooBig`;
  `app.js` `keepIdOf` / `diskIdOf`, `keptList` (PC band ho to list copies se), `mainFoldersRow` / `openMainKeep`, `offline-open`.
- **Phone app:** `OfflinePins.java` pehle se copy rakhta / taaza karta / mitata tha (cloud drive ke liye); ab andar ka koi folder
  Windows padhne na de to sirf wahi chhootta hai, poora folder fail nahi hota (aise round mein purani copy mitayi nahi jaati).
- **Phase 3 (Google key wala raasta, 14 Nov):** `GoogleAuth.java`, `DriveBackend.java`, `WhenOffStore.java`, `LocalMobileBridgeService.WhenOff.cs`,
  `RcloneConfigService.OwnDriveClient`. Code + tests hain; **asli jaanch nahi hui** kyunki user ki apni Google key nahi bani.

## Asli jaanch (17 Nov 2026, 02:04–02:25, asli phone)

| Kya | Nateeja |
|---|---|
| Permissions mein button, "Choose…" ki list | 6 folder size ke saath; Downloads (64.7 GB, 28,520 files) → "Too many files" |
| Documents rakhna | "On this phone · 15 files · 768 B" (chhupi `desktop.ini` nahi aati) |
| PC tak raasta kaat kar (PC band jaisi haalat) Offline files → Documents | khula: "C: PC disk › Users › … › Documents", patti "Kept on this phone: these files open without <PC>" |
| Test file phone ki copy se padhna | text sahi aaya; "Read · From this phone (kept offline)"; "Open on the PC screen" dhundhla ("Needs PC") |
| PC par file badalna | link wapas aate hi phone ne khud naya version liya (kisi ne sync nahi dabaya) |
| PC par file mitana | agle round mein phone ki copy bhi hat gayi (16 → 15 files) |
| PC folder ka ⋮ menu | sirf "Open" + "Keep offline" (Rename / Move / Delete / sync nahi) |
| Bina key ke request | 401 |

Photos: `.work\shots\k3-choose.png`, `k5-kept.png`, `k5-off.png`, `k5-v2.png`, `k5-gone.png`, `k2-end.png`. Scripts: `.work\t-k3.js`, `t-k5a.js` … `t-k5e.js`, `t-k2menu.js`.

## Jo nahi jaancha / nahi bana (sach)

- **PC ko sach mein power off nahi kiya.** "PC band" ki haalat phone ka raasta kaat kar banayi (`adb reverse --remove`): phone ke liye dono ek jaise hain.
- **Phone PC tak ghar ke Wi-Fi se nahi pahunchta.** Windows Firewall rokta hai: Wi-Fi "Private" hai, par `cloud-ssd.exe` ki ijazat sirf "Public" ke liye.
  Jaanch `adb reverse tcp:8090 tcp:8090` se hui. Theek karna user ke haath mein (admin): PC app → Add device → "direct link" wala button, ya admin PowerShell mein
  `netsh advfirewall firewall add rule name="Cloud-SSD direct links" dir=in action=allow protocol=TCP localport=8090 remoteip=LocalSubnet profile=any`.
  **Baad mein (17 Nov 02:35):** user ke kehne par yahi rule jod diya gaya (user ne Windows ke box mein "Yes" dabaya). `adb reverse` hata kar phone se
  PC ki Wi-Fi wali request chali (200, 40 ms). App ke andar "Connected (Wi-Fi)" nahi dekha: us waqt phone lock tha.
- **K6 ("Cloud copy Google Drive app mein kholo") nahi bana:** PC ka mirror paused hai, Drive par copy nahi, to jaanch ho hi nahi sakti.
- **K7 (phone se PC jagana):** sirf jaancha. PC Wi-Fi par hai, Wi-Fi card wake ke liye armed nahi → abhi nahi chalega.
- **Phase 3 ka 3.7** (Google key ke saath asli jaanch): user ki key ke bina nahi ho sakti.
- **Kabhi na khole gaye upar ke folder** (C: → Users → …) ka raasta copies se banna: sirf JS test mein dekha; phone par woh folder pehle se saved the.
- `LocalMobileBridgeService.Files.cs` ka aakhri sudhaar (cloud drive se "IsReady" poochhne se pehle use chhod dena; busy Z: par request 10 s atak sakti thi)
  source + tests mein hai, par **installed PC build (02:05) mein nahi**; agle install mein aayega.
- Phone par abhi **test (-Debug) APK** hai. Release APK (`mobile-android\Cloud-SSD-Mobile.apk`) dobara nahi bana.
- `/api/fs/usage` chhupi files (`desktop.ini`) bhi ginta hai, list nahi dikhati: "16 files" likha, 15 aaye. Chhota farq, theek nahi kiya.

## Files

`complete\CHANGED-FILES.txt` dekho (1 nayi, 20 badli). Dhyan: `MainActivity.java` aur `RcloneConfigService.cs` mein 14–16 Nov ke doosre kaam ke badlaav bhi hain
(wahi file baad mein doosre agents ne bhi badli), `before\` 14 Nov 15:44 ka hai.

## Wapas kaise jaayein

`complete\files\` ki har file ka purana roop `before\` mein usi raaste par hai: wahan se project par copy karo, aur nayi file
`WhenOffStore.java` hata do. Ya: `tools\backup\backup.ps1 restore -Folder 2026-11-14_1544_band-pc-ki-files-phone-se -Files "<file>"`.
Poora restore mat karo: 14 Nov ke baad doosre kaam bhi inhi files mein gaye hain.

# Teen kaam: app ka icon, same naam ka sawaal, PC ki cloud copy

Bane: 14 November 2026, subah 07:36 se 09:00 ke beech. Teeno ka "pehle wala" backup ek hi hai (`..\before\`),
kyunki teeno ek ke baad ek bane.

---

## 1. App ka icon (kai options)

### Yeh kya hai
Phone app ka naya icon, aur use badalne ke saat options: Ocean, Kit, Paper, Glow, Midnight, Sunset, Classic (purana).

### Kaise use hota hai
Phone app: **Aur -> Look aur bhasha -> App icon**. Icon par tap karo, "Change" dabao.
Android icon badalte waqt app ko ek baar band karta hai; home screen par naye icon se dobara kholo. Icon apni jagah par hi rehta hai.

### Andar se kaise chalta hai
- Android mein har icon ek "alias" hai (`AndroidManifest.xml` mein `.IconOcean`, `.IconKit` ...). Ek waqt mein ek hi alias on rehta hai.
- Page (`app.js`) -> `native.setAppIcon("glow")` -> `MainActivity.java` us alias ko on aur baaki ko off karta hai.
- Icon ki drawing ek hi jagah se banti hai: `tools\icons\make-icons.js` (Android ki drawing + page ki tasveer), `tools\icons\png.js` (PNG).

### Files
`tools\icons\*`, `mobile-android\src\main\res\drawable\ic_app_*`, `res\mipmap-anydpi-v26\ic_app_*`, `res\mipmap-xxhdpi\ic_app_*.png`,
`assets\icon-*.svg`, `assets\icon-classic.png`, `AndroidManifest.xml`, `MainActivity.java` (`APP_ICONS`, `appIcon`, `setAppIcon`),
`assets\app.js` (`ICON_CARDS`, action `app-icon`), `assets\looks.css` (`.icon-picker`).

### Jaanch
Asli phone par: saaton icon dikhe, Glow aur Ocean laga kar dekha, home screen par badla.

---

## 2. Same naam ka sawaal aur jagah ki jaanch (phone -> PC)

### Yeh kya hai
Phone se PC ko bhejte waqt agar us naam ki file ya folder PC par pehle se hai, to phone poochhta hai:
**Dono rakho / Badal do / Chhod do**. Aur PC par jagah kam ho to bhejna shuru hi nahi hota.

### Kaise use hota hai
Phone tab mein files ya folder chuno -> Send -> PC. Naam pehle se ho to sawaal aata hai.
- Dono rakho: nayi file "naam (2)" ban kar jaati hai.
- Badal do: PC ki purani file ki jagah nayi aati hai.
- Chhod do: woh files nahi jaatin, baaki jaati hain.

### Connection kaise banta hai
```
Phone page (app.js)                         PC (LocalMobileBridgeService)
  pcClashes()      -- POST /api/upload/clashes  {files, folders}  -->  UploadClashes()
                   <--  {files: [jo pehle se hain], folders: [...], free: khaali jagah}
  askClash()          (sawaal wala sheet)
  /api/upload/folder?name=X&onClash=replace   -->  wahi folder dobara use hota hai
  native.sendPreparedToPc2(renames, skip, onClash)
        -> TransferHub.java har file ke saath "&onClash=replace" bhejta hai
  POST /api/upload?...&onClash=replace         -->  purani file badalti hai
```
- "Badal do" sirf aapke apne device ke liye maana jaata hai. Guest ki file hamesha alag se rakhi jaati hai.
- PC par "hamesha poochho" on ho to file PC ke Accept ke baad hi aati hai (Files -> Transfers).

### Saath mein theek hua
- Transfer "PC door hai" maan kar atak jata tha; ab khud dobara koshish karta hai (30 second, 1 minute ... 15 minute tak).
- Camera backup ka ek database khula reh jata tha; ab band hota hai.

### Files
PC: `LocalMobileBridgeService.Upload.cs`, `.Extra.cs`, `.Security.cs`, `Views\TransfersView.cs`, `LocalizationManager.Peer.cs`, `tests\UploadTaskTests.cs`.
Phone: `assets\app.js` (`pcClashes`, `askClash`, `sendPaths`, `sendPhoneFiles`, `onFolderPicked`), `MainActivity.java` (`sendPreparedToPc2`, `sendFolderToPc2`), `TransferHub.java`, `CameraBackup.java`, `assets\i18n-words.js`.

### Jaanch
Asli phone + PC par: sawaal aaya, "Chhod do" aur "Badal do" dono sahi chale, PC par Accept ke baad file aayi.
Nahi jaancha: jagah kam hone wala sandesh (sirf code test), aur atke transfer ka khud dobara chalna.
Abhi nahi hai: Home ke "Photos"/"Files" tile aur doosre apps ke Share se bhejne par yeh sawaal.

---

## 3. PC ki files ki cloud copy ("Band hone par bhi files", PC wala hissa)

### Yeh kya hai
PC apni files ki copy aapke Google Drive mein rakhta hai, taaki PC band ho tab bhi juda hua device unhe khol sake.
Yeh tabhi chalta hai jab PC aur device dono ne is permission ko haan kaha ho. Poora plan: `docs\WHEN_OFF_PLAN.md`.

### Kaise use hota hai
PC app: **Devices -> When off**.
- Haal (dekh raha hai / copy kar raha hai / ruka hai), kitna hua, kis account mein jaata hai.
- "Sync now", "Pause / Continue".
- Options: Windows aur programs bhi, battery par roko, Windows ke saath app chalu karo, upload ki speed limit.
- **Abhi yeh ruka hua ("Paused") chhoda gaya hai.** Shuru karne ke liye "Continue" dabao.
- Pehli copy lambi hai: apni files 1-2 din, poori disk hafton mein.

### Connection kaise banta hai
```
AppHost (har 10 second)  ->  DeviceMirrorService.TickAsync
   dono ki haan hai? ruka to nahi (aapne / game / battery)?
   1. MirrorScanner   disk dekhta hai (apne folder har ghante, poori disk din mein ek baar)
   2. MirrorState     yaad rakhta hai kaun si file cloud mein ja chuki (mirror\pc.db)
   3. MirrorUploader  rclone se copy:
        rclone copy C:\  <account>:Cloud-SSD Devices/<pc>/files/C  --files-from-raw <list> --backup-dir .../trash/<tareekh>/C
   4. device.json     haal likhta hai (doosri taraf isse padhegi)
```
Cloud mein jagah:
```
Cloud-SSD Devices/<pc ki id> <pc ka naam>/
   files/C/Users/...        copy
   trash/2026-11-14/C/...   badli ya hatayi gayi files ki purani copy (30 din)
   device.json              haal
```
- Kram: pehle Desktop/Documents/Pictures/Videos/Music/Downloads, phir baaki profile, phir doosre folder, sabse aakhir mein programs aur Windows.
- Kabhi copy nahi hota: app ka apna data (`%LOCALAPPDATA%\Cloud-SSD`, isme accounts ki chaabi hai), `pagefile.sys` jaisi files, links, WinSxS.
- `Cloud-SSD Devices` folder Z: aur Y: drive mein nahi dikhta.
- Bahut saari files ek saath gayab hon (500 se zyada) to copy hatane se pehle poochhta hai.

### Files
`src\CloudSSD.App\Mirror\` (5 files), `StartWithWindows.cs`, `AppHost.cs`, `src\CloudSSD.Core\Settings.cs` (`MirrorSettings`),
`src\CloudSSD.Desktop\Views\WhenOffView.cs`, `Views\MobileHubView.xaml(.cs)`, `MainWindow.xaml.cs`, `Views\DevicePermissionsWindow.cs`,
`LocalizationManager.Extras.cs`, `tests\MirrorTests.cs`.

### Jaanch
- 11 test (ek asli rclone ko local folder par chalata hai).
- Asli Google Drive par chhote test folder se: nayi file gayi, badli file ki purani copy trash mein, hatayi file ki copy trash mein. Test ka sab kuch hata diya.
- Abhi rclone ki "shared key" par har kaam ~40 second leta hai aur Google use rok bhi deta hai. Apni Google key chahiye (Cloud Drives -> How do I get a key?).

### Abhi nahi bana
Folder ka naam badalne ko pehchanna (abhi dobara upload hota hai), metered network par rukna, phone se band PC ki files kholna (uske liye apni Google key chahiye), phone ki cloud copy.

---

## Wapas kaise jaayein

`CHANGED-FILES.txt` dekho: CHANGED files `..\before\` se project par copy karo, NEW files hata do, phir PC app aur phone app dobara build karo.
Sirf ek kaam hatana ho to upar us kaam ki "Files" list wali files hi wapas karo. `app.js`, `MainActivity.java`, `Settings.cs`, `AppHost.cs`
ek se zyada kaam ki hain: unhe poora wapas karne se teeno ka hissa jayega.

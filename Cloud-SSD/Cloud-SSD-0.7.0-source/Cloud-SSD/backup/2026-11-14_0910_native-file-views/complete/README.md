# Files asli jaisi dikhen (phone ↔ PC)

Bana: 14 November 2026. Asli PC aur phone par chala kar dekha: haan (phone aur PC dono par).

## Yeh kya hai

Ek device doosre ki files waise hi dikhaye jaise woh device khud dikhata hai, apna alag dhaancha nahi:

- **Phone par PC kholo** (Cloud SSD tab → PC) to sabse pehle Windows File Explorer jaisa **Home** khulta hai:
  upar **Quick access** (PC par jo folder pin hain: Desktop, Downloads, Documents, Pictures, Music, Videos, aur jo aap pin karo),
  phir **Ye PC**: PC ki disk (jaise "ACER (C:)") aur Cloud SSD ki drives ("All Accounts (Z:)", "Each Account (Y:)") khaali jagah ke saath.
- **PC par phone storage kholo** (Files → Phone storage) to phone ke Phone tab jaisa dikhta hai:
  **Internal storage** (poora storage, seedha uske folder) aur phone wali **Categories**: Downloads, Images, Videos, Audio,
  Documents, APK aur archives, har ek ke saath "kitni · kitna MB".
- **PC par Cloud SSD** (Files → Cloud SSD): kinds ke naam phone jaise ("Apps and archives" ek saath).

## Kya kaam hua

1. **PC ka Quick access phone tak**: PC ek naya raasta deta hai `/api/pc/home`. Woh Windows se Quick access ke pin kiye folder
   (usi kram mein) padhta hai. Sirf wahi folder bhejta hai jo phone dekh sakta hai; baaki ki ginti `hidden` mein.
2. **Phone par PC ka Home**: PC kholte hi Home. Drives ki patti mein sabse pehle "Home". Kisi drive ke upar se "Up" dabao to
   wapas Home; Home se Back dabao to devices ki list.
3. **PC par phone jaisa phone storage**: "Internal storage" aur "Categories" phone ke naam aur kram mein.
   Phone poora storage dikhane deta hai to PC seedha uske saare folder kholta hai (DCIM, Download, Android, WhatsApp…).
4. **"Poora phone dikhao" button**: phone ne sirf 6 folder (photos, downloads, documents, music) ki ijaazat di ho to PC par
   yeh button aata hai. Dabane par phone par sawaal aata hai; wahan Allow dabao, PC apne aap poora storage dikhane lagta hai.
5. **Ginti phone jaisi**: phone apni categories Android ke media index se ginta hai (WhatsApp jaise `Android/media` ke folder bhi). PC ko jawab dene wala hissa (PeerLink) ab wahi index padhta hai, isliye PC par bhi wahi ginti aati hai. Size bhi phone jaisa likha jaata hai ("340 MB", MiB nahi), aur Downloads = Download folder ki files.
6. **Naya default**: PC jab pehli baar phone ki files maangta hai, to phone ke sawaal mein ab "Whole phone storage" pehle aur
   chuna hua aata hai (pehle sirf 6 folder wala chuna hota tha).

## Kaise use hota hai

- **Phone**: Cloud SSD tab → apne PC par tap → Home. Kisi pin kiye folder ya drive par tap karo. Upar "Home" pill se wapas.
- **PC**: Files → Phone storage. Bayein "Internal storage" ya koi category. 6 folder hi dikhen to "Show the whole phone"
  dabao aur phone par Allow karo.
- PC ke Desktop/Documents jaise folder phone par tabhi khulte hain jab PC par "PC disks" chalu ho
  (Devices → Permissions). Is PC par yeh chalu hai.

## Connection kaise banta hai

```
Phone (Cloud SSD tab)                         PC (Cloud-SSD app)
  PC par tap  ── GET /api/pc/home ─────────►  Windows Shell: Quick access (pin kiye folder)
              ◄─ {pinned:[Desktop…], hidden}   + sirf wahi jo phone dekh sakta hai
              ── GET /api/drives ──────────►  C:, Z:, Y: aur khaali jagah
  folder par tap ── /api/fs/list ... (pehle jaisa)

PC (Files → Phone storage)                    Phone (Cloud-SSD app, PeerLink)
  kholte hi   ── fs.roots ─────────────────►  ijaazat: "all" ya "shared"
              ── fs.list path="" ──────────►  (all ho to) Internal storage ke folder
              ── fs.cats ──────────────────►  categories ki ginti aur size
  "Show the whole phone" ── fs.askAll ─────►  phone par sawaal (notification / page)
                                              Allow → ijaazat "all" → PC dobara kholta hai
```

## Files

| File | Kaam |
|---|---|
| `src\CloudSSD.App\LocalMobileBridgeService.QuickAccess.cs` (nayi) | Quick access padhna, `/api/pc/home` |
| `src\CloudSSD.App\LocalMobileBridgeService.Extra.cs` | naye raaste ka case |
| `src\CloudSSD.App\LocalMobileBridgeService.Security.cs` | naye raaste ki permission (Browsing) aur feature "pc-home" |
| `src\CloudSSD.Desktop\Views\PhoneFilesView.cs` | PC par phone storage phone jaisa; "Show the whole phone" |
| `src\CloudSSD.Desktop\Views\SsdFilesView.cs` | "Apps and archives" ek saath |
| `src\CloudSSD.Desktop\LocalizationManager.Native.cs` (nayi), `LocalizationManager.Devices.cs` | PC ke Hinglish/Hindi shabd |
| `mobile-android\src\main\assets\app.js` | phone par PC ka Home, Home pill, Up/Back |
| `mobile-android\src\main\assets\looks.css`, `newlooks.css`, `glass.css` | Home ke tiles aur drive rows har look mein |
| `mobile-android\src\main\assets\index.html` | ijaazat wale sawaal mein "Whole phone storage" pehle |
| `mobile-android\src\main\assets\i18n-words.js` | phone ke naye shabd |
| `mobile-android\src\main\java\com\cloudssd\mobile\PeerLink.java` | `fs.askAll`, default ijaazat "all", ginti Android ke media index se |
| `mobile-android\src\main\java\com\cloudssd\mobile\MainActivity.java`, `Tr.java` | sawaal page tak; notification ka text |
| `tests\CloudSSD.Tests\QuickAccessTests.cs` (nayi) | tests |

(`src\CloudSSD.Desktop\wwwroot\mobile\*` phone ke page ki copy hai, upar wali assets jaisi hi. Kuch files, jaise `app.js`, mein doosri window ke kaam ke badlav bhi hain; `complete\files\` mein unka aaj ka poora roop hai.)

## Jaanch

- Build: PC 0 warning, 0 error. Tests: 462 C# (2 naye: `QuickAccessTests`), 44 JS. Phone ka APK bina naye warning ke bana.
- Is PC par Windows ka asli Quick access padha: Desktop, Downloads, Documents, Pictures, Music, Videos (usi kram mein).
- **Phone (asli)**: Cloud SSD → PC: Home khula. Quick access mein 6 pin folder + "From phone"; This PC mein "ACER (C:)" 110 GB khaali, "Each Account (Y:)", "All Accounts (Z:)". Desktop par tap → "Home › C: › Users › … › Desktop" ki files. Home pill se wapas. Z: khol kar Up → wapas Home.
- **PC (asli)**: Files → Phone storage: pehle 6 folder aur "Show the whole phone" button. Button dabaya → phone par sawaal aaya, "Whole phone storage" pehle se chuna. Phone par Allow (aapne khud dabaya) → PC par poora storage (Alarms, Android, DCIM, Download, …).
- Ginti dono taraf ek jaisi: Downloads 17 · 120 MB, Images 817 · 340 MB, Videos 12 · 43.3 MB, Audio None, Documents 130 · 227 MB, APK aur archives 20 · 273 MB. "APK and archives" kholne par Download aur WhatsApp wali files dono aayin.
- Har look (Ocean, Kit, Paper, Glow) mein PC Home ka design preview mein dekha.

## Wapas kaise jaayein

- Sirf yeh kaam hatana ho: `complete\CHANGED-FILES.txt` dekho. "CHANGED" files `before\` se project par copy karo,
  "NEW" files hata do. Phir PC app aur phone app dobara build karo.
- Phone par purana dhaancha chahiye ho bina code badle: kuch nahi karna padta, PC purana ho (bina "pc-home") to phone pehle
  jaisa pehli drive kholta hai.

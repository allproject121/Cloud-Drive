# Folder khulte hi uski files taiyaar ("kholne mein der" ka ilaaj)

- **Agent:** Claude Code (Claude Fable 5.2) · **Task:** TASK-CLAUDE-WARMUP
- **Kab:** 17 Nov 2026, 14:05 → 14:35 · **Validation:** APPROVED (build 0 warning / 0 error, C# 634/634)
- **User ka kehna:** "abhi bhi time le raha hai kam se kam 4-5 second or usse jada bhi oska kuch karo"

## Yeh kya hai

Cloud drive par koi file **pehli baar** kholne mein 2 se 15 second lagte the; doosri baar 5 millisecond.
Ab jaise hi aap File Explorer mein koi cloud folder kholte ho, app uski files peeche se laptop ki cache mein le aata hai.
Kuch second baad us folder ki koi bhi file click karo to turant khulti hai.

## Der kahan thi (naapa hua)

| Cheez | Samay |
|---|---|
| Drive letter / folder kholna | turant (folder pehli baar ~0.7 s) |
| File pehli baar kholna, 0.4-0.9 MB | 1.7 s |
| File pehli baar kholna, 5-14 MB | 3-15 s |
| Wahi file doosri baar | 0.005 s |

Der "open" mein hi lagti thi: file khulte hi Windows ka antivirus (Defender) uska shuru ka hissa padhta hai, aur Google ko pehla
byte dene mein 1.5 s lagte hain (internet line us waqt 9.9 MB/s thi, uski galti nahi). Zip aur exe ko scanner poora padhta hai.

## Ab (asli app, asli drive)

Explorer mein folder khola (Fast drive W: ke raaste) → app ne 19 files / 6.8 MiB 14.5 s mein taiyaar ki → wahi files **0.026 s** mein khuli.
Doosra folder (13 files, 0.1-6.4 MB): sab **0.02-0.22 s** mein khuli, 1 s se upar ek bhi nahi.

## Andar se kaise chalta hai

```
File Explorer mein khula folder
        |  (har 1.5 s Windows se poocha jata hai: ExplorerFolderWatcher)
        v
AppHost.CloudPlaceOf  --  cloud drive ka raasta?  ya Fast drive ke link ke raaste?
        |
        v
ArchiveWarmer:  us folder ki files, sabse chhoti pehle, 6 ek saath
   chhoti file (4 MiB tak)  -> poori
   badi file                -> shuru ka 512 KiB + aakhri 128 KiB
   zip / 7z / rar           -> pehle jaisa (file list + shuru)
   andar ke folder (40 tak) -> pehle se list
        |
        v
rclone ki cache (laptop)  ->  click par Google ka intezaar nahi
```

Seema: ek folder ke liye 60 files aur 128 MiB tak. Game chal raha ho, disk bhar rahi ho ya Google "ruko" kahe to yeh ruk jata hai.

## Files

| File | Kya |
|---|---|
| `src/CloudSSD.App/ArchiveWarmer.cs` | sirf archive nahi, har file; 6 ek saath; andar ke folder list; log mein bina naam ki ek line |
| `src/CloudSSD.App/ExplorerFolderWatcher.cs` (nayi) | File Explorer ke khule folder (rclone ke log par nirbhar nahi) |
| `src/CloudSSD.App/AppHost.cs` | `ExplorerFolders`, `CloudPlaceOf`, Fast drive ke link ka raasta |
| `src/CloudSSD.App/Hybrid/HybridDriveService.cs` | sudhaar: app dobara chalu ho to apna purana letter hi le (pehle har baar naya letter leta tha) |
| `src/CloudSSD.Core/Settings.cs` | `RootOrDefault` settings.json mein na likha jaye |
| `tests/CloudSSD.Tests/ArchiveWarmerTests.cs` | 3 naye test, 1 badla |

## Jaanch

- `backup.ps1 validate` → APPROVED, 634/634.
- Asli jaanch: `.work\speed\warm-live-test.ps1 -Cloud G -Fast W` (do alag folder), `first-open.ps1`, `who-reads.ps1`, `open-times.ps1`.
- **Nahi jaancha / seema (sach):**
  - Folder kholte hi **turant** (taiyaari se pehle) click karo to pehli file ab bhi 2-3 s le sakti hai.
  - 4 MiB se badi file ka sirf shuru aur ant taiyaar hota hai; beech ka hissa padhte waqt aata hai (bada video aage badhane par, badi zip nikalne par).
  - Sirf File Explorer ki window dekhi jati hai. Kisi program ke "Open file" box se khula folder, ya cmd se, is raaste se nahi pakda jata
    (G: ke liye log wala raasta restart tak band hai: purana atka rclone log ko rotate nahi hone deta).
  - Defender ko chheda nahi gaya (scan chalu hai). Data aur cache ki jagah zyada lagti hai (cache ki seema 30 GiB hai, purana khud hatta hai).
  - PC restart ke baad dobara nahi jaancha.

## Wapas kaise jayein

Is folder ke `before\` se upar ki files wapas copy karo (`ExplorerFolderWatcher.cs` hata do), build + test. `git reset --hard` kabhi nahi.

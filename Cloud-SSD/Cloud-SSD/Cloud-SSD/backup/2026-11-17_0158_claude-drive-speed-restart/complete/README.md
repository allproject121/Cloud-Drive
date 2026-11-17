# Drive restart par bani rahe + zip / install ki speed (17 Nov 2026)

- **Agent:** Claude Code (Claude Fable 5.2) · **TaskId:** TASK-CLAUDE-SPEED
- **Jaanch:** build 0 error / 0 warning, C# tests 518/518 (`VALIDATION.txt` = APPROVED), naya build asli PC par laga kar naapa
- **User ne kaha:** "laptop restart / power off ke baad drive wapas load hoti hai, ek baar login + account connect ke baad
  permanent rehna chahiye; zip slow khulta hai, fix ke baad bhi apne aap phir slow; app install 5-10 guna slow"

## Yeh kya hai

Teen shikayaton ki ek hi jad nikli: **Google ki "shared key"**. Cloud-SSD abhi rclone ki sabke-saath-baanti hui Google key
se chalta hai (`project_number:202264815644`). Us key ki limit poori duniya ke rclone users milkar bhar dete hain, isliye
Google hamare lagbhag aadhe request "403 quota exceeded" bol kar lauta deta hai. Har 403 ke baad rclone 1, 2, 4, 8, 16 second
rukta hai. Yeh key 2026 me band bhi hone wali hai (rclone khud log me likhta hai).

App ke andar teen cheezein is takleef ko aur badha rahi thi. Woh teeno theek ki gayi hain.

## Kya naapa (asli Z: drive, internet 9.25 MB/s)

| Kaam | Pehle | Ab (naya build) |
|---|---|---|
| 54 MB file shuru se aakhir tak (pehli baar) | 259 s, 37 request, 32 baar 403 | 110 s, **4 request**, 13 baar 403 |
| Wahi file dobara (cache se) | 0.14 s | 0.14 s |
| 440 MB zip ki list (pehli baar) | — | 3.8 s, 4 request, 0.43 MB utra |
| Wahi zip dobara | — | 0.13 s |
| Restart ke baad drive | 47 s (01:33 par) | 10 s Z:, 16 s Y: (us waqt 403 nahi aaya) |

Data jab aata hai to poori speed se aata hai (7-9 MB/s). Bacha hua saara intezaar 403 ka hai.

**Z: par likhna (app install):** 60 chhoti files + 13 folder = 280 s, 105 baar 403. Har naya folder = 2 s (Google me folder
banana) + 20-60 s (naye folder ki pehli list, 403 ke intezaar ke saath). Wahi folder hatane me 453 s lage. Yeh code se theek
nahi hota; apni Google key se 403 wala hissa chala jata hai.

## Kya kaam hua

1. **Drive kabhi haar nahi maanti** (`MountService.cs`): pehle 10 minute me 5 baar fail hone par app likh deta tha
   "Automatic restart disabled … Remount manually" aur drive tab tak gayab rehti thi jab tak user khud na jode. Ab pehle
   5 koshish jaldi (2, 4, 8, 16, 32 s), uske baad har 2 minute par, hamesha. (Purane 0.7.0 zip me bhi yahi "5 ke baad band"
   tha aur Windows ke saath chalu hone ka code tha hi nahi: problem shuru se thi.)
2. **Badi file kam request me** (`MountPlanning.cs`): `--vfs-read-chunk-size-limit` `4Mi` se `off`. Pehle har 4 MB par ek
   naya request jata tha (500 MB installer = 125 request, har ek par 403 ka khatra). Ab tukda badhta jata hai
   (4, 8, 16, 32 MB …): 54 MB = 4 request, 500 MB = 7 request.
3. **"Zip pehle se taiyar" user ke raaste se hata** (`ArchiveWarmer.cs`, `AppHost.cs`): folder kholte hi app us folder ki har
   zip ka shuru + aakhir mangwata tha (20 zip = 40 request). Wahi request user ki file se aage line me lag jate the
   (naapa: file khulne me hi 85 s). Ab Google ne pichhle 2 minute me 403 bola ho to yeh kaam ruka rehta hai.

## Andar se kaise chalta hai

```
file kholo -> rclone -> Google Drive
                 |  403? -> 1,2,4,8,16 s ruko -> phir koshish     (yahi asli deri hai)
                 |  200  -> data 7-9 MB/s -> cache (C: par) -> dobara turant

drive gir gayi -> 2s,4s,8s,16s,32s -> phir har 2 min -> ... (rukta nahi)
folder khula   -> pichhle 2 min me 403?  haan: kuch mat mangwao | nahi: zip ke sire pehle se le aao
```

## Files

- `src/CloudSSD.Mount/MountService.cs` — `NextRestartDelay`, `SlowRestartDelay`, `RateLimitedWithin`, `LastRateLimit`
- `src/CloudSSD.Mount/MountPlanning.cs` — chunk limit `off`
- `src/CloudSSD.App/ArchiveWarmer.cs` — `QuietAfterRateLimit` (2 min)
- `src/CloudSSD.App/AppHost.cs` — warmer ka "ruko" niyam
- `tests/CloudSSD.Tests/CoreTests.cs` — chunk limit ka test badla, restart-delay ka naya test (5 cases)
- Naapne ke script: `.work\speed\read-test.ps1`, `zip-list-test.ps1`, `write-test.ps1`

## Kya nahi jaancha

- Asli restart / power off karke nahi dekha (PC band nahi kiya). App band + drives alag + naya build + app chalu kiya: drives
  10 s / 16 s me aayi. "Kabhi haar nahi maanti" ka sirf unit test hai, internet band karke asli jaanch nahi hui.
- Warmer ka rukna asli drive par alag se nahi dikhaya (403 apni marzi se nahi laya ja sakta); code + build + tests hi hain.
- Speed ke number 403 ki wajah se har baar alag aate hain. Request ki ginti (37 -> 4) pakki hai, second nahi.

## User ke haath me (sabse bada fayda)

**Apni Google key**: PC app -> Cloud Drives -> "How do I get a key?" -> "Switch to my own Google key". Usse 403 khatam,
aur 2026 me shared key band hone par login bhi nahi tootega.

## Wapas kaise jaayein

`powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 restore -Folder "2026-11-17_0158_claude-drive-speed-restart"`
(sirf upar ki 5 files `before\` se wapas aati hain), phir build + install.

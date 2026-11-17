# Speed check + Speed Lock ("baad mein phir dheema na ho jaye")

- **Agent:** Claude Code (Claude Fable 5.2) · **Task:** TASK-CLAUDE-SPEEDLOCK
- **Kab:** 17 Nov 2026, 14:35 → 14:50 · **Validation:** APPROVED (build 0 warning / 0 error, C# 640/640)
- **User ka kehna:** "abhi kayse pata ke open ho raha hai isko lock ya kuch kar sakte hai baad me aapa leat open hona susru kar dega ye"

## Yeh kya hai

Drive tez isliye hui ki teen cheezein lagi hain: apni Google key, Fast drive, aur khule folder ki files pehle se taiyaar rakhna.
Inme se koi bhi chupchaap hat sakti hai (login wapas shared key par, setting band, letter gaya, kisi agent ne flag badla) aur user ko
bas "phir dheema ho gaya" dikhta. Ab app **khud naapta hai** aur bata deta hai.

## Kaise use hota hai

- PC app → **Cloud Drives** → card **"Speed check"** → **"Check the speed now"**. Har line ✔ (theek), ! (chalta hai par dhyan do) ya ✖ (dheema).
- App khud bhi jaanchta hai: chalu hone ke ~90 second baad, phir **har 3 ghante**. Jo cheez pehle theek thi aur ab ✖ hai, uska
  **note kone mein + ghanti mein** aata hai (ek hi baat baar-baar nahi).
- Aakhri nateeja file mein bhi: `%LOCALAPPDATA%\Cloud-SSD\speed-check.json`; log mein "Speed check: OK" ya "Speed check: N problem(s)".

## Kya jaanchta hai

| Line | Kaise | ✖ kab |
|---|---|---|
| Google key | accounts shared key par to nahi | koi account shared key par |
| Cloud drive | judi hai ya nahi | nahi judi |
| Fast drive | asli naap: 200 files, 20 folder likh kar turant hatana | 5 s se zyada, ya letter nahi (band ho to "!") |
| Opening files | asli naap: cache mein poori maujood ek file kholna + 64 KB | 1 s se zyada |
| Preparing folders | chalu / ruka, aakhri folder kab taiyaar hua | (ruka ho to "!") |
| Google / Dead drive name / Drive log / Drive letter | mana kiya?, mara hua letter, atka log, Z: ki jagah doosra letter | sirf "!" |

Kuch badalta nahi; sirf apna test folder (`.cloudssd-speed-check`) banata aur hatata hai. Fast drive is naam ko kabhi link / upload nahi karta.

## "Lock" ka matlab (sach)

Koi tala speed ko bandh kar nahi rakh sakta (internet, Google, Windows badal sakte hain). Lock teen cheezon se bana hai:
1. **App ki apni nigrani** (upar): bigadte hi pata chalta hai, aur kya karna hai woh line mein likha hota hai.
2. **Agents ke liye niyam:** `RULE.md` ka naya hissa **"10. Speed Lock"** — kaun si cheezein speed deti hain, naape hue number, aur "jo badlaav inhe kharab kare woh ship nahi hoga".
3. **Tests:** Fast drive, warm-up aur speed check ke test (640 mein) — code badle to pakda jaye.

## Asli jaanch (17 Nov 14:42, naya build installed)

```
ok    Google key         All 3 Google account(s) use your own Google key.
ok    Cloud drive        The cloud drive is connected (G:).
ok    Fast drive         New files on the fast drive (W:): 200 files in 20 folders written in 0.1 s.
warn  Drive letter       Z: is held by something else until Windows restarts, so the fast drive is W: for now.
ok    Opening files      Opening a file that is ready on this PC: 0.05 s.
ok    Preparing folders  The files of folders you open are fetched ahead (last: 14:42, 1 file(s), 1.2 MiB).
warn  Dead drive name    Z: is the name of a drive that did not close cleanly. It goes away when Windows restarts.
warn  Drive log          The activity log of G: stopped (an older drive process holds it). …
```

## Files

`src/CloudSSD.App/SpeedGuard.cs` (nayi), `AppHost.cs` (`Speed`), `ArchiveWarmer.cs` (`LastReady`, `IsPaused`), `Hybrid/HybridLayout.cs` (test folder ko andekha),
`src/CloudSSD.Desktop/ViewModels/CloudDrivesViewModel.cs` + `Views/CloudDrivesView.xaml` (card + note), `tests/CloudSSD.Tests/SpeedGuardTests.cs` (6 test), `RULE.md` (dono copy).

## Nahi jaancha / seema

- Note / ghanti wala raasta (koi cheez sach mein bigde tab) asli app mein nahi dikha, kyunki kuch bigda nahi; sirf code + test.
- 3 ghante wala apne aap chalna abhi dekha nahi (button se chalaya; start ke 90 s baad wala chalega).
- "Opening files" sirf woh file naapta hai jo pehle se laptop par hai; bilkul nayi file ka pehla open (2-3 s) isme nahi aata.
- Card angrezi mein hai (user ka app abhi English par set hai).

## Wapas kaise jayein

Is folder ke `before\` se files wapas copy karo (`SpeedGuard.cs`, `SpeedGuardTests.cs` hata do; `RULE.md` ka hissa 10 hatao), build + test.

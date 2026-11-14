# Backup folder: yeh kaise kaam karta hai

Is folder mein har naye kaam ka backup rehta hai. Yeh project ke andar hai, isliye GitHub par bhi jaata hai.

## Har kaam ka ek folder

```
backup\
  2026-11-14_0906_winfsp-apne-aap-install\     <- tareekh_samay_kaam-ka-naam
    BEFORE.txt      kab liya, kitni files
    before\         kaam shuru hone se PEHLE ka poora source. Ise kabhi nahi chheda jaata.
    complete\       kaam poora hone par banta hai:
      README.md           yeh kya hai, kya kaam hua, kaise use hota hai, connection kaise banta hai, wapas kaise jaayein
      CHANGED-FILES.txt   kaun si files nayi bani, kaun si badli
      files\              nayi aur badli hui files ka poora-bana version (project jaisa hi raasta)
```

## Niyam

1. **Kaam shuru karne se pehle** backup lo: `tools\backup\backup.ps1 start -Name "kaam-ka-naam"`
2. **Jab tak kaam poora nahi hota**, us backup ko mat chhedo. `before\` kabhi nahi badalta.
3. **Kaam poora aur test hone par**: `tools\backup\backup.ps1 complete -Folder "<folder ka naam>"`, phir `complete\README.md` likho.
4. Kaun sa backup kis haal mein hai: `tools\backup\backup.ps1 list`

## Purane jaisa wapas kaise banayein

- Ek kaam hatana ho: us kaam ke `complete\CHANGED-FILES.txt` mein dekho. "CHANGED" files ko `before\` se project par copy karo, aur "NEW" files project se hata do.
- Poora project us din jaisa chahiye: `before\` ka sab kuch project par copy karo.
- Uske baad PC app aur phone app dobara build karo (neeche "Build").

## Backup mein kya nahi hota

Sirf source (code, pages, chhoti tasveerein) rehta hai, taaki backup chhota rahe (lagbhag 12 MB). Yeh cheezein nahi hotin:
build se bani files (`bin`, `obj`, `dist`, `build`), `rclone.exe`, WinFsp ka installer, APK, zip, aur 2 MB se badi files.
Ye sab GitHub ke purane commit se ya dobara build karke mil jaati hain.

## Build

- PC app: `dotnet build CloudSSD.slnx`, tests: `dotnet test tests\CloudSSD.Tests`
- Phone app: `mobile-android\build-apk.ps1 -Debug -OutDir <folder>`
- PC ka install folder: `installer\build-release.ps1`, phir us folder mein `Install.cmd`

## 14 November 2026 se pehle ke backup

Us se pehle ke backup project ke bahar hain: `Downloads\Cloud-Drive\Cloud-SSD-backups\` (GitHub par nahi hain).

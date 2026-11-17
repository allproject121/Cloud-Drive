# Storage permanent rahe jab tak app laga hai (17 Nov 2026)

- **Agent:** Claude Code (Claude Fable 5.2) · **TaskId:** TASK-CLAUDE-PERMANENT
- **Jaanch:** build 0 error / 0 warning, C# tests 553/553 (`VALIDATION.txt` = APPROVED), asli PC par naya build laga kar dekha
- **User ne kaha:** "file aata hai mujhe wo permanent chahiye jab tak app hai tab tak mujhe storage mile"

## Yeh kya hai

Ek baar account jod diya to Z: aur Y: tab tak rahein jab tak aap khud app ke andar se disconnect na karo ya app uninstall
na karo. Do raaste the jinse drive / login bina aapke kahe ja sakta tha. Dono band kiye.

## Kya kaam hua

1. **Khidki band karne par drive rehti hai.** App band karte waqt sawaal aata hai "Keep the cloud drives mounted…?".
   Pehle usme pehle se chuna hua jawab **No** tha: Enter dabate hi Z: aur Y: chali jati thi. Ab pehle se chuna jawab
   **Yes** hai (`Settings.cs` ka default + is PC ki `settings.json` me `KeepMountsAfterExit = true`).
   Purani setting ki copy: `%LOCALAPPDATA%\Cloud-SSD\settings.json.before-keep-drives`.
2. **Accounts ki file kho jaye to app khud wapas laata hai.** Saare login ek file me hain (`rclone.conf`). Use 2-3 rclone
   process bina taale ke likhte hain. 13 Nov ko PC neend se uthte hi yeh file ek pal ke liye **khaali** mili thi
   (`rclone.conf.old4270454923`, 0 bytes). Us pal app chalu hota to saare account "disconnected" dikhte aur sab me dobara
   login karna padta. Ab app har baar accounts sahi padhne ke baad ek copy rakhta hai (`rclone.conf.good`, rclone se
   jaanch kar), aur file gayab / khaali / na-padhne-layak mile to wahi copy wapas rakh deta hai. Kharab file phenki nahi
   jati (`rclone.conf.lost-<samay>`). Aap khud account disconnect karo to copy bhi hata di jati hai, taaki account
   apne aap wapas na aaye.

## Andar se kaise chalta hai

```
app chalu / accounts ki list
   -> rclone.conf gayab ya khaali?  haan -> rclone.conf.good wapas rakho
   -> rclone padh nahi paya?        haan -> kharab wali ko .lost-<samay> banao, good wapas rakho, dobara padho
   -> sahi padha, 1+ account        -> copy banao, rclone se jaancho, tab rclone.conf.good banao

khidki ka X -> sawaal -> pehle se chuna "Yes" -> app band, rclone chalta rehta hai -> Z: Y: wahin
```

## Asli PC par jaanch (02:54 - 02:55)

- App band kiya, jawab Yes: Z: aur Y: judi rahi (wahi rclone process 11136, 22232), naya build 5 s me chalu, "Re-attached".
- `rclone.conf.good` 02:54:30 par bani (2798 bytes).
- **Jaan-boojh kar** `rclone.conf` ko 0 bytes kiya (02:55:05) aur app chalu kiya: 1.4 s me file wapas, wahi content
  (SHA256 same), log: "The accounts file was missing or empty; the last good copy was put back", drives judi rahi.

## Kya nahi jaancha

- Asli restart / power off nahi kiya.
- Na-padhne-layak (aadhi likhi) file wala raasta sirf unit test me hai, asli PC par nahi.
- File me kuch account kam ho jayein (poori khaali nahi) to yeh pakad me nahi aata: app nahi jaan sakta ki aapne hataya ya
  kho gaya.
- Sawaal me aap khud "No" dabao to drive hategi (yeh aapka faisla maana jata hai). Khidki band karne par app ko peeche
  chalte rakhna `App.xaml.cs` me hai, jise chhuna mana hai.

## Sabse bada khatra abhi bhi baaki

rclone ki **shared Google key 2026 me band** hogi. Tab saare login toot jayenge, chahe app kuch bhi kare. Ilaaj: apni Google
key (PC app -> Cloud Drives -> "How do I get a key?" -> "Switch to my own Google key").

## Files

- `src/CloudSSD.Core/Settings.cs` — `KeepMountsAfterExit = true`
- `src/CloudSSD.Mount/RcloneConfigService.cs` — `ConfigGuard`, `RestoreIfLost`, `RestoreUnreadable`, `RememberGoodAsync`, `ForgetGood`
- `src/CloudSSD.App/AppHost.cs` — `RefreshRemotesAsync` me upar ke call
- `tests/CloudSSD.Tests/ConfigGuardTests.cs` — 6 naye tests
- `.work\speed\app-close.ps1 -Answer Yes|No` — app band karke uske sawaal ka jawab dene ka script

## Wapas kaise jaayein

`powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 restore -Folder "2026-11-17_0247_claude-drive-permanent"`,
phir build + install. Purani setting: `settings.json.before-keep-drives` ko `settings.json` par copy karo (app band karke).

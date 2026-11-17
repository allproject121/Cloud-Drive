# Fast drive (Hybrid Z:) — naya likhna pehle laptop par, upload peeche

- **Agent:** Claude Code (Claude Fable 5.2) · **Task:** TASK-CLAUDE-HYBRID
- **Kab:** 17 Nov 2026, 12:03 → 13:57 · **Validation:** APPROVED (build 0 warning / 0 error, C# 631/631)
- **User ka kehna:** "file jayse speed xhahiye" → sawaal mein chuna "Haan, Hybrid Z: banao"

## Yeh kya hai

Cloud drive par install ya bahut saari files likhna dheema tha, kyunki har naya folder Google se poochna padta hai.
Fast drive mein drive ka letter (Z:) asal mein **laptop ka ek folder** hota hai. Naya kuch bhi seedha laptop ki disk par
likha jata hai (Files jaisi raftaar), aur app use peeche-peeche Google par chadha deta hai.

Naapa hua (wahi kaam: ek install hue app ki 853 files, 143 folder, 970 MB ek-ek karke likhna):

| Kahan | Samay |
|---|---|
| Laptop ki apni Files | 3 s |
| Cloud drive, rclone ki shared key (subah) | 42 min |
| Cloud drive, user ki apni Google key | 13 min |
| **Fast drive (asli app mein, 17 Nov 13:53)** | **5.1 s** |

## Kaise use hota hai

PC app → **Cloud Drives** → card **"Fast drive"** → **"Switch the fast drive on"** → Yes.
Wapas band: wahi button ("Switch the fast drive off"). Jab tak koi cheez sirf laptop par hai (upload nahi hui), band nahi hota.
"Open the fast drive" us drive ko File Explorer mein kholta hai.

Default mein **OFF** hai. Is PC par 17 Nov 13:51 se ON hai.

## Andar se kaise chalta hai

```
Z:\  =  C:\Users\<naam>\Cloud-SSD\All Accounts      (laptop ka folder; app letter ko is par lagata hai)
 |
 +-- Photos        -> link ->  X:\Photos       (cloud drive, jo apne letter X: par chali jati hai)
 +-- Documents     -> link ->  X:\Documents
 +-- Naya App         asli folder (laptop par)
                         |  20 s shaant rehne par
                         v
                   cloud drive ka apna rclone "sync/copy"  ->  Google (CloudSSD:Naya App)
```

Har 10 second ka ek pass (`HybridDriveService.TickAsync`):
1. **Letter:** Z: ko folder par lagao (`DosDevice`, "subst" jaisa). Z: kisi aur ke paas ho (17 Nov ko mara hua naam atka tha) to us
   session ke liye koi doosra khaali letter; agle start par phir Z: pehle.
2. **Link:** cloud drive ke upar wale har folder / file ka link (`HybridLayout.Reconcile`). Cloud drive ka letter badle to link ghoom jate hain.
3. **Upload:** laptop par bani cheez 20 s shaant rahe to ek-ek karke Google par copy; badle to dobara (sirf badli files jati hain).

**Kuch bhi delete nahi hota:**
- User tez drive mein kisi cloud folder ka link hataye → woh folder sirf **chhup** jata hai (`Hidden`), cloud se nahi hatta.
- Cloud drive door ho ya achanak "khaali" dikhe → koi link nahi hatta.
- Laptop ka asli folder kabhi nahi hatta. "Sirf cloud" banana (laptop se jagah khaali karna) **abhi bana nahi** (Phase 2).

## Files

| File | Kya |
|---|---|
| `src/CloudSSD.Core/Settings.cs` | `HybridDriveSettings` (Enabled, Letter Z, BackingLetter X, Root, MountId, QuietSeconds) + `AppSettings.Hybrid` |
| `src/CloudSSD.App/Hybrid/DosDevice.cs` (nayi) | letter ↔ folder, File Explorer ka naam "Cloud SSD" |
| `src/CloudSSD.App/Hybrid/HybridLayout.cs` (nayi) | link banana / hatana + `HybridState` (`hybrid-state.json`) |
| `src/CloudSSD.App/Hybrid/HybridDriveService.cs` (nayi) | pass, upload, on / off, cloud drive ko apne letter par le jana |
| `src/CloudSSD.App/AppHost.cs` | `Hybrid` property; start par letter pehle, phir drives, phir pass (sirf desktop app) |
| `src/CloudSSD.Desktop/ViewModels/CloudDrivesViewModel.cs`, `Views/CloudDrivesView.xaml` | "Fast drive" card |
| `tests/CloudSSD.Tests/HybridDriveTests.cs` (nayi) | 9 test |

## Jaanch

- `backup.ps1 validate` → build 0/0, C# **631/631** → APPROVED.
- **Asli PC, asli app (naya build installed, 13:50):** Fast drive on → log "11 link(s) made"; tez drive par 853 files **5.1 s**;
  55 files / 47 MB ka folder app ne khud upload kiya ("upload finished in 65 s"), cloud drive par 55/55; purana cloud folder link se 0.01 s mein khula;
  test folder dono jagah se hate, state saaf (11 link, 0 hidden). Script: `.work\speed\fast-live-test.ps1 -Fast W -Cloud G`.
- **Nahi jaancha (sach):** PC restart ke baad Z: par aana (aaj Z: ka naam Windows mein atka tha, isliye tez drive **W:** par chali; user abhi restart nahi kar sakta);
  asli MiniMax installer (uska raasta `Z:\MiniMax Code` hai); "Switch off"; cloud drive ko chalte hue X: par le jana (`MoveCloudDriveAsync`, aaj zarurat nahi padi);
  bahut bade folder (970 MB) ka upload; internet band hone par; doosre PC par jahan Developer Mode band ho (tab link nahi bante, card mein dikhega "could not be linked").
- **Pata hona chahiye:** tez drive laptop ki khaali jagah dikhati hai (116 GB), 15 TB nahi. Purane cloud folder ke ANDAR likhna ab bhi cloud ke raaste (dheema) hai.
  Phone wala bridge, Files page, games, offloader cloud drive ko seedha dekhte hain (jo sirf laptop par hai woh unhe upload ke baad dikhta hai).
  PC app ke naye text angrezi mein hain (Cloud Drives page ke baaki text bhi angrezi hain).
  Installed build mein ek chhota fark: `settings.json` mein `RootOrDefault` bhi likha jata hai (nuksaan nahi); source mein theek ho chuka, agle install se jayega.

## Wapas kaise jayein

- Sirf band karna: app → Cloud Drives → "Switch the fast drive off". Folder `C:\Users\<naam>\Cloud-SSD\All Accounts` aur usme bani cheezein waise hi rehti hain.
- Code wapas: is folder ke `before\` se upar ki table wali files copy karo (nayi 4 files hata do), phir build + test.
  Kabhi `git reset --hard` / `git checkout -- .` nahi.

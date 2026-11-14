# WinFsp apne aap install hona

Bana: 14 November 2026. Asli PC par chala kar dekha: haan.

## Yeh kya hai

Cloud drive ko Z: aur Y: ke roop mein dikhane ke liye Windows ko ek chhota driver chahiye, jiska naam **WinFsp** hai.
Pehle ise alag se install karna padta tha. Ab iska official installer Cloud-SSD ke saath hi aata hai, aur
WinFsp na mile to Cloud-SSD use khud laga deta hai.

(Apna khud ka driver banana socha tha, par nahi banaya: uske liye Microsoft ka sign chahiye, mahino ka kaam hai,
aur galti hone par PC crash ho sakta hai. WinFsp free hai aur uska installer baantna allowed hai.)

## Kya kaam hua

1. **Installer app ke saath**: release folder mein `tools\winfsp\winfsp-2.1.25156.msi` jaata hai. Build ke waqt uska sign jaancha jaata hai.
2. **App khud lagata hai**: WinFsp na ho to app poochhta hai "Install karein?". Yes par installer chalta hai (Windows ek baar permission poochhta hai), phir drives apne aap jud jaate hain.
3. **Sirf asli installer chalta hai**: chalane se pehle app uska sign jaanchta hai (Windows ki apni jaanch + banane wale ka naam "NAVIMATICS LLC"). Badla hua installer nahi chalta.
4. **"No" yaad rehta hai**: app shuru hone par dobara nahi poochhta. Drive connect karne par poochhta hai.
5. **Install script theek hua**: `Install-CloudSSD.ps1` folders ko galat jagah copy karta tha (`tools\tools`, `wwwroot\wwwroot`). Isse installer app tak nahi pahunchta tha, aur PC app ke andar ka phone wala page purana reh jata tha. Ab sahi copy hota hai aur purane galat folder hata diye jaate hain.
6. **Transfer history ki galti theek hui**: do transfer ek saath khatam hone par `transfer_history.json` likhne mein error aata tha.

## Kaise use hota hai

- **Naya PC**: Cloud-SSD ka folder kholo, `Install.cmd` chalao. WinFsp na ho to wahi laga deta hai (Windows ek baar poochhega).
- **App ke andar**: app kholo. WinFsp na ho to 4 second baad sawaal aata hai. Yes dabao, Windows ke sawaal par bhi Yes.
- **Drive connect karte waqt**: Cloud Drives page par drive jodne par bhi yahi sawaal aata hai agar WinFsp na ho.
- "No" ke baad dobara chahiye: Cloud Drives page par koi drive connect karo.

## Andar se kaise chalta hai

```
App shuru  ->  MainWindow (Loaded, 4 second baad)
           ->  WinFspOffer.AtStartAsync
                 WinFsp hai?  haan -> kuch nahi
                 nahi -> sawaal (Yes / No)
                    No  -> Settings.WinFspOfferDeclined = true
                    Yes -> WinFspSetup.InstallAsync
                             tools\winfsp\winfsp*.msi dhundho
                             sign jaancho (IsGenuine)
                             msiexec /i ... /passive   (Windows ka permission wala sawaal)
                         -> AppHost.RestoreMountsAsync  (Z: aur Y: judte hain)
```

## Files

| File | Kaam |
|---|---|
| `src\CloudSSD.App\WinFspSetup.cs` (nayi) | installer dhundhna, sign jaanchna, chalana |
| `src\CloudSSD.Desktop\WinFspOffer.cs` (nayi) | sawaal wala dialog aur uske jawab |
| `src\CloudSSD.App\AppHost.cs` | `RestoreMountsAsync`: drives dobara jodna |
| `src\CloudSSD.Desktop\MainWindow.xaml.cs` | app shuru hone par offer |
| `src\CloudSSD.Desktop\ViewModels\CloudDrivesViewModel.cs` | drive connect karne se pehle offer |
| `src\CloudSSD.Core\Settings.cs` | `WinFspOfferDeclined` |
| `src\CloudSSD.Desktop\LocalizationManager.Extras.cs` | Hinglish aur Hindi shabd |
| `installer\Install-CloudSSD.ps1` | WinFsp lagana; folder copy ki galti theek |
| `installer\build-release.ps1` | installer ko release folder mein rakhna |
| `src\CloudSSD.App\LocalMobileBridgeService.cs` | transfer history likhne ki galti theek |
| `tests\CloudSSD.Tests\WinFspSetupTests.cs` (nayi) | tests |

## Jaanch

- PC ke 460 test pass, 0 warning.
- Asli PC par: dialog aaya, Yes dabaya, WinFsp 2.1.25156 laga (09:15), Z: aur Y: jud gaye.
- Nahi jaancha: `Install.cmd` se WinFsp lagna (code likha hai, chala kar nahi dekha). `setup.exe` (ek file wala installer) is PC par nahi banta kyunki Inno Setup install nahi hai; usme WinFsp pehle se saath jaata tha.

## Wapas kaise jaayein

`CHANGED-FILES.txt` dekho. CHANGED files `..\before\` se project par copy karo, NEW files (`WinFspSetup.cs`, `WinFspOffer.cs`, `WinFspSetupTests.cs`) hata do, phir PC app dobara build karo.
Dhyan: `Install-CloudSSD.ps1` ko purana mat karo, warna folder copy wali galti wapas aa jayegi.

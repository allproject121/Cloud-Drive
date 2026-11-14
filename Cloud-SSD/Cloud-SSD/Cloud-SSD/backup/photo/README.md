# Purani photos (app ke purane icon aur logo)

Yahan app ki woh saari photos rakhi hain jo 14 November 2026 tak use hoti thin. Us din inki jagah naya icon
(neela "Ocean": safed badal, andar drive ki patti aur batti) laga diya gaya.
Har file usi raaste par rakhi hai jahan woh project mein thi, taaki wapas lagani ho to seedhi copy ho jaye.

| Purani photo | Kahan use hoti thi |
|---|---|
| `src\CloudSSD.Desktop\Assets\clouddrive.png` | PC app ke upar-baayein wala logo (sheeshe jaisa badal, andar chip) |
| `src\CloudSSD.Desktop\Assets\clouddrive.ico` | PC app ki program file aur window / taskbar ka icon |
| `src\CloudSSD.Desktop\Assets\cloudssd.ico` | setup (installer) ka icon: kaala dabba, neeli lakeer, baingani X |
| `mobile-android\src\main\res\mipmap-xxhdpi\ic_launcher.png` | phone app ka pehla icon (baad mein "Classic / Purana" naam ka option) |
| `mobile-android\src\main\assets\icon-classic.png` | phone ke icon chunne wale page mein "Classic" ki chhoti tasveer |
| `mobile-android\src\main\assets\icon-192.svg` | browser tab aur "home screen par jodo" wala icon (kaala, bijli wala badal) |
| `mobile-android\src\main\assets\icon-512.svg` | wahi, bada |

## Nayi photo kahan se banti hai

Ek hi drawing se sab banta hai: `tools\icons\make-icons.js` (drawing), `tools\icons\png.js` (PNG aur PC ki photo),
`tools\icons\make-ico.ps1` (PC ke .ico). Teeno ek saath: `installer\make-icon.ps1`.

## Purani photo wapas lagani ho

Is folder ki file ko usi raaste par project mein copy karo, phir PC app aur phone app dobara build karo.
Dhyan: `installer\make-icon.ps1` dobara chalaoge to nayi photo phir se ban kar purani ke upar aa jayegi.
Phone ka "Classic" option wapas chahiye to `backup\2026-11-14_1008_app-photo-latest\before\` se
`app.js`, `AndroidManifest.xml` aur `CloudDocumentsProvider.java` bhi wapas karne honge.

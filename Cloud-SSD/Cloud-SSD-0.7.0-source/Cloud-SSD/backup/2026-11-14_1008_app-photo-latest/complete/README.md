# App ki photo: purani hata kar nayi (Ocean) lagayi

Kaam ki tareekh: 14 November 2026. Jaanch: asli PC aur asli phone par.

## Yeh kya hai

App ki "photo" matlab uska icon aur logo: PC app ki window aur taskbar ka icon, PC app ke upar-baayein wala
logo, setup ka icon, phone ke home screen ka icon, aur browser tab wala icon.
Pehle in sab jagah alag-alag purani photos thin (sheeshe jaisa badal, kaala dabba, bijli wala badal).
Ab har jagah ek hi nayi photo hai: neela "Ocean" icon (safed badal, andar drive ki patti aur batti).

## Kya kaam hua

1. Saari purani photos `backup\photo\` mein rakh din (usi raaste par jahan woh project mein thin).
   Kaunsi photo kahan use hoti thi, yeh `backup\photo\README.md` mein likha hai.
2. PC app: `clouddrive.png` (logo), `clouddrive.ico` (window / taskbar / program file) aur `cloudssd.ico` (setup)
   naye icon se bane.
3. Phone app: browser wale `icon-192.svg` aur `icon-512.svg` naye icon se bane.
4. Phone ke icon chunne wale page se "Classic" (purani photo) hata di. Ab 6 icon hain:
   Ocean, Kit, Paper, Glow, Midnight, Sunset.
5. Jis phone mein pehle "Classic" chuna tha, uske home screen par ab Ocean icon dikhega (icon gayab nahi hoga).
6. Purani photo ki files project se hata din: `ic_launcher.png`, `icon-classic.png`.
7. PC app ko band karne aur uski screen ki photo lene ke do chhote auzaar bhi isi kaam mein bane
   (`tools\live-test\pc-close.ps1`, `pc-shot.ps1`), taaki jaanch ho sake.

## Kaise use hota hai

- Kuch karna nahi hai: PC app aur phone app kholte hi nayi photo dikhti hai.
- Phone par doosra icon chahiye: More → Look and language → "App icon" → jo pasand ho us par tap.
  App ek baar band hota hai; home screen ke naye icon se dobara kholo.
- Icon ki drawing badalni ho: `tools\icons\make-icons.js` mein badlo, phir `installer\make-icon.ps1` chalao.
  Woh saari photos (PC + phone) dobara bana deta hai. Uske baad PC app aur phone app build karo.

## Andar se kaise chalta hai (connection)

```
tools\icons\make-icons.js   (ek hi drawing, 6 rang)
        |
        |--> phone: res\drawable + mipmap  (home screen ke icon)
        |--> phone: assets\icon-<naam>.svg (icon chunne wale page ki tasveer)
        |--> assets\icon-192.svg, icon-512.svg  (browser tab; Ocean se)
        v
tools\icons\png.js
        |--> phone: ic_app_<naam>.png  (purane Android ke liye)
        |--> PC: Assets\clouddrive.png (1024 px, Ocean)
        v
tools\icons\make-ico.ps1
        |--> PC: Assets\clouddrive.ico, cloudssd.ico (16 se 256 px)
```

- PC app build ke waqt `clouddrive.ico` ko program file mein aur `clouddrive.png` ko window ke logo mein le leta hai.
- Phone mein har icon ka ek "alias" hai (`AndroidManifest.xml` mein `.IconOcean`, `.IconKit` …). Ek waqt mein ek hi
  on rehta hai; wahi home screen par dikhta hai. `.IconClassic` abhi bhi likha hai par usme bhi Ocean ki photo hai,
  aur page par uska card nahi hai.
- `assets` aur `wwwroot\mobile` ke page ki files ek jaisi rakhi gayi hain.

## Files

Is kaam ki har nayi / badli file ki taiyaar copy `complete\files\` mein hai; poori list `CHANGED-FILES.txt` mein.
Kaam se pehle ka source `before\` mein hai (use chheda nahi gaya).

## Jaanch

- Build: 0 warning. C# tests 462 pass, phone page ke tests 44 pass. APK bana, 0 naya warning.
- PC (asli): naya build install kiya, app khola: window ke upar aur baayein logo mein naya neela icon dikha;
  Z: aur Y: drive jude rahe.
- Phone (asli): app install kiya; home screen par naya icon; More → Look and language → App icon mein 6 icon
  dikhe, "Classic" nahi, koi tasveer tooti nahi.
- Jo nahi jaancha: setup.exe ka icon (is PC par Inno Setup nahi hai, isliye setup.exe banta hi nahi).

## Wapas kaise jaayein

1. `backup\photo\` ki files ko usi raaste par project mein copy karo (ya `before\` se wahi files).
2. `before\` se `app.js` (dono jagah), `AndroidManifest.xml`, `MainActivity.java`, `CloudDocumentsProvider.java`,
   `tools\icons\make-icons.js`, `tools\icons\png.js`, `installer\make-icon.ps1` wapas rakho.
3. `tools\icons\make-ico.ps1` hata do (yeh nayi file hai).
4. PC app aur phone app dobara build karo.

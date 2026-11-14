# Naye look mein Home ke heading wapas (System & Storage, Live, Send to PC)

Bana: 14 November 2026. Asli phone par teeno naye look (Kit, Paper, Glow) mein dekha: haan.

## Yeh kya hai

Purane look mein Home par har hisse ke upar naam likha rehta tha: cards ke upar baayein "System & Storage" aur
daayein "Live", phir "RAM" aur "Storage", aur Photos / Files / Folder ke upar "Send to PC".
Naye look (Kit, Paper, Glow) mein ye naam nahi the. Ab wahan bhi hain.

## Kya kaam hua

1. Cards ke upar ek line: baayein **System & Storage**, daayein **Live** (PC juda na ho to **Offline**, feeka).
2. Pehli line ke cards ke upar chhota naam **Storage**; doosri line ke upar **RAM · PC Drives**
   (us line mein Phone RAM, PC RAM aur PC Drives teeno hain, isliye dono naam).
3. Photos / Files / Folder ke upar **Send to PC** wapas dikhta hai (pehle naye look mein chhupa tha).
4. Glow mein daayein wala "Live" nahi lagaya: wahan upar PC ke naam ke saath "Live" pehle se hai.
5. Paper mein "Live" ke neeche line (underline) hata di, aur do lakeerein ek saath nahi aatin.

## Kaise use hota hai

Kuch karna nahi hai. Phone app -> Aur -> Look aur bhasha -> Kit, Paper ya Glow -> Home.
Purane look (Ocean, Colourful, Midnight, Phone jaisa) jaise the waise hi hain.

## Andar se kaise chalta hai

```
newlooks.js  (#nl-home banata hai)
   "System & Storage"   -> page ka apna shabd; bhasha badalne par apne aap badalta hai
   Live / Offline       -> header-status-dot dekh kar (wahi jo upar ke Live ke liye hai)
   "Storage", "RAM"     -> purane tiles ke apne chhote naam padh kar (chhupe hue tiles se), usi bhasha mein
   "PC Drives"          -> purane "PC Drives" tile ka naam
newlooks.css
   ".nl-send-sec > .section-header" ko chhupane wala rule hata -> "Send to PC" dikhta hai
```

Koi naya shabd nahi joda.

## Files

| File | Kaam |
|---|---|
| `mobile-android\src\main\assets\newlooks.js` | heading aur do chhote naam; `nl-head-live` ko Live/Offline |
| `mobile-android\src\main\assets\newlooks.css` | `.nl-head`, `.nl-head-live`, chhote naam ki jagah; Paper aur Glow ke chhote sudhaar |
| `src\CloudSSD.Desktop\wwwroot\mobile\newlooks.js/.css` | wahi files, PC app ke andar ki copy |

## Jaanch

- Phone ke 44 JS test aur PC ke 462 test pass.
- Asli phone par Home dekha: Kit, Paper, Glow. Paper mein "Live" par underline nahi (page se padh kar dekha).
- Nahi jaancha: PC band hone par "Offline" dikhna (PC chalu tha).

## Wapas kaise jaayein

`..\before\` se `newlooks.js` aur `newlooks.css` (dono jagah) project par copy karo, phone app dobara build karo.

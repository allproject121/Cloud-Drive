# Home ke teen chhote chips ab cards hain (Phone RAM, PC RAM, PC Drives)

Bana: 14 November 2026. Asli phone par teeno naye look (Kit, Paper, Glow) mein dekha: haan.

## Yeh kya hai

Phone app ke Home par (Kit, Paper aur Glow look mein) upar teen cards hain: Phone Storage, PC Storage, Cloud SSD.
Unke neeche Phone RAM, PC RAM aur PC Drives teen chhoti pattiyon (chips) mein the. Ab ye teeno bhi upar wale
teen jaise hi cards hain, usi size aur usi dhang ke.

## Kya kaam hua

1. Teen chips hata kar teen cards banaye, jo upar wale cards ka hi dhaancha use karte hain:
   - **Kit:** naam, bada number, neeche line, sabse neeche patti (bar).
   - **Paper:** naam, bada number, neeche line (bina dabbe ke, lakeeron ke beech).
   - **Glow:** gol gauge mein %, neeche naam aur ek line.
2. Card mein kya dikhta hai:
   - Phone RAM / PC RAM: bada "67%", neeche "4.79 GB / 7.13 GB", patti utni bhari.
   - PC Drives: bada "Z: Y:", neeche "online" aur PC ka naam, patti poori.
3. Har card ki patti ab card ke sabse neeche rehti hai, to ek line mein teeno pattiyan barabar dikhti hain.
4. **Ek purani galti theek hui:** "PC Storage" card mein "347 GB / 475 GB" wali line kabhi nahi dikhti thi.
   Do cheezon ka andar ka naam ek hi tha (`nl-pc-sub`): PC wale neele card ki line aur PC Storage card ki line.
   Ab cards ke hisson ke naam alag hain (`nl-s-<card>-<hissa>`).

## Kaise use hota hai

Kuch karna nahi hai. Phone app -> Aur -> Look aur bhasha -> Kit, Paper ya Glow chuno, Home kholo.
Kisi card par tap karne se wahi khulta hai jo pehle us chip (ya purane tile) par tap karne se khulta tha.
Purane look (Ocean, Colourful, Midnight, Phone jaisa) mein Home waisa hi hai jaisa tha.

## Andar se kaise chalta hai

```
app.js  ->  purane Home tiles ko bharta rehta hai (ye naye look mein chhupe rehte hain)
              hw-ram-pct / hw-ram-val / hw-ram-bar          (Phone RAM)
              hw-pcram-pct / hw-pcram-val / hw-pcram-bar    (PC RAM)
              hw-pc-drives-val / hw-pc-status-badge / hw-pc-bar   (PC Drives)
newlooks.js ->  in tiles ko dekhta rehta hai (badlav hote hi) aur unki value naye cards mein likhta hai
              STORES = upar ke teen cards, MORE = neeche ke teen cards, dono ek hi tareeke se bante hain (card())
newlooks.css -> ".nl-store" ka look teeno look ke liye pehle se likha tha; naye cards wahi class use karte hain
```

Koi naya shabd nahi joda: naam purane tiles se aate hain, jo pehle se Hinglish aur Hindi mein hain.

## Files

| File | Kaam |
|---|---|
| `mobile-android\src\main\assets\newlooks.js` | `MORE` list, `card()`, `split()` mein drive letters, cards ke hisson ke naye naam |
| `mobile-android\src\main\assets\newlooks.css` | chips ke rules hate; `.nl-more`; patti card ke neeche |
| `src\CloudSSD.Desktop\wwwroot\mobile\newlooks.js/.css` | wahi files, PC app ke andar ki copy |
| `tools\live-test\phone.ps1` (nayi) | asli phone par jaanch: page mein JS chalana + screenshot (call, lock aur saamne wala app pehle dekhta hai) |

## Jaanch

- Phone ke 44 JS test pass, APK bina naye warning ke bana.
- Asli phone par Home dekha: Kit (glass on), Paper, Glow. Chhe cards barabar size ke, koi chip nahi bacha.
- Nahi jaancha: naye cards par tap karke kya khulta hai (code wahi purana raasta use karta hai).

## Wapas kaise jaayein

`..\before\` se `newlooks.js` aur `newlooks.css` (dono jagah: `mobile-android\src\main\assets` aur
`src\CloudSSD.Desktop\wwwroot\mobile`) project par copy karo, phir phone app dobara build karo.
Dhyan: isse "PC Storage" wali line ki galti bhi wapas aa jayegi.

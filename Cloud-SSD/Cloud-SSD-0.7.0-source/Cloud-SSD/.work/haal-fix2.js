const fs = require('fs');
const now = process.argv[2];
const B = String.fromCharCode(92);
let s = fs.readFileSync('.work/haal.txt', 'utf8');
const rep = (a, b) => { if (!s.includes(a)) { console.log('missing: ' + a.slice(0, 50)); process.exit(1); } s = s.split(a).join(b); };
rep('16:55 — Claude', now + ' — Claude (window A)');
rep('- **A, 17:05:**', '- **A, ' + now + ':**');
rep('- [ ] 3.6 Saare tests (C#, JS), APK, PC build + install; asli device par jo ho sake (key ke bina: sahi sandesh dikhe)',
    '- [ ] 3.6 Saare tests pass (C# 464, JS 45), APK bana (`mobile-android' + B + 'Cloud-SSD-Mobile.apk`), PC release ban raha hai.\n      **Baaki:** phone adb par nahi tha (wireless debugging band) → APK install aur phone ki jaanch baaki; PC install + jaanch.\n      Phone par dekhna: (a) More → Permissions → "Files when it is off" mein doosri line ("Not ready yet" …) sahi dikhe,\n      (b) Cloud SSD tab pehle jaisa chale, (c) koi JS error nahi (`.work' + B + 't-whenoff.js` likhni hai).');
rep('**Agla kadam:** 3.6 (poore C# tests → APK phone par → PC build + install → Permissions page aur Cloud SSD tab dekhna).',
    '**Agla kadam:** 3.6 ka baaki: PC par naya build install karke dekhna; phone adb par aaye to APK install karke upar ke (a)(b)(c).');
let md = fs.readFileSync('CHALU_KAAM.md', 'utf8');
md = md.split('# APK: .work' + B + 'apk' + B + 'Cloud-SSD-Mobile.apk').join('# APK: mobile-android' + B + 'Cloud-SSD-Mobile.apk')
       .split('install -r .work' + B + 'apk' + B + 'Cloud-SSD-Mobile.apk').join('install -r mobile-android' + B + 'Cloud-SSD-Mobile.apk')
       .split('15:45 — Claude').join('15:45 — Claude');
fs.writeFileSync('CHALU_KAAM.md', md);
fs.writeFileSync('.work/haal.txt', s);

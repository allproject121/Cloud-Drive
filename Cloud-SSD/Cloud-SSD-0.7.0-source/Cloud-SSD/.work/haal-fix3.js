const fs = require('fs');
const now = process.argv[2];
const B = String.fromCharCode(92);
let s = fs.readFileSync('.work/haal.txt', 'utf8');
const cut = (from, to, text) => { const a = s.indexOf(from), b = s.indexOf(to, a); if (a < 0 || b < 0) { console.log('missing ' + from.slice(0, 40)); process.exit(1); } s = s.slice(0, a) + text + s.slice(b); };
s = s.replace(/\*\*Aakhri badlaav:\*\* .*/, '**Aakhri badlaav:** 14 Nov 2026, ' + now + ' — Claude (window A)');
cut('- [ ] 3.6 ', '- [ ] 3.7 ',
  '- [ ] 3.6 Saare tests pass (C# 464, JS 45). **PC: ho gaya** — naya build (0.9.0) install hokar chal raha hai, Z:/Y: jude,\n' +
  '      `/api/whenoff/key` bina device ke 401 deta hai. **Phone: baaki** — phone adb par nahi tha (wireless debugging band).\n' +
  '      Phone judte hi: `adb install -r mobile-android' + B + 'Cloud-SSD-Mobile.apk`, phir\n' +
  '      `tools' + B + 'live-test' + B + 'phone.ps1 -Launch -Js .work' + B + 't-whenoff.js -Shot whenoff-perm` (kuch badalta nahi, sirf dekhta hai).\n' +
  '      Sahi nateeja (abhi PC saajhi key par hai): rows mein "Keep copies in the cloud · On: …" aur "Not ready yet · … shared key …",\n' +
  '      `signInButton: false`, `errors: []`. Phir Cloud SSD tab ek baar khol kar dekho ki pehle jaisa chalta hai.\n');
cut('**Agla kadam:**', '**Ruka hua kis par:**',
  '**Agla kadam:** 3.6 ka phone wala hissa (upar likha hai). Uske baad 3.7 (key ke baad).\n');
cut('**Ruka hua kis par:**', '**Doosri window ka note',
  '**Ruka hua kis par:** (1) phone ka wireless debugging chalu ho; (2) 3.7 ke liye user ki apni Google key\n' +
  '(PC app → Cloud Drives → "How do I get a key?" → "Switch to my own Google key"). Key ke baad: phone ke Permissions mein\n' +
  '"Sign in" aayega → user Google mein sign in kare → PC par Devices → When off → Continue (chhota test: `Mirror.OnlyFolders`)\n' +
  '→ PC app band karke phone ke Cloud SSD tab mein "<PC> (cloud copy)" kholna.\n' +
  'PC par ab Phase 3 wala build chal raha hai. Commit / push nahi hua (user ne nahi kaha).\n\n');
fs.writeFileSync('.work/haal.txt', s);

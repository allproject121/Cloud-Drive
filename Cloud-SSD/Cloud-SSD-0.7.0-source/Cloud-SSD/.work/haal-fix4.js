const fs = require('fs');
const now = process.argv[2];
let s = fs.readFileSync('.work/haal.txt', 'utf8');
s = s.replace(/\*\*Aakhri badlaav:\*\* .*/, '**Aakhri badlaav:** 14 Nov 2026, ' + now + ' — Claude (window A)');
const a = '**Phone: baaki** — phone adb par nahi tha (wireless debugging band).';
if (!s.includes(a)) { console.log('missing'); process.exit(1); }
s = s.replace(a, '**Phone:** ' + now + ' par wireless debugging chalu mila, naya APK install ho gaya (Success). Jaanch **baaki**:\n      phone par Settings (Developer options) saamne tha, isliye app nahi chhua. User Cloud-SSD khole ya home screen par aaye, tab:');
s = s.replace('**Ruka hua kis par:** (1) phone ka wireless debugging chalu ho;', '**Ruka hua kis par:** (1) phone par Cloud-SSD saamne ho (ya home screen), tab `t-whenoff.js` chalana;');
fs.writeFileSync('.work/haal.txt', s);

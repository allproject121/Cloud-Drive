const fs = require('fs');
const now = process.argv[2];
const B = String.fromCharCode(92);
let s = fs.readFileSync('.work/haal.txt', 'utf8');
s = s.replace(/\*\*Aakhri badlaav:\*\* .*/, '**Aakhri badlaav:** 14 Nov 2026, ' + now + ' — Claude (window A)');
const a = s.indexOf('- [ ] 3.6 '), b = s.indexOf('- [ ] 3.7 ');
if (a < 0 || b < 0) { console.log('missing 3.6'); process.exit(1); }
s = s.slice(0, a) + '- [x] 3.6 Tests pass (C# 464, JS 45). PC: naya build install, chal raha hai. Phone (' + now + '): test APK install, `.work' + B + 't-whenoff.js` ka nateeja sahi:\n' +
  '      "Keep copies in the cloud · On: … both said yes" + "Not ready yet · … shared key …", Sign in button nahi, `errors: []`.\n' + s.slice(b);
fs.writeFileSync('.work/haal.txt', s);
let md = fs.readFileSync('CHALU_KAAM.md', 'utf8');
const x = 'powershell -ExecutionPolicy Bypass -File mobile-android' + B + 'build-apk.ps1   # APK: mobile-android' + B + 'Cloud-SSD-Mobile.apk\nC:' + B + 'Android' + B + 'Sdk' + B + 'platform-tools' + B + 'adb.exe install -r mobile-android' + B + 'Cloud-SSD-Mobile.apk';
if (!md.includes(x)) { console.log('md commands not found'); process.exit(1); }
md = md.replace(x,
  '# Jaanch wala APK (-Debug): isi mein phone.ps1 page ke andar jhaank sakta hai. Bina -Debug wala APK release ke liye hai\n' +
  '# (mobile-android' + B + 'Cloud-SSD-Mobile.apk); us par phone.ps1 "fetch failed / other side closed" deta hai.\n' +
  'powershell -ExecutionPolicy Bypass -File mobile-android' + B + 'build-apk.ps1 -Debug -OutDir .work' + B + 'apk\n' +
  'C:' + B + 'Android' + B + 'Sdk' + B + 'platform-tools' + B + 'adb.exe install -r .work' + B + 'apk' + B + 'Cloud-SSD-Mobile.apk');
fs.writeFileSync('CHALU_KAAM.md', md);

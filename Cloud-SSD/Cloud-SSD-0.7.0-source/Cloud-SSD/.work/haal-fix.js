const fs = require('fs');
let s = fs.readFileSync('.work/haal.txt', 'utf8');
const B = String.fromCharCode(92);
const rep = (a, b) => { if (!s.includes(a)) { console.log('missing: ' + a.slice(0, 50)); process.exit(1); } s = s.split(a).join(b); };
rep('`.workp3-words.json`', '`.work' + B + 'p3-words.json`');
rep('`mobile-androidsrcmainjavacomcloudssdmobileGoogleAuth.java`', '`mobile-android' + B + 'src' + B + 'main' + B + 'java' + B + 'com' + B + 'cloudssd' + B + 'mobile' + B + 'GoogleAuth.java`');
rep('`assetsapp.js`', '`assets' + B + 'app.js`');
rep('`wwwrootmobile`', '`wwwroot' + B + 'mobile`');
rep('`testsmobile-jsdata.test.js`', '`tests' + B + 'mobile-js' + B + 'data.test.js`');
rep('`.workp3-pc.js`, `p3-auth.js`, `p3-drive.js`, `p3-fix1.js`, `p3-page.js`', '`.work' + B + 'p3-pc.js`, `p3-auth.js`, `p3-drive.js`, `p3-fix1.js`, `p3-fix2.js`, `p3-page.js`');
rep('- User ko bata diya jayega ki ek kaam ke liye ek hi window chalayein.',
    '- User ko bata diya jayega ki ek kaam ke liye ek hi window chalayein.\n- **A, 17:05:** teeno baatein theek kar din (`.work' + B + 'p3-fix2.js`): copy mein `canCreate = false`, search `max * 3`, key badle to "dobara sign in".\n  C# tests 464 pass, JS 45 pass.');
fs.writeFileSync('.work/haal.txt', s);

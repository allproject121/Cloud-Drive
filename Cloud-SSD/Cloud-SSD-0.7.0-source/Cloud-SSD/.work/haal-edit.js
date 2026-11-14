const fs = require('fs');
let s = fs.readFileSync('.work/haal.txt', 'utf8');
const rep = (a, b) => { if (!s.includes(a)) { console.log('missing: ' + a.slice(0, 50)); process.exit(1); } s = s.replace(a, b); };
rep('16:10 — Claude', '16:55 — Claude');
rep('- [ ] 3.3 Phone: Google key chalte waqt — `GoogleAuth.java` (+ `MainActivity` bridge `setGoogleKey`)',
    '- [x] 3.3 Phone: Google key chalte waqt — `GoogleAuth.java` (`setKey`, `available(Context)`, revoke hataya), bridge `setGoogleKey`');
rep('- [ ] 3.4 Phone: `DriveBackend.java` nayi jad `pc-<pcId>` + chhupana + sirf padhna; `WhenOffStore` (kaun se PC)',
    '- [x] 3.4 Phone: `DriveBackend.java` jad `pc-<pcId>` (`copyBase`, `copyInfo`, `hidden`), sirf padhna; `WhenOffStore.java` (nayi);\n      bridge `whenOffSync`, cloudOp `copy-info`. APK compile hota hai.');
rep('- [ ] 3.5 Phone page (`app.js`, dono copy): key lena, sign-in ka button, jagah ka naam, patti; naye shabd i18n mein',
    '- [x] 3.5 Phone page: `data.js` (`whenOffReady`, `whenOffReadyText`, `copyNote`), `app.js` (`syncWhenOff`, Permissions mein doosri\n      line + "Sign in", `renderDriveNote`), 16 naye shabd (`.work\p3-words.json`), dono copy ek jaisi, JS tests 45 pass.');
rep('**Is kaam mein badli files (ab tak):**',
    '**Is kaam mein badli files (ab tak):**\n- Phone: `mobile-android\src\main\java\com\cloudssd\mobile\GoogleAuth.java`, `DriveBackend.java`, `MainActivity.java`,\n  `WhenOffStore.java` (nayi); `assets\app.js`, `data.js`, `i18n-words.js` (+ wahi teen `wwwroot\mobile` mein);\n  `tests\mobile-js\data.test.js`. Code poora hai, **asli phone par abhi nahi dekha**.\n- Patch scripts jo lag chuke (dobara mat chalao): `.work\p3-pc.js`, `p3-auth.js`, `p3-drive.js`, `p3-fix1.js`, `p3-page.js`.');
rep('**Agla kadam:** 3.3.', '**Agla kadam:** 3.6 (poore C# tests → APK phone par → PC build + install → Permissions page aur Cloud SSD tab dekhna).');
fs.writeFileSync('.work/haal.txt', s);

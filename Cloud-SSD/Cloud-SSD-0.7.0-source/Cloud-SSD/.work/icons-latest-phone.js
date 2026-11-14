// One-off patch: the phone app no longer offers or uses the old picture ("classic"). Its alias stays in the manifest
// with the new icon, so a phone that had "classic" chosen keeps an icon on its home screen after the update.
const fs = require('fs');
const repo = process.argv[2];
function patch(rel, swaps) {
  const p = repo + '/' + rel;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) {
    if (s.split(a).length !== 2) { console.log(rel + ' NOT ONCE: ' + a.slice(0, 80)); process.exit(1); }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
}
patch('mobile-android/src/main/assets/app.js', [
  ["    ['sunset', 'Sunset', 'icon-sunset.svg'],\n    ['classic', 'Classic', 'icon-classic.png']\n  ];",
   "    ['sunset', 'Sunset', 'icon-sunset.svg']\n  ];"]
]);
patch('mobile-android/src/main/AndroidManifest.xml', [
  ['             with. The drawings come from tools/icons/make-icons.js; "Classic" is the app\'s first icon. -->',
   '             with. The drawings come from tools/icons/make-icons.js. ".IconClassic" carried the app\'s first picture\n             (now in backup/photo); it is not offered any more and shows the new icon, so a phone that had it chosen\n             still has an icon after the update. -->'],
  ['android:enabled="false" android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher">',
   'android:enabled="false" android:icon="@mipmap/ic_app_ocean" android:roundIcon="@mipmap/ic_app_ocean">']
]);
patch('mobile-android/src/main/java/com/cloudssd/mobile/CloudDocumentsProvider.java', [
  ['R.mipmap.ic_launcher', 'R.mipmap.ic_app_ocean']
]);
patch('mobile-android/src/main/java/com/cloudssd/mobile/MainActivity.java', [
  ['     * that carries the icon}. The first one is the alias that is on in a new install.\n',
   '     * that carries the icon}. The first one is the alias that is on in a new install. "classic" is not offered any\n     * more (the page has no card for it); it stays here so that picking another icon switches its alias off.\n']
]);
for (const f of ['mobile-android/src/main/res/mipmap-xxhdpi/ic_launcher.png', 'mobile-android/src/main/assets/icon-classic.png', 'src/CloudSSD.Desktop/wwwroot/mobile/icon-classic.png']) {
  fs.rmSync(repo + '/' + f, { force: true });
  console.log('removed', f);
}
for (const f of ['app.js', 'icon-192.svg', 'icon-512.svg']) fs.copyFileSync(repo + '/mobile-android/src/main/assets/' + f, repo + '/src/CloudSSD.Desktop/wwwroot/mobile/' + f);
console.log('ok');

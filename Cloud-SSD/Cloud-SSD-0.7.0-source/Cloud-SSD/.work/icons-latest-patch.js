// One-off patch: the app's picture is the new icon (Ocean) everywhere. The generators also make the web page's icons
// and the PC app's picture from it; the old picture ("classic") is no longer made or offered.
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
patch('tools/icons/make-icons.js', [
  ['//   mobile-android/src/main/assets/icon-<key>.svg                 the picker\'s picture (the middle 72 of the 108)\n',
   '//   mobile-android/src/main/assets/icon-<key>.svg                 the picker\'s picture (the middle 72 of the 108)\n' +
   '// and, from the first icon (the app\'s own picture):\n' +
   '//   mobile-android/src/main/assets/icon-192.svg, icon-512.svg     the web page\'s icon (browser tab, "add to home screen")\n'],
  ['// Android 7 has no adaptive icons: mipmap-xxhdpi/ic_app_<key>.png is made from the SVG by tools/icons/png.js.\n// The app\'s old picture (mipmap-xxhdpi/ic_launcher.png) stays as the choice "classic"; nothing is made for it here.\n',
   '// Android 7 has no adaptive icons: mipmap-xxhdpi/ic_app_<key>.png is made from the SVG by tools/icons/png.js, which\n// also makes the PC app\'s picture (Assets/clouddrive.png); tools/icons/make-ico.ps1 makes the .ico files from that.\n// The pictures the app had before 14 Nov 2026 are kept in backup/photo.\n'],
  ['  write(`assets/icon-${i.key}.svg`, svg(i));\n}\n',
   '  write(`assets/icon-${i.key}.svg`, svg(i));\n}\n' +
   '// The web page\'s own icon is the app\'s picture: the first icon, at the two sizes the page names.\n' +
   'for (const size of [192, 512]) write(`assets/icon-${size}.svg`, svg(ICONS[0]).replace(\'width="144" height="144"\', `width="${size}" height="${size}"`));\n']
]);
patch('tools/icons/png.js', [
  ['//   mobile-android/src/main/assets/icon-classic.png              192 x 192, the old icon for the app\'s icon picker\n',
   '//   src/CloudSSD.Desktop/Assets/clouddrive.png                   1024 x 1024, the PC app\'s picture (from icon-ocean.svg)\n'],
  ['const classic = path.join(main, \'res\', \'mipmap-xxhdpi\', \'ic_launcher.png\');\nshot(`<img src="file:///${classic.replace(/\\\\/g, \'/\')}" width="192" height="192" style="display:block">`, 192, path.join(main, \'assets\', \'icon-classic.png\'));\nconsole.log(\'png classic\');\n',
   '// The PC app\'s picture: the app\'s own icon (Ocean), big.\nconst own = fs.readFileSync(path.join(main, \'assets\', \'icon-ocean.svg\'), \'utf8\').replace(\'width="144" height="144"\', \'width="1024" height="1024"\');\n' +
   'shot(own, 1024, path.join(main, \'..\', \'..\', \'..\', \'src\', \'CloudSSD.Desktop\', \'Assets\', \'clouddrive.png\'));\nconsole.log(\'png pc\');\n']
]);
console.log('ok');

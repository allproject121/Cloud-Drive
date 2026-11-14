// Turns the icon pictures made by make-icons.js into PNG files, with Microsoft Edge (headless) as the drawing tool:
//   mobile-android/src/main/res/mipmap-xxhdpi/ic_app_<key>.png   144 x 144, for Android 7 (no adaptive icons there)
//   mobile-android/src/main/assets/icon-classic.png              192 x 192, the old icon for the app's icon picker
//
//   node tools/icons/png.js
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const main = path.join(__dirname, '..', '..', 'mobile-android', 'src', 'main');
const edge = [process.env['ProgramFiles(x86)'], process.env.ProgramFiles].filter(Boolean)
  .map(p => path.join(p, 'Microsoft', 'Edge', 'Application', 'msedge.exe')).find(p => fs.existsSync(p));
if (!edge) { console.error('Microsoft Edge not found'); process.exit(1); }
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cssd-icons-'));

function shot(html, size, out) {
  const page = path.join(tmp, 'p.html');
  fs.writeFileSync(page, `<!doctype html><meta charset="utf-8"><body style="margin:0;background:transparent">${html}</body>`, 'utf8');
  execFileSync(edge, ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000',
    '--user-data-dir=' + path.join(tmp, 'prof'), '--screenshot=' + out, `--window-size=${size},${size}`, 'file:///' + page.replace(/\\/g, '/')], { stdio: 'ignore' });
}

const svgs = fs.readdirSync(path.join(main, 'assets')).filter(f => /^icon-[a-z]+\.svg$/.test(f));
for (const f of svgs) {
  const key = f.slice(5, -4);
  const svg = fs.readFileSync(path.join(main, 'assets', f), 'utf8');
  shot(svg, 144, path.join(main, 'res', 'mipmap-xxhdpi', `ic_app_${key}.png`));
  console.log('png', key);
}
const classic = path.join(main, 'res', 'mipmap-xxhdpi', 'ic_launcher.png');
shot(`<img src="file:///${classic.replace(/\\/g, '/')}" width="192" height="192" style="display:block">`, 192, path.join(main, 'assets', 'icon-classic.png'));
console.log('png classic');
fs.rmSync(tmp, { recursive: true, force: true });

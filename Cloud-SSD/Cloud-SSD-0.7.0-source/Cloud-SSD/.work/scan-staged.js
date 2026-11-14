// Before a push: which staged text files add lines that look like personal data, and where the staged files are.
// Usage (from the git root): node scan-staged.js [extra-word ...]
const { execFileSync } = require('child_process');
const git = (...a) => execFileSync('git', a, { maxBuffer: 1 << 30 }).toString('utf8');
const skip = /\/(bin|obj|dist)\/|\.(apk|dex|class|jar|png|ico|flat|idsig|exe|dll|pdb|zip|msi|db|jpg|jpeg|webp|cache)$/i;
const words = ['192\\.168\\.', '@gmail', 'DESKTOP-', 'LAPTOP-', 'C:\\\\Users\\\\(?!<|you|me|user|name)'].concat(process.argv.slice(2));
const re = new RegExp(words.join('|'), 'i');
const files = git('diff', '--cached', '--name-only', '--diff-filter=AM').split('\n').filter(Boolean);
const groups = {};
for (const f of files) { const k = f.replace('Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD/', '').split('/').slice(0, 2).join('/'); groups[k] = (groups[k] || 0) + 1; }
console.log('staged files:', files.length);
console.log(Object.entries(groups).sort((a, b) => b[1] - a[1]).slice(0, 20).map(([k, n]) => n + ' ' + k).join('\n'));
console.log('--- added lines that match:');
let hits = 0;
for (const f of files) {
  if (skip.test(f)) continue;
  let d;
  try { d = git('diff', '--cached', '-U0', '--text', '--', f); } catch (e) { continue; }
  const lines = d.split('\n').filter(l => l[0] === '+' && !l.startsWith('+++') && re.test(l));
  if (!lines.length) continue;
  hits += lines.length;
  console.log(lines.length + '  ' + f.replace('Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD/', ''));
  for (const l of lines.slice(0, 2)) console.log('     ' + l.slice(0, 170));
}
console.log('hits:', hits);

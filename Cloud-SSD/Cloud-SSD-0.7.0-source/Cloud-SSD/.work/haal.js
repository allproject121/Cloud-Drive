// Rewrites the "Abhi ka haal" part of CHALU_KAAM.md from a text file: node .work/haal.js <text-file>
const fs = require('fs');
const f = 'CHALU_KAAM.md';
const s = fs.readFileSync(f, 'utf8');
const at = s.indexOf('## Abhi ka haal');
if (at < 0) { console.log('no section'); process.exit(1); }
fs.writeFileSync(f, s.slice(0, at) + fs.readFileSync(process.argv[2], 'utf8').trim() + '\n');
console.log('haal updated');

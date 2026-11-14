// One-off: every part of a Home card is named nl-s-<key>-<part> (in the markup and where it is filled).
const fs = require('fs');
const p = process.argv[2] + '/newlooks.js';
let s = fs.readFileSync(p, 'utf8');
let n = 0;
s = s.replace(/id="nl-\$\{key\}-(arc|pct|label|big|word|sub|bar)"/g, (m, part) => { n++; return 'id="nl-s-${key}-' + part + '"'; });
s = s.replace(/'nl-' \+ key \+ '-(label|big|word|sub|pct|bar|arc)'/g, (m, part) => { n++; return "'nl-s-' + key + '-" + part + "'"; });
fs.writeFileSync(p, s);
const left = (s.match(/nl-\$\{key\}-|'nl-' \+ key \+ '-/g) || []).length;
console.log('replaced', n, 'left', left);
if (left) process.exit(1);

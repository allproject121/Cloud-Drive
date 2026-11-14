const fs = require('fs');
const p = process.argv[2] + '/newlooks.css';
let s = fs.readFileSync(p, 'utf8');
const a = ':root[data-look="paper"] .nl-head-live { text-decoration: none; }';
if (s.split(a).length !== 2) { console.log('NOT ONCE'); process.exit(1); }
s = s.replace(a, () => ':root[data-look="paper"] .nl-home .nl-head-live { text-decoration: none; }');
fs.writeFileSync(p, s);
console.log('ok');

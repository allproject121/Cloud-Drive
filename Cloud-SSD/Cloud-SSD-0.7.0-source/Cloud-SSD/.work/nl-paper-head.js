const fs = require('fs');
const p = process.argv[2] + '/newlooks.css';
let s = fs.readFileSync(p, 'utf8');
const a = ':root[data-look="paper"] .nl-store-bar { display: none; }\n';
if (s.split(a).length !== 2) { console.log('NOT ONCE'); process.exit(1); }
s = s.replace(a, () => a +
  '/* "Live" is a state, not a link; and the second row needs no line under it: the next heading brings its own. */\n' +
  ':root[data-look="paper"] .nl-head-live { text-decoration: none; }\n' +
  ':root[data-look="paper"] .nl-more { border-bottom: none; }\n');
fs.writeFileSync(p, s);
console.log('ok');

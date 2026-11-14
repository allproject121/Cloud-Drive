const fs = require('fs');
const p = process.argv[2] + '/newlooks.css';
let s = fs.readFileSync(p, 'utf8');
const swaps = [
  ['/* The second row of cards (phone RAM, PC RAM, PC drives): as far from the first as the cards are from each other. */\n.nl-more { margin-top: -4px; }\n', ''],
  ["/* The second row hangs under the first one's line; it needs no heavy line of its own. */\n:root[data-look=\"paper\"] .nl-more { border-top: none; margin-top: -12px; }\n", '']
];
for (const [a, b] of swaps) { if (s.split(a).length !== 2) { console.log('NOT ONCE: ' + a.slice(0, 60)); process.exit(1); } s = s.replace(a, () => b); }
fs.writeFileSync(p, s);
console.log('ok');

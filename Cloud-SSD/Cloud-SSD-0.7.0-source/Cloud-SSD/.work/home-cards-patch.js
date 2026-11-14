// One-off patch (kept out of the source tree's code): Home's three small chips (Phone RAM, PC RAM, PC drives) in the
// looks Kit, Paper and Glow become three cards drawn like the three storage cards above them.
const fs = require('fs');
const dir = process.argv[2];
function patch(file, swaps) {
  const p = dir + '/' + file;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) {
    if (s.split(a).length !== 2) { console.log(file + ' NOT ONCE: ' + a.slice(0, 80)); process.exit(1); }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
}
patch('newlooks.js', [
  [' *   #nl-home — the top of Home: the PC as a card (Kit), the three storages (bars in Kit, numbers in Paper, round\n *              gauges in Glow), and small chips for RAM and the PC\'s drives.',
   ' *   #nl-home — the top of Home: the PC as a card (Kit), the three storages (bars in Kit, numbers in Paper, round\n *              gauges in Glow), and under them three cards of the same kind for the phone\'s RAM, the PC\'s RAM and\n *              the PC\'s drives.'],
  ['  /** The smaller numbers: [key, the tile\'s value]. */\n  const CHIPS = [[\'ram\', \'hw-ram-pct\'], [\'pcram\', \'hw-pcram-pct\'], [\'drives\', \'hw-pc-drives-val\']];\n',
   '  /**\n   * The three cards under them, drawn the same way: [key, the tile\'s value (a percentage, or the drives), the line\n   * under it, its bar]. A RAM tile\'s line is "used / total"; the drives\' is the PC\'s name.\n   */\n' +
   '  const MORE = [\n    [\'ram\', \'hw-ram-pct\', \'hw-ram-val\', \'hw-ram-bar\'],\n    [\'pcram\', \'hw-pcram-pct\', \'hw-pcram-val\', \'hw-pcram-bar\'],\n    [\'drives\', \'hw-pc-drives-val\', \'hw-pc-status-badge\', \'hw-pc-bar\']\n  ];\n' +
   '  /** One card: a ring (Glow), its name, the big value, a word after it, a line under it, a bar (Kit). */\n' +
   '  const card = ([key]) => `\n        <button type="button" class="nl-store" data-nl-open="${key}">\n' +
   '          <span class="nl-ring"><svg viewBox="0 0 72 72" aria-hidden="true"><circle cx="36" cy="36" r="30"/><circle cx="36" cy="36" r="30" transform="rotate(-90 36 36)" id="nl-${key}-arc"/></svg><b id="nl-${key}-pct" data-no-i18n></b></span>\n' +
   '          <span class="nl-store-label" id="nl-${key}-label" data-no-i18n></span>\n          <span class="nl-store-big" id="nl-${key}-big" data-no-i18n></span>\n' +
   '          <span class="nl-store-word" id="nl-${key}-word" data-no-i18n></span>\n          <span class="nl-store-sub" id="nl-${key}-sub" data-no-i18n></span>\n' +
   '          <span class="nl-store-bar"><i id="nl-${key}-bar"></i></span>\n        </button>`;\n'],
  ['      <div class="nl-stores">${STORES.map(([key]) => `\n        <button type="button" class="nl-store" data-nl-open="${key}">\n' +
   '          <span class="nl-ring"><svg viewBox="0 0 72 72" aria-hidden="true"><circle cx="36" cy="36" r="30"/><circle cx="36" cy="36" r="30" transform="rotate(-90 36 36)" id="nl-${key}-arc"/></svg><b id="nl-${key}-pct" data-no-i18n></b></span>\n' +
   '          <span class="nl-store-label" id="nl-${key}-label" data-no-i18n></span>\n          <span class="nl-store-big" id="nl-${key}-big" data-no-i18n></span>\n' +
   '          <span class="nl-store-word" id="nl-${key}-word" data-no-i18n></span>\n          <span class="nl-store-sub" id="nl-${key}-sub" data-no-i18n></span>\n' +
   '          <span class="nl-store-bar"><i id="nl-${key}-bar"></i></span>\n        </button>`).join(\'\')}\n      </div>\n' +
   '      <div class="nl-chips">${CHIPS.map(([key]) => `<button type="button" class="nl-chip" data-nl-open="${key}" id="nl-chip-${key}" data-no-i18n></button>`).join(\'\')}</div>`;',
   '      <div class="nl-stores">${STORES.map(card).join(\'\')}\n      </div>\n      <div class="nl-stores nl-more">${MORE.map(card).join(\'\')}\n      </div>`;'],
  ['    if (parts.length >= 2 && /^[\\d.,]+$/.test(parts[0])) return [parts[0] + \' \' + parts[1], parts.slice(2).join(\' \')];\n    return [badge, \'\'];',
   '    if (parts.length >= 2 && /^[\\d.,]+$/.test(parts[0])) return [parts[0] + \' \' + parts[1], parts.slice(2).join(\' \')];\n' +
   '    // "Z: Y: online" → the drive letters big, what follows them small.\n' +
   '    const after = parts.findIndex(p => !/^[A-Za-z]:$/.test(p));\n    if (after > 0) return [parts.slice(0, after).join(\' \'), parts.slice(after).join(\' \')];\n    return [badge, \'\'];'],
  ['    for (const [key, badgeId, valId, barId] of STORES) {', '    for (const [key, badgeId, valId, barId] of STORES.concat(MORE)) {'],
  ['      // The gauges of Glow have no big number: their line under the name says what is free.\n      set(\'nl-\' + key + \'-sub\', look() === \'glow\' ? badge : text(valId));',
   '      // The gauges of Glow have no big number: their line under the name says what is free. A RAM gauge has its\n      // percentage in the ring already, so its line stays "used / total".\n' +
   '      const ram = key === \'ram\' || key === \'pcram\';\n      set(\'nl-\' + key + \'-sub\', look() === \'glow\' && !ram ? badge : text(valId));'],
  ['    for (const [key, valId] of CHIPS) {\n      const chip = $(\'nl-chip-\' + key);\n      if (!chip) continue;\n      const html = labelOf(key) + \' · \';\n      const value = text(valId);\n' +
   '      if (chip.dataset.shown !== html + value) {\n        chip.dataset.shown = html + value;\n        chip.textContent = html;\n        const b = document.createElement(\'b\');\n        b.textContent = value;\n        chip.appendChild(b);\n      }\n    }\n', '']
]);
patch('newlooks.css', [
  ['.nl-chips { display: flex; flex-wrap: wrap; gap: 6px; }\n', '/* The second row of cards (phone RAM, PC RAM, PC drives): as far from the first as the cards are from each other. */\n.nl-more { margin-top: -4px; }\n'],
  [':root[data-look="paper"] .nl-chip { background: transparent; border: 1px solid var(--look-line); border-radius: 8px; }\n',
   '/* The second row hangs under the first one\'s line; it needs no heavy line of its own. */\n:root[data-look="paper"] .nl-more { border-top: none; margin-top: -12px; }\n'],
  [':root[data-look="glow"] .nl-chip { border-radius: 16px; }\n', ''],
  [':is(.nl-store, .nl-chip, .nl-icon-btn:not(.nl-me))', ':is(.nl-store, .nl-icon-btn:not(.nl-me))']
]);
// The two chip rules that follow ".nl-chips" in the shared part go as well.
{
  const p = dir + '/newlooks.css';
  let s = fs.readFileSync(p, 'utf8');
  const before = s.length;
  s = s.replace(/^\.nl-chip \{[^\n]*\n/m, '').replace(/^\.nl-chip b \{[^\n]*\n/m, '');
  if (s.length === before || /\.nl-chip\b/.test(s)) { console.log('chip rules: left ' + (s.match(/\.nl-chip\b[^\n]*/g) || []).join(' | ')); process.exit(1); }
  fs.writeFileSync(p, s);
}
console.log('ok');

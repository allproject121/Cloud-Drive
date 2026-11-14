// Phase 3, phone page: fetches the PC's Google key once both said yes, tells the app which PCs' copy it may open,
// shows what is still missing (sign-in), and names the copy above the files. Run: node .work\p3-page.js <repo>
const fs = require('fs');
const repo = process.argv[2];
function patch(rel, swaps) {
  const p = repo + '/' + rel;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) {
    const n = s.split(a).length - 1;
    if (n !== 1) { console.log(rel + ' NOT ONCE (' + n + '): ' + a.slice(0, 90)); process.exit(1); }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
  console.log('ok', rel);
}
const A = 'mobile-android/src/main/assets/';

patch(A + 'data.js', [
  [`  /** The line under the switch for each state (pcName as written on the PC). */`,
`  /**
   * Once both said yes: what is still missing before this phone can open the PC's copy while the PC is off.
   * 'shared-key' (the PC has no Google key of its own to hand over), 'sign-in' (no Google account is signed in on
   * this phone yet), 'ready'. '' while it is not on.
   */
  function whenOffReady(w, drive) {
    if (whenOffState(w) !== 'on') return '';
    const d = drive || {};
    const signedIn = (d.accounts || []).some(a => a && !a.needsReauth);
    if (d.available && signedIn) return 'ready';
    if (!d.available && !w.key) return 'shared-key';
    return 'sign-in';
  }

  function whenOffReadyText(ready, pcName) {
    const pc = pcName || 'the PC';
    switch (ready) {
      case 'shared-key': return pc + ' still signs in to Google with the shared key. On the PC open Cloud Drives and switch to your own Google key; then this phone can open its files while it is off.';
      case 'sign-in': return 'One step left: sign in to Google on this phone, so the files of ' + pc + ' open while it is off.';
      case 'ready': return 'Ready. While ' + pc + ' is off, its files are in the Cloud SSD tab as "' + pc + ' (cloud copy)".';
      default: return '';
    }
  }

  /**
   * The line above a PC's copy: "My PC is off or away · cloud copy up to 14 Nov, 14:32 · 41% copied so far", from what
   * the PC last wrote about its copy (device.json). Parts that are not known are left out.
   */
  function copyNote(info, pcName, fmtTime) {
    const dev = info && info.device;
    const parts = [(pcName || 'PC') + ' is off or away'];
    const at = dev && Date.parse(dev.lastSync);
    parts.push(at ? 'cloud copy up to ' + fmtTime(at) : 'cloud copy');
    if (dev && dev.bytes > 0) {
      const pct = Math.floor(100 * (dev.uploadedBytes || 0) / dev.bytes);
      if (pct < 100) parts.push(pct + '% copied so far');
    }
    return parts.join(' · ');
  }

  /** The line under the switch for each state (pcName as written on the PC). */`],
  [`upsertTask, whenOffState, whenOffText
  };`, `upsertTask, whenOffState, whenOffText, whenOffReady, whenOffReadyText, copyNote
  };`]
]);

patch(A + 'app.js', [
  // the row in Permissions
  [`    const mine = !!(w && w.device);
    return \`<div class="perm-row \${state === 'on' ? 'on' : ''}">
        <div class="perm-row-text"><div>Keep copies in the cloud</div><div class="perm-row-sub">\${esc(DATA.whenOffText(state, link.pcName))}</div></div>
        <button class="m3-tonal-btn" data-act="whenoff-set" data-on="\${mine ? '0' : '1'}">\${mine ? 'Stop' : 'Allow…'}</button>
      </div>\`;
  }`,
`    const mine = !!(w && w.device);
    // Both said yes: what this phone still needs before it can open the PC's files while the PC is off.
    const ready = DATA.whenOffReady(w, drive);
    const more = ready ? \`<div class="perm-row \${ready === 'ready' ? 'on' : ''}">
        <div class="perm-row-text"><div>\${ready === 'ready' ? 'Opens while the PC is off' : 'Not ready yet'}</div><div class="perm-row-sub">\${esc(DATA.whenOffReadyText(ready, link.pcName))}</div></div>
        \${ready === 'sign-in' ? '<button class="m3-tonal-btn" data-act="drive-add">Sign in</button>' : ''}
      </div>\` : '';
    return \`<div class="perm-row \${state === 'on' ? 'on' : ''}">
        <div class="perm-row-text"><div>Keep copies in the cloud</div><div class="perm-row-sub">\${esc(DATA.whenOffText(state, link.pcName))}</div></div>
        <button class="m3-tonal-btn" data-act="whenoff-set" data-on="\${mine ? '0' : '1'}">\${mine ? 'Stop' : 'Allow…'}</button>
      </div>\` + more;
  }
  let whenOffKeyAt = 0;
  /**
   * Tells the app whether this phone may open this PC's copy in the cloud (both said yes), so it still knows while
   * the PC is off. And once: fetches the PC's Google key (never a sign-in) when this phone has none, so the user can
   * sign in to Google here.
   */
  function syncWhenOff() {
    if (!isApp || !link.pcId || typeof native.whenOffSync !== 'function') return;
    const w = link.status && link.status.whenOff;
    if (!w) return;
    const on = DATA.whenOffState(w) === 'on';
    try { native.whenOffSync(link.pcId, link.pcName || '', on); } catch (e) { return; }
    if (!on || !w.key || drive.available || Date.now() - whenOffKeyAt < 60000) return;
    whenOffKeyAt = Date.now();
    api('/api/whenoff/key', { noAsk: true }).then(r => {
      if (!r || !r.ok || !r.data || !r.data.clientId) return;
      try { native.setGoogleKey(r.data.clientId, r.data.clientSecret || ''); } catch (e) { return; }
      refreshDrive();
      if (isOpen('perm-sheet')) renderPermissions();
    }).catch(() => { });
  }`],
  [`    if (link.status) link.status.whenOff = r.data;
    if (isOpen('perm-sheet')) renderPermissions();`,
`    if (link.status) link.status.whenOff = r.data;
    syncWhenOff();
    if (isOpen('perm-sheet')) renderPermissions();`],
  [`  function onStatus(st) {
    link.status = st;
    link.lastOnline = Date.now();
    if (st.pcName && st.pcName !== link.pcName) { link.pcName = st.pcName; ls.set('cloudssd_pc_name', link.pcName); }`,
`  function onStatus(st) {
    link.status = st;
    link.lastOnline = Date.now();
    if (st.pcName && st.pcName !== link.pcName) { link.pcName = st.pcName; ls.set('cloudssd_pc_name', link.pcName); }
    if (st.pcId === link.pcId) syncWhenOff();`],
  [`  function leaveDevice(forgotten) {
    if (!forgotten) {`,
`  function leaveDevice(forgotten) {
    // A forgotten PC: its copy in the cloud is not this phone's to open any more.
    if (forgotten && link.pcId && isApp && typeof native.whenOffSync === 'function') { try { native.whenOffSync(link.pcId, '', false); } catch (e) { } }
    if (!forgotten) {`],
  // the line above the files
  [`  async function loadDriveRoots() {`,
`  const copyInfo = new Map();   // pcId → {at, data}: what a PC last wrote about its copy
  function copyPcOf(path) { const m = /^pc-([^:]+):/i.exec(String(path || '')); return m ? m[1] : ''; }
  /** The line above the files while the PC is away: where they come from; for a PC's copy also how old it is. */
  function renderDriveNote(path) {
    const el = $('ssd-drive-note');
    if (!el) return;
    const pc = copyPcOf(path);
    if (!pc) { el.textContent = 'PC is off — your files come straight from Google Drive'; return; }
    const hit = copyInfo.get(pc);
    const name = pc === link.pcId && link.pcName ? link.pcName : hit && hit.data && hit.data.name;
    el.textContent = DATA.copyNote(hit && hit.data, name, fmtDate);
    if (hit && Date.now() - hit.at < 5 * 60000) return;
    copyInfo.set(pc, { at: Date.now(), data: hit && hit.data });
    cloudOp('copy-info', { pc }).then(r => {
      if (!r.ok || !r.data) return;
      copyInfo.set(pc, { at: Date.now(), data: r.data });
      if (copyPcOf(ssd.path) === pc) renderDriveNote(ssd.path);
    });
  }
  async function loadDriveRoots() {`],
  [`    if (isCloudId(path) && cloudSource() === 'drive') { loadDriveFolder(path); return; }
    renderSsdDrives();`,
`    if (isCloudId(path) && cloudSource() === 'drive') { renderDriveNote(path); loadDriveFolder(path); return; }
    renderSsdDrives();`],
  [`          drive.roots = [];
          if (isOpen('settings-modal')) renderSettings();`,
`          drive.roots = [];
          if (isOpen('settings-modal')) renderSettings();
          if (isOpen('perm-sheet')) renderPermissions();`]
]);

patch('tests/mobile-js/data.test.js', [[
`test('files when it is off: on only when the phone and the PC both said yes', () => {`,
`test('files when it is off: what is missing before the PC\\'s copy opens, and the line above it', () => {
  const on = { pc: true, device: true, active: true, key: true };
  const signedIn = { available: true, accounts: [{ email: 'a@x.com' }] };
  assert.equal(data.whenOffReady({ pc: true, device: false }, signedIn), '');            // not on: nothing to say
  assert.equal(data.whenOffReady({ ...on, key: false }, { available: false, accounts: [] }), 'shared-key');
  assert.equal(data.whenOffReady(on, { available: false, accounts: [] }), 'sign-in');    // the key is on its way
  assert.equal(data.whenOffReady(on, { available: true, accounts: [] }), 'sign-in');
  assert.equal(data.whenOffReady(on, { available: true, accounts: [{ email: 'a@x.com', needsReauth: true }] }), 'sign-in');
  assert.equal(data.whenOffReady(on, signedIn), 'ready');
  assert.equal(data.whenOffReady({ ...on, key: false }, signedIn), 'ready');             // the app was built with a key
  assert.match(data.whenOffReadyText('ready', 'My PC'), /"My PC \\(cloud copy\\)"/);
  assert.match(data.whenOffReadyText('shared-key', ''), /^the PC still signs in/);
  assert.equal(data.whenOffReadyText('', 'My PC'), '');

  const fmt = t => 'T' + t;
  const at = Date.parse('2026-11-14T09:02:00Z');
  assert.equal(data.copyNote(null, 'My PC', fmt), 'My PC is off or away · cloud copy');
  assert.equal(data.copyNote({ device: { lastSync: '2026-11-14T09:02:00Z', bytes: 200, uploadedBytes: 82 } }, 'My PC', fmt),
    'My PC is off or away · cloud copy up to T' + at + ' · 41% copied so far');
  assert.equal(data.copyNote({ device: { lastSync: '2026-11-14T09:02:00Z', bytes: 200, uploadedBytes: 200 } }, '', fmt),
    'PC is off or away · cloud copy up to T' + at);
});

test('files when it is off: on only when the phone and the PC both said yes', () => {`]]);

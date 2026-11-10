// Cloud-SSD mobile — using a cloud drive like normal storage from the Cloud SSD tab:
// new folder, upload here, rename, move, delete. Everything goes through the PC's /api/fs/ routes.
// Loaded before app.js, which hands over what this file needs through CloudSsdFs.init().
(function () {
  'use strict';

  let app = null;          // helpers and state from app.js
  let rows = [];           // actions of the sheet that is open
  let moving = null;       // { id, name } — the item picked with "Move to…"
  let promptResolve = null;
  let uploadFolder = '';   // folder "Upload here" was started in, to refresh it when a file arrives

  const ICON = {
    newFolder: '<svg viewBox="0 0 24 24"><path d="M20 6h-8l-2-2H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-1 8h-3v3h-2v-3h-3v-2h3V9h2v3h3v2z"/></svg>',
    rename: '<svg viewBox="0 0 24 24"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>',
    move: '<svg viewBox="0 0 24 24"><path d="M20 6h-8l-2-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm-6 12v-3h-4v-4h4V8l5 5-5 5z"/></svg>',
    trash: '<svg viewBox="0 0 24 24"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>'
  };

  const $ = (id) => document.getElementById(id);

  // ---- which folder on which drive ---------------------------------------------------------------------------

  /** The connected cloud drive a path belongs to, or null (PC disks and the "From phone" folder are not managed here). */
  function place(path) {
    const pl = app.placeOf(path);
    return pl && pl.cloud && pl.id && pl.mounted ? pl : null;
  }
  /** "Z:\Photos\a.jpg" → "cloudssd:Photos/a.jpg": the PC names cloud items by drive, not by drive letter. */
  function idOf(path) {
    const pl = place(path);
    if (!pl) return null;
    return pl.id + ':' + String(path).slice(pl.root.length).split('\\').filter(Boolean).join('/');
  }
  function childId(folderId, name) { return folderId + (folderId.endsWith(':') ? '' : '/') + name; }
  /** Windows cannot store these characters, or a name that ends in a dot or space. */
  function cleanName(name) { return String(name).replace(/[\\/:*?"<>|\u0000-\u001f]/g, '_').replace(/[. ]+$/, ''); }

  async function call(route, params) {
    if (app.link.state !== 'online') { app.toast('PC is not connected'); return null; }
    try {
      const r = await app.api('/api/fs/' + route, { method: 'POST', params, timeout: 300000 });
      if (r.ok) return r.data || {};
      // A PC app from before file management answers every /api/fs/ route with this.
      const oldPc = r.status === 404 && r.data && r.data.error === 'API endpoint not found';
      app.toast(oldPc ? 'Update Cloud-SSD on the PC to manage files from the phone' : app.apiError(r));
    } catch (e) {
      app.toast('PC did not answer');
    }
    return null;
  }
  function refresh() { if (app.ssd.path) app.loadSsd(app.ssd.path, true); }

  // ---- small dialogs -----------------------------------------------------------------------------------------

  function sheet(title, list) {
    rows = list;
    $('fs-sheet-title').textContent = title;
    $('fs-sheet-list').innerHTML = list.map((a, i) => `
      <div class="m3-sheet-row" data-act="fs-row" data-i="${i}">
        ${a.icon}
        <div class="m3-sheet-row-text"><div>${app.esc(a.title)}</div>${a.sub ? `<div class="m3-sheet-row-sub">${app.esc(a.sub)}</div>` : ''}</div>
      </div>`).join('');
    app.openSheet('fs-sheet');
  }
  /** Asks for a name; resolves to the trimmed text, or null when cancelled. */
  function ask(title, value, okLabel) {
    if (promptResolve) promptResolve(null);
    $('fs-prompt-title').textContent = title;
    $('fs-prompt-yes').textContent = okLabel || 'OK';
    const input = $('fs-prompt-input');
    input.value = value || '';
    app.openSheet('fs-prompt');
    setTimeout(() => {
      input.focus();
      const dot = input.value.lastIndexOf('.');
      input.setSelectionRange(0, dot > 0 ? dot : input.value.length);
    }, 120);
    return new Promise(resolve => { promptResolve = resolve; });
  }
  function answer(value) {
    const r = promptResolve;
    promptResolve = null;
    app.closeSheet('fs-prompt');
    if (r) r(value);
  }

  // ---- actions -----------------------------------------------------------------------------------------------

  async function newFolder() {
    const folder = idOf(app.ssd.path);
    const name = await ask('New folder', '', 'Create');
    if (!name) return;
    const made = await call('create', { parent: folder, name: cleanName(name), dir: 1 });
    if (made) { app.toast('Folder created: ' + made.name); refresh(); }
  }

  function uploadHere() {
    const folder = idOf(app.ssd.path);
    uploadFolder = app.ssd.path;
    if (app.isApp) {
      try { app.native.setUploadTarget(folder); app.native.pickAndUploadFiles('files'); }
      catch (e) { app.toast('Update the Cloud-SSD app to upload into a cloud folder'); }
    } else {
      $('fs-uploader').click();
    }
  }
  /** Phone browser without the app: send the chosen files straight to the folder. */
  async function uploadInBrowser(files, folder) {
    let done = 0;
    for (const file of files) {
      app.toast(`Uploading ${file.name} (${done + 1} of ${files.length})…`);
      try {
        const res = await fetch(app.apiUrl('/api/fs/write', { path: childId(folder, cleanName(file.name)), overwrite: 0 }), { method: 'POST', body: file });
        if (res.ok) done++;
        else { let msg = 'PC answered HTTP ' + res.status; try { msg = (await res.json()).error || msg; } catch (e) { } app.toast(msg); }
      } catch (e) { app.toast('PC not reachable'); break; }
    }
    if (done) { app.toast(done === 1 ? 'Uploaded 1 file' : `Uploaded ${done} files`); refresh(); }
  }

  async function rename(item, id) {
    const name = await ask('Rename', item.name, 'Rename');
    if (!name || name === item.name) return;
    const r = await call('rename', { path: id, name: cleanName(name) });
    if (r) { app.toast('Renamed to ' + r.name); refresh(); }
  }

  async function remove(item, id) {
    const ok = await app.confirmDialog(item.isFolder ? 'Delete this folder?' : 'Delete this file?',
      `"${item.name}"${item.isFolder ? ' and everything in it' : ''} will be moved to the trash of the cloud account.`, 'Delete');
    if (!ok) return;
    app.toast('Deleting ' + item.name + '…');
    const r = await call('delete', { path: id });
    if (r) { app.toast('Deleted ' + item.name); refresh(); }
  }

  function startMove(item, id) {
    moving = { id, name: item.name };
    renderMoveBar();
    app.toast('Open the folder it should go to, then tap "Move here"');
  }
  async function moveHere() {
    if (!moving) return;
    const to = idOf(app.ssd.path);
    if (!to) { app.toast('Open a folder on a cloud drive first'); return; }
    const item = moving;
    app.toast('Moving ' + item.name + '…');
    const r = await call('move', { path: item.id, to });
    if (!r) return;               // the bar stays, so another folder can be tried
    moving = null;
    renderMoveBar();
    app.toast('Moved ' + item.name);
    refresh();
  }
  function renderMoveBar() {
    const bar = $('fs-move-bar');
    bar.style.display = moving ? 'flex' : 'none';
    if (moving) $('fs-move-text').textContent = 'Moving "' + moving.name + '"';
  }

  /** Rename / move / delete for one cloud file or folder; empty for anything that is not on a cloud drive. */
  function itemActions(item) {
    const id = app ? idOf(item.path) : null;
    if (!id) return [];
    return [
      { icon: ICON.rename, title: 'Rename', sub: 'Change the name on the cloud drive', fn: () => rename(item, id) },
      { icon: ICON.move, title: 'Move to…', sub: 'Then open the folder it should go to', fn: () => startMove(item, id) },
      { icon: ICON.trash, title: 'Delete', sub: 'Goes to the trash of the cloud account', fn: () => remove(item, id) }
    ];
  }

  // ---- camera backup (Android app only) ----------------------------------------------------------------------

  function backupStatus() {
    try { return JSON.parse(app.native.getCameraBackup()); } catch (e) { return null; }
  }
  function ago(ms) {
    const min = Math.round((Date.now() - ms) / 60000);
    if (min < 1) return 'just now';
    if (min < 60) return min + ' min ago';
    if (min < 48 * 60) return Math.round(min / 60) + ' h ago';
    return Math.round(min / 1440) + ' days ago';
  }
  function renderBackup() {
    const s = backupStatus();
    if (!s || !$('backup-card')) return;
    $('backup-state-pill').textContent = s.running ? 'Backing up…' : s.enabled ? 'On' : 'Off';
    $('backup-last-pill').textContent = s.error ? s.error
      : !s.enabled ? 'Photos stay only on this phone'
      : s.waiting > 0 ? s.waiting + ' waiting for the PC'
      : s.lastRun ? 'Up to date · checked ' + ago(s.lastRun) : 'Not run yet';
    $('backup-total-pill').textContent = s.total > 0 ? s.total + ' saved to the cloud' : '';
    $('backup-total-pill').style.display = s.total > 0 ? '' : 'none';
    $('backup-toggle-btn').textContent = s.enabled ? 'Turn off' : 'Turn on';
    $('backup-now-btn').style.display = s.enabled ? '' : 'none';
    $('backup-now-btn').disabled = !!s.running;
  }
  function buildBackupCard() {
    if (!app.isApp || !app.native.getCameraBackup) return; // a browser, or an older app
    const saver = document.querySelector('.saver-card');
    if (!saver) return;
    const card = document.createElement('div');
    card.className = 'pc-connection-banner-card saver-card';
    card.id = 'backup-card';
    card.style.marginTop = '12px';
    card.innerHTML = `
      <div class="pc-conn-left">
        <div class="pc-conn-icon-halo saver-halo">
          <svg viewBox="0 0 24 24"><path d="M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8.2A3.2 3.2 0 1 0 12 15.2 3.2 3.2 0 0 0 12 8.8z"/></svg>
        </div>
        <div class="pc-conn-info">
          <div class="pc-conn-title">Camera backup</div>
          <div class="pc-conn-sub">New photos and videos go to "Phone Backup" on the cloud drive when the PC is on the same Wi-Fi</div>
          <div class="pc-conn-pills-row">
            <span class="pc-conn-pill speed" id="backup-state-pill">—</span>
            <span class="pc-conn-pill" id="backup-last-pill">—</span>
            <span class="pc-conn-pill ping" id="backup-total-pill"></span>
          </div>
        </div>
      </div>
      <div class="pc-conn-actions">
        <button class="pc-conn-toggle-btn saver-btn" data-act="backup-now" id="backup-now-btn">Back up now</button>
        <button class="pc-conn-toggle-btn saver-btn" data-act="backup-toggle" id="backup-toggle-btn">Turn on</button>
      </div>`;
    saver.parentNode.insertBefore(card, saver.nextSibling);

    Object.assign(app.actions, {
      'backup-toggle': async () => {
        const s = backupStatus() || {};
        if (s.enabled) { app.native.setCameraBackup(false); app.toast('Camera backup is off'); renderBackup(); return; }
        const ok = await app.confirmDialog('Turn on camera backup?',
          'Every photo and video in the camera folder is copied to "Phone Backup" on the cloud drive, starting now. New ones follow by themselves whenever the PC is on the same Wi-Fi.', 'Turn on');
        if (!ok) return;
        if (!app.native.setCameraBackup(true)) { app.toast('Allow access to photos first (Phone tab)'); return; }
        app.toast(app.link.state === 'online' ? 'Camera backup started' : 'Camera backup is on — it starts when the PC is reachable');
        renderBackup();
      },
      'backup-now': () => {
        if (app.link.state !== 'online') { app.toast('PC is not connected'); return; }
        app.native.backupNow();
        app.toast('Checking the camera folder…');
        setTimeout(renderBackup, 1500);
      }
    });
    renderBackup();
    setInterval(() => { if (!document.hidden) renderBackup(); }, 4000);
  }

  // ---- wiring ------------------------------------------------------------------------------------------------

  function buildDom() {
    const style = document.createElement('style');
    style.textContent = `
      #fs-move-bar { position: fixed; left: 12px; right: 12px; bottom: calc(84px + env(safe-area-inset-bottom, 0px)); z-index: 210; display: none;
        align-items: center; gap: 8px; padding: 10px 12px 10px 16px; border-radius: 18px; background: #0B3A82;
        border: 1px solid rgba(168, 199, 250, 0.4); box-shadow: 0 6px 18px rgba(0, 0, 0, 0.5); color: #fff; font-size: 14px; }
      #fs-move-text { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      #fs-move-bar button { border: 0; border-radius: 16px; height: 32px; padding: 0 14px; font-size: 13px; font-weight: 600; }
      #fs-move-bar .ghost { background: transparent; color: #D3E3FD; }
      #fs-move-bar .go { background: #A8C7FA; color: #062E6F; }
      #fs-prompt { z-index: 1300; }
      #fs-prompt .modal-input { margin: 14px 0 18px; }
      .folder-item .item-more-btn { margin-left: auto; }
      #backup-card .pc-conn-actions { display: flex; flex-direction: column; gap: 8px; }
      #backup-card .pc-conn-toggle-btn { white-space: nowrap; }`;
    document.head.appendChild(style);

    const box = document.createElement('div');
    box.innerHTML = `
      <div id="fs-sheet" class="m3-bottom-sheet-backdrop" data-act="sheet-close">
        <div class="m3-bottom-sheet">
          <div class="m3-drag-handle"></div>
          <div class="sheet-subtitle" id="fs-sheet-title"></div>
          <div class="m3-sheet-list" id="fs-sheet-list"></div>
        </div>
      </div>
      <div id="fs-prompt" class="modal-backdrop">
        <div class="modal-card">
          <div class="modal-title" id="fs-prompt-title"></div>
          <input type="text" id="fs-prompt-input" class="modal-input" autocomplete="off" maxlength="200" enterkeyhint="done">
          <div class="confirm-actions">
            <button class="m3-tonal-btn" data-act="fs-prompt-no">Cancel</button>
            <button class="m3-filled-btn" data-act="fs-prompt-yes" id="fs-prompt-yes">OK</button>
          </div>
        </div>
      </div>
      <input type="file" id="fs-uploader" style="display: none;" multiple>`;
    while (box.firstElementChild) document.body.appendChild(box.firstElementChild);

    // Inside the Cloud SSD tab, so the bar is only there while that tab is.
    const bar = document.createElement('div');
    bar.id = 'fs-move-bar';
    bar.innerHTML = '<div id="fs-move-text"></div><button class="ghost" data-act="fs-move-cancel">Cancel</button><button class="go" data-act="fs-move-here">Move here</button>';
    ($('tab-ssd') || document.body).appendChild(bar);

    $('fs-prompt-input').addEventListener('keydown', (e) => { if (e.key === 'Enter') answer($('fs-prompt-input').value.trim()); });
    $('fs-uploader').addEventListener('change', (e) => {
      const files = Array.from(e.target.files || []);
      const folder = idOf(uploadFolder);
      e.target.value = '';
      if (files.length && folder) uploadInBrowser(files, folder);
    });
  }

  function init(helpers) {
    app = helpers;
    buildDom();
    buildBackupCard();
    Object.assign(app.actions, {
      // "+" in the Cloud SSD toolbar: what can be added to the folder that is open.
      'fs-menu': () => {
        if (app.link.state !== 'online') { app.toast('PC is not connected'); return; }
        if (!idOf(app.ssd.path)) { app.toast('Open a cloud drive first — PC disks cannot be changed from the phone'); return; }
        sheet('Add to this folder', [
          { icon: ICON.newFolder, title: 'New folder', sub: 'Create a folder here', fn: newFolder },
          { icon: app.SVG.upload, title: 'Upload files here', sub: 'Photos, videos or any file from this phone', fn: uploadHere }
        ]);
      },
      'fs-folder-more': (el) => {
        const fo = app.ssd.view.folders[+el.dataset.i];
        if (!fo) return;
        const item = { name: fo.name, path: fo.path, isFolder: true };
        sheet(fo.name, [{ icon: app.SVG.folder, title: 'Open', sub: '', fn: () => app.loadSsd(fo.path) }].concat(itemActions(item)));
      },
      'fs-row': (el) => { const a = rows[+el.dataset.i]; app.closeSheet('fs-sheet'); if (a) a.fn(); },
      'fs-prompt-yes': () => answer($('fs-prompt-input').value.trim()),
      'fs-prompt-no': () => answer(null),
      'fs-move-here': moveHere,
      'fs-move-cancel': () => { moving = null; renderMoveBar(); }
    });

    // A file sent with "Upload here" has arrived: show it.
    const onNative = window.onNative;
    window.onNative = function (event, data) {
      if (onNative) onNative(event, data);
      if (event === 'transfer' && data && data.type === 'upload' && data.state === 'done' && uploadFolder && uploadFolder === app.ssd.path) refresh();
    };
  }

  window.CloudSsdFs = {
    init,
    /** True when the folder is on a connected cloud drive, so its items get a "more" button. */
    canManage: (path) => !!app && !!idOf(path),
    fileActions: (f) => itemActions({ name: f.name, path: f.path, isFolder: false })
  };
})();

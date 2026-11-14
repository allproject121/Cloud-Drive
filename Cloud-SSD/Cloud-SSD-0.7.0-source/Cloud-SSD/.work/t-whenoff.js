// Live check on the phone for "Files when it is off" (Phase 3): the Permissions page shows the two rows, the app
// knows the PC's answer, nothing throws. Changes nothing (no taps on Allow / Stop / Sign in).
//   powershell -ExecutionPolicy Bypass -File tools\live-test\phone.ps1 -Launch -Js .work\t-whenoff.js -Shot whenoff-perm
(async () => { const w = ms => new Promise(r => setTimeout(r, ms));
 const errors = [];
 window.addEventListener('error', e => errors.push(String(e.message)));
 for (let i = 0; i < 4; i++) { if (document.querySelector('.as-page.active') && window.onAndroidBack) { window.onAndroidBack(); await w(250); } }
 const look = localStorage.getItem('cloudssd_look');
 document.getElementById('nav-more').click(); await w(500);
 const row = [...document.querySelectorAll('#tab-more .more-row')].find(r => /Permissions|Anumati|अनुमति/.test(r.innerText));
 if (!row) return { err: 'no Permissions row', look };
 row.click(); await w(1500);
 const sheet = document.getElementById('perm-sheet');
 const rows = [...sheet.querySelectorAll('.perm-row')].map(r => r.innerText.replace(/\s+/g, ' ').trim()).filter(t => /cloud|Google|off|band|copy/i.test(t));
 const btn = sheet.querySelector('[data-act="whenoff-set"]');
 if (btn) btn.scrollIntoView({ block: 'center' });
 await w(400);
 let drive = {};
 try { drive = JSON.parse(window.AndroidBridge && AndroidBridge.driveStatus ? AndroidBridge.driveStatus() : '{}'); } catch (e) { }
 return { look, rows, hasButton: !!btn, signInButton: !!sheet.querySelector('[data-act="drive-add"]'),
   googleKey: drive.available, accounts: (drive.accounts || []).length, errors };
})()

(async () => { const w = ms => new Promise(r => setTimeout(r, ms));
 for (let i = 0; i < 4; i++) { if (document.querySelector('.as-page.active') && window.onAndroidBack) { window.onAndroidBack(); await w(250); } }
 const look = localStorage.getItem('cloudssd_look');
 document.getElementById('nav-more').click(); await w(500);
 const row = [...document.querySelectorAll('#tab-more .more-row')].find(r => r.querySelector('.more-row-sub') && /Hinglish|English|Hindi/.test(r.innerText));
 if (!row) return { err: 'no Look and language row' };
 row.click(); await w(900);
 const picker = document.querySelector('#customize-modal .icon-picker');
 if (!picker) return { err: 'no icon picker' };
 picker.scrollIntoView({ block: 'center' }); await w(500);
 const cards = [...picker.querySelectorAll('.icon-card')].map(c => { const img = c.querySelector('img');
   return c.dataset.icon + (c.classList.contains('active') ? '*' : '') + ' ' + (img ? img.getAttribute('src') + ' ' + img.naturalWidth + 'x' + img.naturalHeight : 'no img'); });
 const bad = [...document.querySelectorAll('img')].filter(i => i.complete && !i.naturalWidth && i.getAttribute('src')).map(i => i.getAttribute('src'));
 return { look, shown: document.documentElement.dataset.look, native: window.CloudSSD && CloudSSD.appIcon ? CloudSSD.appIcon() : 'no bridge', cards, bad };
})()

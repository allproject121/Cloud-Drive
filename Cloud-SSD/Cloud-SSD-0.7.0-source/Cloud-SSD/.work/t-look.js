(async () => { const w = ms => new Promise(r => setTimeout(r, ms));
 const look = '__LOOK__';
 for (let i = 0; i < 4; i++) { if (document.querySelector('.as-page.active') && window.onAndroidBack) { window.onAndroidBack(); await w(250); } }
 const before = localStorage.getItem('cloudssd_look');
 document.getElementById('nav-more').click(); await w(500);
 const row = [...document.querySelectorAll('#tab-more .more-row')].find(r => r.querySelector('.more-row-sub') && /Hinglish|English|Hindi/.test(r.innerText));
 if (!row) return { err: 'no Look and language row' };
 row.click(); await w(800);
 const card = document.querySelector('#customize-modal [data-act="look"][data-look="' + look + '"]');
 if (!card) return { err: 'no card ' + look };
 card.click(); await w(700);
 if (window.onAndroidBack) window.onAndroidBack(); await w(400);
 document.getElementById('nav-home').click(); await w(1200); window.scrollTo(0, 0); await w(300);
 const cards = [...document.querySelectorAll('#nl-home .nl-store')].map(c => { const r = c.getBoundingClientRect(); const t = id => (c.querySelector('.' + id) || {}).textContent || '';
   return c.dataset.nlOpen + ' ' + Math.round(r.width) + 'x' + Math.round(r.height) + ' [' + t('nl-store-big') + '|' + t('nl-store-word') + '|' + t('nl-store-sub') + '|' + ((c.querySelector('.nl-ring b') || {}).textContent) + ']'; });
 return { before, saved: localStorage.getItem('cloudssd_look'), shown: document.documentElement.dataset.look, width: document.documentElement.scrollWidth, cards };
})()

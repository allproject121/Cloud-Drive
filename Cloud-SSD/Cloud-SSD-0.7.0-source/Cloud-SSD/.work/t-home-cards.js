(async () => { const w = ms => new Promise(r => setTimeout(r, ms));
 for (let i = 0; i < 4; i++) { if (document.querySelector('.as-page.active') && window.onAndroidBack) { window.onAndroidBack(); await w(250); } }
 document.getElementById('nav-home').click(); await w(1200); window.scrollTo(0, 0); await w(300);
 const cards = [...document.querySelectorAll('#nl-home .nl-store')].map(c => {
   const r = c.getBoundingClientRect();
   const t = id => (c.querySelector('.' + id) || {}).textContent || '';
   return { key: c.dataset.nlOpen, w: Math.round(r.width), h: Math.round(r.height), label: t('nl-store-label'), big: t('nl-store-big'), word: t('nl-store-word'), sub: t('nl-store-sub'),
     bar: (c.querySelector('.nl-store-bar i') || { style: {} }).style.width, pct: (c.querySelector('.nl-ring b') || {}).textContent };
 });
 return { look: document.documentElement.dataset.look, glass: document.documentElement.dataset.glass, chips: document.querySelectorAll('.nl-chip').length, width: document.documentElement.scrollWidth, cards };
})()

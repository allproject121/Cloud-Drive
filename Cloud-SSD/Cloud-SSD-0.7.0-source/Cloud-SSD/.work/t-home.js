(async () => { const w = ms => new Promise(r => setTimeout(r, ms));
 for (let i = 0; i < 4; i++) { if (document.querySelector('.as-page.active') && window.onAndroidBack) { window.onAndroidBack(); await w(250); } }
 document.getElementById('nav-home').click(); await w(600); window.scrollTo(0, 0);
 return { look: localStorage.getItem('cloudssd_look'), page: !!document.querySelector('.as-page.active') };
})()

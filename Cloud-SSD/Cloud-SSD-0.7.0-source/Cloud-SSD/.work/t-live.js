(async () => { const e = document.querySelector('.nl-head-live'); const s = getComputedStyle(e);
 return { look: document.documentElement.dataset.look, underline: s.textDecorationLine, text: e.innerText.trim(), labels: [...document.querySelectorAll('#nl-home .hw-group-title')].map(x => x.textContent), head: document.querySelector('#nl-home .section-title').textContent, send: (document.querySelector('.nl-send-sec .section-title') || {}).textContent, sendShown: !!(document.querySelector('.nl-send-sec .section-header') || {}).offsetParent };
})()

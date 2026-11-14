// Who wrote a given file name into this session's transcript? Prints only metadata of the matching lines.
const fs = require('fs');
const file = process.argv[2], word = process.argv[3];
const lines = fs.readFileSync(file, 'utf8').split('\n');
let n = 0;
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  if (!l.includes(word)) continue;
  let o; try { o = JSON.parse(l); } catch (e) { continue; }
  const c = o.message && Array.isArray(o.message.content) ? o.message.content.map(x => x.type + (x.name ? ':' + x.name : '')).join(',') : typeof (o.message && o.message.content);
  console.log(i, o.timestamp, o.type, 'side=' + o.isSidechain, 'agent=' + (o.agentId || ''), 'ver=' + (o.version || ''), 'cwd=' + String(o.cwd || '').slice(-40), 'entry=' + (o.entrypoint || o.userType || ''), c);
  if (++n > 12) break;
}
console.log('lines', lines.length);

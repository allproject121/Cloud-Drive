// The last entries of this session's transcript: time, cwd tail, and the start of what was said or run.
const fs = require('fs');
const lines = fs.readFileSync(process.argv[2], 'utf8').split('\n');
const from = Math.max(0, lines.length - Number(process.argv[3] || 60));
for (let i = from; i < lines.length; i++) {
  let o; try { o = JSON.parse(lines[i]); } catch (e) { continue; }
  if (o.type !== 'assistant' || !o.message || !Array.isArray(o.message.content)) continue;
  for (const x of o.message.content) {
    let t = '';
    if (x.type === 'text') t = 'SAYS ' + x.text;
    else if (x.type === 'tool_use') t = 'RUNS ' + x.name + ' ' + (x.input.description || x.input.file_path || x.input.pattern || '');
    else continue;
    console.log(String(o.timestamp).slice(11, 19), String(o.cwd || '').slice(-22), '|', t.replace(/\s+/g, ' ').slice(0, 170));
  }
}

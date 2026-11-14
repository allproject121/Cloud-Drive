const fs = require('fs');
const p = 'mobile-android/src/main/java/com/cloudssd/mobile/DriveBackend.java';
let s = fs.readFileSync(p, 'utf8');
const crlf = s.includes('\r\n'); if (crlf) s = s.replace(/\r\n/g, '\n');
const swaps = [
  ['import java.util.Collections;\n', 'import java.util.Collections;\nimport java.util.HashMap;\n'],
  ['            } catch (BackendException e) {\n                throw e;\n            } catch (IOException ignored) {\n                // one account not answering does not hide the others',
   '            } catch (IOException ignored) {\n                // one account not answering (or asking to sign in again) does not hide the others']
];
for (const [a, b] of swaps) { if (s.split(a).length !== 2) { console.log('NOT ONCE', a.slice(0, 60)); process.exit(1); } s = s.replace(a, () => b); }
fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s); console.log('ok');

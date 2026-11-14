// Three small things from the other window's review of the phone code (see CHALU_KAAM.md): a copy offers no "new here",
// a search asks Google for more when PCs keep copies, and a changed Google key asks to sign in again.
const fs = require('fs');
function patch(p, swaps) {
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n'); if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) { if (s.split(a).length !== 2) { console.log(p + ' NOT ONCE: ' + a.slice(0, 70)); process.exit(1); } s = s.replace(a, () => b); }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s); console.log('ok', p);
}
const J = 'mobile-android/src/main/java/com/cloudssd/mobile/';
patch(J + 'DriveBackend.java', [
  ['        d.canCreate = d.dir && (caps == null || caps.optBoolean("canAddChildren", true));',
   '        d.canCreate = editable && d.dir && (caps == null || caps.optBoolean("canAddChildren", true));'],
  ['        boolean copy = isCopy(d);\n        for (Place p : places(UNION.equalsIgnoreCase(d) ? UNION + ":" : copy ? d + ":" : folderId)) {',
   '        boolean copy = isCopy(d);\n        // Google answers for the whole account; what lies in (or outside) a PC\'s copy is dropped below, so ask for more.\n        int ask = WhenOffStore.pcs(ctx).isEmpty() ? max : max * 3;\n        for (Place p : places(UNION.equalsIgnoreCase(d) ? UNION + ":" : copy ? d + ":" : folderId)) {'],
  ['            for (JSONObject m : DriveApi.query(token, q.toString(), max)) {', '            for (JSONObject m : DriveApi.query(token, q.toString(), ask)) {']
]);
patch(J + 'GoogleAuth.java', [
  ['            if (e.body.contains("invalid_grant")) {',
   '            // The access ended, or it was given to another Google key than the one in use now (the PC handed over a new one).\n            if (e.body.contains("invalid_grant") || e.body.contains("unauthorized_client") || e.body.contains("invalid_client")) {']
]);

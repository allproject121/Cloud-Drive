// Phase 3, phone: the PC's copy in the cloud as a read-only drive "pc-<pcId>" in DriveBackend; the folder
// "Cloud-SSD Devices" is hidden everywhere else; bridge calls for the page. Run: node .work\p3-drive.js <repo>
const fs = require('fs');
const repo = process.argv[2];
function patch(rel, swaps) {
  const p = repo + '/' + rel;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b] of swaps) {
    const n = s.split(a).length - 1;
    if (n !== 1) { console.log(rel + ' NOT ONCE (' + n + '): ' + a.slice(0, 90)); process.exit(1); }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
  console.log('ok', rel);
}
const J = 'mobile-android/src/main/java/com/cloudssd/mobile/';

patch(J + 'DriveBackend.java', [
  [`    static final String EACH = "accounts";
`,
`    static final String EACH = "accounts";
    /** "pc-<pcId>": the copy a PC keeps of its own files ("Files when it is off"); read only. */
    static final String COPY = "pc-";
    /** Where every device keeps its copy. Hidden on the other drives: it is opened only through "pc-…". */
    static final String MIRROR_FOLDER = "Cloud-SSD Devices";
`],
  [`    /** Every account the id could live in (all of them for "All Accounts", the one for "Each Account"). */
    private List<Place> places(String id) throws BackendException {
        String d = drive(id), r = rel(id);
        List<Place> out = new ArrayList<>();
        if (UNION.equalsIgnoreCase(d)) {
            for (JSONObject a : byFreeSpace()) out.add(new Place(a, r));
        } else if (EACH.equalsIgnoreCase(d)) {
            if (r.isEmpty()) return out;
            int slash = r.indexOf('/');
            String folder = slash < 0 ? r : r.substring(0, slash);
            out.add(new Place(accountForFolder(folder), slash < 0 ? "" : r.substring(slash + 1)));
        } else throw new BackendException(404, "Unknown drive.");
        return out;
    }
`,
`    private static boolean isCopy(String drive) {
        return drive.toLowerCase(Locale.ROOT).startsWith(COPY);
    }

    /** The devices' copies, seen from "All Accounts" or an account's folder: not shown and not reachable there. */
    private static boolean hidden(String path) {
        String p = path.toLowerCase(Locale.ROOT), f = MIRROR_FOLDER.toLowerCase(Locale.ROOT);
        return p.equals(f) || p.startsWith(f + "/");
    }

    /** pcId → {email, path of its "files" folder, found at}. */
    private static final Map<String, String[]> copyCache = Collections.synchronizedMap(new HashMap<String, String[]>());

    /**
     * Where a PC keeps its copy: "Cloud-SSD Devices/<pcId> <name>/files" in the one account that has it. Only for a PC
     * this phone may read while it is off ({@link WhenOffStore}).
     */
    private Place copyBase(String pcId) throws IOException {
        if (!WhenOffStore.has(ctx, pcId)) throw new BackendException(403, "\\"Files when it is off\\" is not switched on for this PC.");
        List<JSONObject> accs = accounts();
        String[] hit = copyCache.get(pcId);
        if (hit != null && SystemClock.elapsedRealtime() - Long.parseLong(hit[2]) < 10 * 60_000L)
            for (JSONObject a : accs) if (a.optString("email").equals(hit[0])) return new Place(a, hit[1]);
        for (JSONObject a : accs) {
            String email = a.optString("email");
            try {
                JSONObject top = find(email, MIRROR_FOLDER);
                if (top == null || !isFolder(top)) continue;
                for (JSONObject m : DriveApi.children(token(email), top.optString("id"))) {
                    String name = nameOf(m);
                    if (!isFolder(m) || !(name.equals(pcId) || name.startsWith(pcId + " "))) continue;
                    String path = MIRROR_FOLDER + "/" + name + "/files";
                    copyCache.put(pcId, new String[]{email, path, String.valueOf(SystemClock.elapsedRealtime())});
                    return new Place(a, path);
                }
            } catch (BackendException e) {
                throw e;
            } catch (IOException ignored) {
                // one account not answering does not hide the others
            }
        }
        throw new BackendException(404, "No copy of this PC is on Google Drive yet, or its Google account is not signed in on this phone.");
    }

    /**
     * What the PC wrote about its copy ({account, device: device.json}): when it last copied and how much is up.
     * "device" is missing while the PC has not finished a first pass.
     */
    JSONObject copyInfo(String pcId) throws IOException {
        Place base = copyBase(pcId);
        String folder = base.path.substring(0, base.path.length() - "/files".length());
        JSONObject out = new JSONObject();
        try {
            out.put("account", base.email()).put("name", WhenOffStore.name(ctx, pcId));
            JSONObject m = find(base.email(), folder + "/device.json");
            if (m != null && !isFolder(m)) {
                try (InputStream in = DriveApi.read(token(base.email()), m.optString("id"), null, 0)) {
                    out.put("device", new JSONObject(DriveApi.readAll(in)));
                }
            }
        } catch (JSONException ignored) {
            // a damaged state file: the copy itself still opens
        }
        return out;
    }

    /** Every account the id could live in (all of them for "All Accounts", the one for "Each Account" or a PC's copy). */
    private List<Place> places(String id) throws IOException {
        String d = drive(id), r = rel(id);
        List<Place> out = new ArrayList<>();
        if (UNION.equalsIgnoreCase(d)) {
            if (hidden(r)) throw new BackendException(404, "Not found on Google Drive.");
            for (JSONObject a : byFreeSpace()) out.add(new Place(a, r));
        } else if (EACH.equalsIgnoreCase(d)) {
            if (r.isEmpty()) return out;
            int slash = r.indexOf('/');
            String folder = slash < 0 ? r : r.substring(0, slash);
            String below = slash < 0 ? "" : r.substring(slash + 1);
            if (hidden(below)) throw new BackendException(404, "Not found on Google Drive.");
            out.add(new Place(accountForFolder(folder), below));
        } else if (isCopy(d)) {
            Place base = copyBase(d.substring(COPY.length()));
            out.add(new Place(base.account, r.isEmpty() ? base.path : base.path + "/" + r));
        } else throw new BackendException(404, "Unknown drive.");
        return out;
    }
`],
  [`        each.freeBytes = all.freeBytes;
        roots.add(each);
        return roots;`,
`        each.freeBytes = all.freeBytes;
        roots.add(each);
        // A PC that is switched off: the copy it keeps of its own files, when this phone may read it and it is there.
        for (String[] pc : WhenOffStore.pcs(ctx)) {
            try {
                copyBase(pc[0]);
            } catch (IOException e) {
                continue;   // no copy yet, or its account is not signed in here
            }
            RootInfo copy = new RootInfo();
            copy.id = COPY + pc[0];
            copy.title = pc[1] + " (cloud copy)";
            copy.readOnly = true;
            copy.canCreate = false;
            roots.add(copy);
        }
        return roots;`],
  [`        Map<String, DocInfo> merged = new LinkedHashMap<>();
        boolean found = false;
        for (Place p : places(folderId)) {
            JSONObject folder = find(p.email(), p.path);
            if (folder == null || !isFolder(folder)) continue;
            found = true;
            for (JSONObject m : DriveApi.children(token(p.email()), folder.optString("id"))) {
                if (!listable(m)) continue;
                String name = nameOf(m);
                if (merged.containsKey(name.toLowerCase(Locale.ROOT))) continue;   // folders merge by name; for files the first account wins
                merged.put(name.toLowerCase(Locale.ROOT), doc(childId(folderId, name), m, true));`,
`        Map<String, DocInfo> merged = new LinkedHashMap<>();
        boolean found = false, copy = isCopy(d);
        for (Place p : places(folderId)) {
            JSONObject folder = find(p.email(), p.path);
            if (folder == null || !isFolder(folder)) continue;
            found = true;
            for (JSONObject m : DriveApi.children(token(p.email()), folder.optString("id"))) {
                if (!listable(m)) continue;
                String name = nameOf(m);
                if (!copy && p.path.isEmpty() && name.equalsIgnoreCase(MIRROR_FOLDER)) continue;   // the devices' copies: only through "pc-…"
                if (merged.containsKey(name.toLowerCase(Locale.ROOT))) continue;   // folders merge by name; for files the first account wins
                merged.put(name.toLowerCase(Locale.ROOT), doc(childId(folderId, name), m, !copy));`],
  [`        if (!found) throw new BackendException(404, "Folder not found on Google Drive.");`,
   `        if (!found) throw new BackendException(404, copy && r.isEmpty() ? "The PC has not copied anything yet." : "Folder not found on Google Drive.");`],
  [`    public DocInfo stat(String id) throws IOException {
        String d = drive(id), r = rel(id);
`,
`    public DocInfo stat(String id) throws IOException {
        String d = drive(id), r = rel(id);
        if (isCopy(d) && r.isEmpty()) {
            copyBase(d.substring(COPY.length()));
            DocInfo root = new DocInfo();
            root.id = id;
            root.name = WhenOffStore.name(ctx, d.substring(COPY.length())) + " (cloud copy)";
            root.dir = true;
            return root;
        }
`],
  [`            JSONObject m = find(p.email(), p.path);
            if (m != null) return doc(id, m, true);
        }
        throw new BackendException(404, "Not found on Google Drive.");`,
`            JSONObject m = find(p.email(), p.path);
            if (m != null) return doc(id, m, !isCopy(d));
        }
        throw new BackendException(404, "Not found on Google Drive.");`],
  [`        String d = drive(folderId);
        for (Place p : places(UNION.equalsIgnoreCase(d) ? UNION + ":" : folderId)) {
            String token = token(p.email());
            String base = EACH.equalsIgnoreCase(d) ? EACH + ":" + p.account.optString("folder") : UNION + ":";
            for (JSONObject m : DriveApi.query(token, q.toString(), max)) {
                if (!listable(m)) continue;
                String path = pathOf(token, m);
                if (path == null) continue;   // not in My Drive (shared with me, other drives)
                String id = childId(base, path);
                if (!id.toLowerCase(Locale.ROOT).startsWith(folderId.toLowerCase(Locale.ROOT).replaceAll("/$", ""))) continue;
                out.add(doc(id, m, true));`,
`        String d = drive(folderId);
        boolean copy = isCopy(d);
        for (Place p : places(UNION.equalsIgnoreCase(d) ? UNION + ":" : copy ? d + ":" : folderId)) {
            String token = token(p.email());
            String base = EACH.equalsIgnoreCase(d) ? EACH + ":" + p.account.optString("folder") : copy ? d + ":" : UNION + ":";
            for (JSONObject m : DriveApi.query(token, q.toString(), max)) {
                if (!listable(m)) continue;
                String path = pathOf(token, m);
                if (path == null) continue;   // not in My Drive (shared with me, other drives)
                if (copy) {
                    if (!path.startsWith(p.path + "/")) continue;   // only what is inside this PC's copy
                    path = path.substring(p.path.length() + 1);
                } else if (hidden(path)) continue;                  // the devices' copies are found only from "pc-…"
                String id = childId(base, path);
                if (!id.toLowerCase(Locale.ROOT).startsWith(folderId.toLowerCase(Locale.ROOT).replaceAll("/$", ""))) continue;
                out.add(doc(id, m, !copy));`],
  [`    public DocInfo create(String parentId, String name, boolean dir) throws IOException {
        Place p = placeForNew(parentId);`,
`    public DocInfo create(String parentId, String name, boolean dir) throws IOException {
        if (isCopy(drive(parentId))) throw new BackendException(403, "A PC's cloud copy can only be read.");
        Place p = placeForNew(parentId);`],
  [`    private static void requireEditable(String id) throws BackendException {
        String d = drive(id), r = rel(id);
`,
`    private static void requireEditable(String id) throws BackendException {
        String d = drive(id), r = rel(id);
        if (isCopy(d)) throw new BackendException(403, "A PC's cloud copy can only be read.");
`]
]);

patch(J + 'MainActivity.java', [
  [`        public void setDriveDirect(boolean on) {
            getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean("drive_direct", on).apply();
            CloudDocumentsProvider.notifyRootsChanged(MainActivity.this);
        }
`,
`        public void setDriveDirect(boolean on) {
            getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean("drive_direct", on).apply();
            CloudDocumentsProvider.notifyRootsChanged(MainActivity.this);
        }

        /**
         * "Files when it is off": the page tells how this phone and a PC stand (both said yes or not), so the PC's copy
         * in the cloud can be opened while the PC cannot be asked. active = false forgets the PC.
         */
        @JavascriptInterface
        public void whenOffSync(String pcId, String name, boolean active) {
            if (WhenOffStore.set(MainActivity.this, pcId, name, active)) CloudDocumentsProvider.notifyRootsChanged(MainActivity.this);
        }

        /** The Google key a PC handed over for this phone's own sign-in (never a sign-in itself). True when it is new. */
        @JavascriptInterface
        public boolean setGoogleKey(String clientId, String clientSecret) {
            boolean fresh = GoogleAuth.setKey(MainActivity.this, clientId, clientSecret);
            if (fresh) CloudDocumentsProvider.notifyRootsChanged(MainActivity.this);
            return fresh;
        }
`],
  [`                case "delete": b.delete(a.getString("path")); data = new JSONObject().put("success", true); break;
                default: throw new BackendException(400, "Unknown operation " + op);`,
`                case "delete": b.delete(a.getString("path")); data = new JSONObject().put("success", true); break;
                // A PC's copy in the cloud: where it is and what the PC last wrote about it. Always from Google Drive.
                case "copy-info": data = new DriveBackend(this).copyInfo(a.getString("pc")); break;
                default: throw new BackendException(400, "Unknown operation " + op);`]
]);

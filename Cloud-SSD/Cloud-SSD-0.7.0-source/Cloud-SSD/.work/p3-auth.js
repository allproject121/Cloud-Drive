// Phase 3, phone: the Google key may come from the PC while the app runs (not only from the build), and signing out
// no longer asks Google to revoke (the PC signs in with the same key). Run: node .work\p3-auth.js <repo>
const fs = require('fs');
const repo = process.argv[2];
function patch(rel, swaps) {
  const p = repo + '/' + rel;
  let s = fs.readFileSync(p, 'utf8');
  const crlf = s.includes('\r\n');
  if (crlf) s = s.replace(/\r\n/g, '\n');
  for (const [a, b, all] of swaps) {
    const n = s.split(a).length - 1;
    if (all ? n < 1 : n !== 1) { console.log(rel + ' NOT ' + (all ? 'FOUND' : 'ONCE') + ' (' + n + '): ' + a.slice(0, 90)); process.exit(1); }
    s = all ? s.split(a).join(b) : s.replace(a, () => b);
  }
  fs.writeFileSync(p, crlf ? s.replace(/\n/g, '\r\n') : s);
  console.log('ok', rel);
}
const J = 'mobile-android/src/main/java/com/cloudssd/mobile/';

patch(J + 'GoogleAuth.java', [
  [` * put on Drive are visible. Two kinds of Google key are supported, chosen when the app is built:
 * an iOS client (redirect into the app by its reversed client id) or a Desktop client (redirect to this phone's own
 * 127.0.0.1, then back into the app). The refresh key is kept encrypted ({@link TokenStore}); access keys only in memory.
 */`,
` * put on Drive are visible. Two kinds of Google key are supported: an iOS client (redirect into the app by its
 * reversed client id, only when the app was built with one) or a Desktop client (redirect to this phone's own
 * 127.0.0.1, then back into the app). The key comes from the build, or — for "Files when it is off" — from the PC,
 * which hands over its own Google key ({@link #setKey}); never a sign-in. The refresh key is kept encrypted
 * ({@link TokenStore}); access keys only in memory.
 */`],
  [`    private static final String REVOKE_URL = "https://oauth2.googleapis.com/revoke";\n`, ``],
  [`    static boolean available() {
        return !GoogleConfig.CLIENT_ID.isEmpty();
    }

    private static boolean desktop() {
        return "desktop".equals(GoogleConfig.MODE);
    }

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
`,
`    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    // ---- the Google key --------------------------------------------------------------------------------------------

    /** The key the PC handed over: {client id, client secret}; read once, then kept in memory. */
    private static volatile String[] fromPc;

    private static String[] pcKey(Context c) {
        String[] k = fromPc;
        if (k == null) {
            SharedPreferences p = prefs(c);
            fromPc = k = new String[]{TokenStore.get(p, "ck_id"), TokenStore.get(p, "ck_secret")};
        }
        return k;
    }

    /** The app was built with a Google key: that one is used, whatever a PC hands over. */
    private static boolean built() {
        return !GoogleConfig.CLIENT_ID.isEmpty();
    }

    /**
     * Keeps the Google key a PC handed over (its own key, for "Files when it is off"). True when it is new. Sign-ins
     * made with another key stop working at Google and ask to sign in again by themselves.
     */
    static synchronized boolean setKey(Context c, String clientId, String clientSecret) {
        String id = clientId == null ? "" : clientId.trim(), secret = clientSecret == null ? "" : clientSecret.trim();
        if (id.isEmpty()) return false;
        String[] old = pcKey(c);
        if (id.equals(old[0]) && secret.equals(old[1])) return false;
        SharedPreferences p = prefs(c);
        TokenStore.put(p, "ck_id", id);
        TokenStore.put(p, "ck_secret", secret);
        fromPc = new String[]{id, secret};
        if (!built()) synchronized (access) {
            access.clear();
        }
        return true;
    }

    static boolean available(Context c) {
        return built() || !pcKey(c)[0].isEmpty();
    }

    private static String clientId(Context c) {
        return built() ? GoogleConfig.CLIENT_ID : pcKey(c)[0];
    }

    private static String clientSecret(Context c) {
        return built() ? GoogleConfig.CLIENT_SECRET : pcKey(c)[1];
    }

    /** A PC's key is always a Desktop one. */
    private static boolean desktop(Context c) {
        return built() ? "desktop".equals(GoogleConfig.MODE) : true;
    }
`],
  [`    static void signOut(final Context c, final String email) {
        final String rt = TokenStore.get(prefs(c), "rt_" + email);
        synchronized (GoogleAuth.class) {`,
`    /**
     * Forgets the account on this phone. Google is not asked to revoke: that ends the access of everything signed in
     * with the same key for this account, and the PC uses that key too.
     */
    static void signOut(final Context c, final String email) {
        synchronized (GoogleAuth.class) {`],
  [`            access.remove(email);
        }
        if (!rt.isEmpty()) new Thread(() -> {
            try {
                post(REVOKE_URL, "token=" + enc(rt));
            } catch (IOException ignored) {
            }
        }).start();
    }`,
`        }
        synchronized (access) {
            access.remove(email);
        }
    }`],
  [`    private static String redirectUri(int port) {
        return desktop() ? "http://127.0.0.1:" + port : GoogleConfig.REDIRECT;
    }`,
`    private static String redirectUri(Context c, int port) {
        return desktop(c) ? "http://127.0.0.1:" + port : GoogleConfig.REDIRECT;
    }`],
  [`        if (!available()) throw new IOException("This build of the app has no Google key. See SETUP.md (\\"Phone without the PC\\").");`,
   `        if (!available(a)) throw new IOException("This phone has no Google key yet. Switch on \\"Files when it is off\\" with a PC that uses its own Google key.");`],
  [`        if (desktop()) {
            stopLoopback();`,
`        if (desktop(a)) {
            stopLoopback();`],
  [`"?response_type=code&client_id=" + enc(GoogleConfig.CLIENT_ID) + "&redirect_uri=" + enc(redirectUri(port))`,
   `"?response_type=code&client_id=" + enc(clientId(a)) + "&redirect_uri=" + enc(redirectUri(a, port))`],
  [`                    + "&client_id=" + enc(GoogleConfig.CLIENT_ID) + "&redirect_uri=" + enc(redirectUri(port))
                    + (GoogleConfig.CLIENT_SECRET.isEmpty() ? "" : "&client_secret=" + enc(GoogleConfig.CLIENT_SECRET));`,
`                    + "&client_id=" + enc(clientId(c)) + "&redirect_uri=" + enc(redirectUri(c, port))
                    + (clientSecret(c).isEmpty() ? "" : "&client_secret=" + enc(clientSecret(c)));`],
  [`        String body = "grant_type=refresh_token&refresh_token=" + enc(rt) + "&client_id=" + enc(GoogleConfig.CLIENT_ID)
                + (GoogleConfig.CLIENT_SECRET.isEmpty() ? "" : "&client_secret=" + enc(GoogleConfig.CLIENT_SECRET));`,
`        String body = "grant_type=refresh_token&refresh_token=" + enc(rt) + "&client_id=" + enc(clientId(c))
                + (clientSecret(c).isEmpty() ? "" : "&client_secret=" + enc(clientSecret(c)));`]
]);

patch(J + 'DriveBackend.java', [[`return GoogleAuth.available() && !accounts().isEmpty();`, `return GoogleAuth.available(ctx) && !accounts().isEmpty();`]]);
patch(J + 'MainActivity.java', [[`GoogleAuth.available()`, `GoogleAuth.available(MainActivity.this)`, true]]);

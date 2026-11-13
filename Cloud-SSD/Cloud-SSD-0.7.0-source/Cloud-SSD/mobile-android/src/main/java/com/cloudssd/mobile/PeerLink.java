package com.cloudssd.mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * The PC looking at this phone's files, only as far as this phone allows. The app keeps one long request open to the
 * PC in use (/api/peer/inbox) while it runs; the PC's questions (list a folder, send a file) come back on it and are
 * answered on /api/peer/result. Nothing is answered without this phone's own permission ({@link Grants}): a question
 * without it brings up a note here, and the PC is told to wait. Paths are checked to stay inside what was allowed
 * (the shared folders, or the whole phone storage).
 */
final class PeerLink {
    interface Listener {
        void onAsk(String pcId, String pcName);
    }

    private static final String TAG = "CloudSSD.Peer";
    static final String CHANNEL = "peer";
    static final int NOTE_ID = 7701;
    /** The folders "shared" lets the PC see. */
    static final String[] SHARED = {"DCIM", "Pictures", "Movies", "Music", "Download", "Documents"};
    private static final int MAX_ITEMS = 2000;

    private static PeerLink instance;

    static synchronized PeerLink get(Context c) {
        if (instance == null) instance = new PeerLink(c.getApplicationContext());
        return instance;
    }

    private final Context ctx;
    private final ExecutorService jobs = Executors.newFixedThreadPool(2);
    private volatile boolean running;
    private volatile Listener listener;
    private long lastAsk;
    /** Wakes the loop from its wait (see {@link #kick}). */
    private final Object wake = new Object();
    private volatile boolean kicked;
    /** The long request open now, so a kick can end it at once (another PC chosen, just paired or unblocked). */
    private volatile HttpURLConnection waiting;

    private PeerLink(Context c) {
        ctx = c;
    }

    void setListener(Listener l) {
        listener = l;
    }

    void start() {
        synchronized (this) {
            if (running) return;
            running = true;
        }
        Thread t = new Thread(this::loop, "cloudssd-peer");
        t.setDaemon(true);
        t.start();
    }

    /**
     * Something changed (paired, another PC chosen, back online after being blocked): start asking the PC now instead
     * of after the current wait (up to a minute after a failure).
     */
    void kick() {
        kicked = true;
        HttpURLConnection c = waiting;
        if (c != null) {
            try {
                c.disconnect();
            } catch (Exception ignored) {
            }
        }
        synchronized (wake) {
            wake.notifyAll();
        }
    }

    private void sleep(long ms) {
        synchronized (wake) {
            if (kicked) return;
            try {
                wake.wait(ms);
            } catch (InterruptedException ignored) {
            }
        }
    }

    /**
     * True while this phone should keep answering the PC with the app closed: "Find my phone" is on, or the PC in use
     * may look at this phone's files right now (its grant has not run out).
     */
    static boolean neededInBackground(Context c) {
        SharedPreferences p = c.getSharedPreferences("cloudssd", Context.MODE_PRIVATE);
        if (p.getBoolean("peer_paused", false)) return false;
        if (p.getBoolean("find_my_phone", false)) return true;
        String pc = PcProfiles.activeId(c);
        return pc != null && !pc.isEmpty() && Grants.get(c, pc) != null;
    }

    private void loop() {
        long backoff = 2000;
        while (running) {
            kicked = false;
            try {
                String pc = PcProfiles.activeId(ctx);
                SharedPreferences p = ctx.getSharedPreferences("cloudssd", Context.MODE_PRIVATE);
                String token = TokenStore.pcToken(ctx);
                // A grant that ran out (or Find my phone switched off) ends the background service. (Starting it is
                // left to the app, the note's buttons and boot: Android does not let a background thread start one.)
                PeerLinkService.stopIfNotNeeded(ctx);
                if (pc == null || pc.isEmpty() || token.isEmpty() || !p.getString("features", "[]").contains("\"peer\"")) {
                    sleep(20000);
                    continue;
                }
                String server = PcLink.resolve(ctx);
                if (server.isEmpty()) {
                    backoff = Math.min(backoff * 2, 60000);
                    sleep(backoff);
                    continue;
                }
                JSONObject r = new JSONObject(waitForJob(server + "/api/peer/inbox?wait=25" + vitals(), token));
                backoff = 2000;
                final JSONObject job = r.optJSONObject("job");
                if (job != null) {
                    final String s = server, pcId = pc;
                    jobs.execute(() -> handle(s, token, pcId, job));
                }
            } catch (Exception e) {
                if (kicked) {
                    backoff = 2000;   // ended on purpose: ask again right away
                    continue;
                }
                backoff = Math.min(backoff * 2, 60000);
                sleep(backoff);
            }
        }
    }

    /** The long wait for the PC's next question; {@link #kick} can end it. */
    private String waitForJob(String url, String token) throws IOException {
        HttpURLConnection c = open(url, token, "GET", 35000);
        waiting = c;
        try {
            int code = c.getResponseCode();
            InputStream in = code >= 400 ? c.getErrorStream() : c.getInputStream();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            if (in != null) try (InputStream i = in) {
                byte[] buf = new byte[8192];
                for (int n; (n = i.read(buf)) > 0; ) out.write(buf, 0, n);
            }
            if (code >= 400) throw new IOException("PC answered HTTP " + code);
            return out.toString("UTF-8");
        } finally {
            waiting = null;
            c.disconnect();
        }
    }

    // ---- answering -----------------------------------------------------------------------------------------------------

    private void handle(String server, String token, String pc, JSONObject job) {
        String id = job.optString("id");
        String kind = job.optString("kind");
        JSONObject args = job.optJSONObject("args");
        String path = args == null ? "" : args.optString("path", "");
        try {
            // Ringing and the clipboard need no file permission: anything the paired PC may do anyway, and seen here.
            if ("phone.ring".equals(kind)) {
                PhoneRinger.ring(ctx, args == null ? "" : args.optString("from", ""));
                answerJson(server, token, id, new JSONObject().put("ok", true));
                return;
            }
            if ("clip.set".equals(kind)) {
                final String text = args == null ? "" : args.optString("text", "");
                final String from = args == null || args.optString("from", "").isEmpty() ? Tr.t(ctx, "the PC") : args.optString("from", "");
                new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
                    android.content.ClipboardManager cm = (android.content.ClipboardManager) ctx.getSystemService(Context.CLIPBOARD_SERVICE);
                    if (cm != null) cm.setPrimaryClip(android.content.ClipData.newPlainText("Cloud-SSD", text));
                    android.widget.Toast.makeText(ctx, Tr.t(ctx, "Clipboard from {0}", from), android.widget.Toast.LENGTH_SHORT).show();
                });
                answerJson(server, token, id, new JSONObject().put("ok", true));
                return;
            }
            Grants.Grant g = Grants.get(ctx, pc);
            if (g == null) {
                // Through the PC, another of its devices (a laptop) may be the one asking: say who.
                ask(pc, args == null ? "" : args.optString("asker", ""));
                answer(server, token, id, "needs-permission", null);
                return;
            }
            switch (kind) {
                case "fs.roots":
                    answerJson(server, token, id, roots(g));
                    break;
                case "fs.list": {
                    File dir = resolve(g, path);
                    if (dir == null || !dir.isDirectory()) answer(server, token, id, "denied", "Not allowed or not there: " + path);
                    else answerJson(server, token, id, list(dir));
                    break;
                }
                case "fs.read": {
                    File f = resolve(g, path);
                    if (f == null || !f.isFile()) answer(server, token, id, "denied", "Not allowed or not there: " + path);
                    else answerFile(server, token, id, f);
                    break;
                }
                default:
                    answer(server, token, id, "error", "This phone does not know " + kind);
            }
        } catch (Exception e) {
            Log.w(TAG, "peer job failed", e);
            try {
                answer(server, token, id, "error", String.valueOf(e.getMessage()));
            } catch (Exception ignored) {
            }
        }
    }

    /** "&battery=83&charging=1&free=…&total=…": shown on the phone's card on the PC. */
    private String vitals() {
        StringBuilder sb = new StringBuilder();
        try {
            android.content.Intent b = ctx.registerReceiver(null, new android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED));
            if (b != null) {
                int level = b.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1), scale = b.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1);
                int plugged = b.getIntExtra(android.os.BatteryManager.EXTRA_PLUGGED, 0);
                if (level >= 0 && scale > 0) sb.append("&battery=").append(Math.round(level * 100f / scale)).append("&charging=").append(plugged != 0 ? 1 : 0);
            }
            android.os.StatFs st = new android.os.StatFs(storageRoot().getPath());
            sb.append("&free=").append(st.getAvailableBytes()).append("&total=").append(st.getTotalBytes());
        } catch (Exception ignored) {
        }
        return sb.toString();
    }

    static File storageRoot() {
        return Environment.getExternalStorageDirectory();
    }

    /** The file or folder at a path relative to the phone storage, when the grant lets the PC see it; else null. */
    static File resolve(Grants.Grant g, String rel) {
        try {
            File root = storageRoot().getCanonicalFile();
            String clean = rel == null ? "" : rel.replace('\\', '/');
            while (clean.startsWith("/")) clean = clean.substring(1);
            File f = (clean.isEmpty() ? root : new File(root, clean)).getCanonicalFile();
            String rp = root.getPath(), fp = f.getPath();
            if (!fp.equals(rp) && !fp.startsWith(rp + File.separator)) return null;          // outside the phone storage
            String inside = fp.equals(rp) ? "" : fp.substring(rp.length() + 1);
            if (inside.startsWith("Android" + File.separator) || inside.equals("Android")) return null;   // other apps' data
            for (String part : inside.split(File.separator.equals("\\") ? "\\\\" : File.separator))
                if (part.startsWith(".")) return null;                                         // hidden files stay hidden
            if ("all".equals(g.scope)) return f;
            if (inside.isEmpty()) return null;                                                 // "shared": not the top itself
            String first = inside.split(File.separator.equals("\\") ? "\\\\" : File.separator)[0];
            for (String s : SHARED) if (s.equalsIgnoreCase(first)) return f;
            return null;
        } catch (IOException e) {
            return null;
        }
    }

    private static String relOf(File f) {
        String rp = storageRoot().getAbsolutePath();
        String fp = f.getAbsolutePath();
        return fp.length() > rp.length() ? fp.substring(rp.length() + 1).replace(File.separatorChar, '/') : "";
    }

    private static JSONObject roots(Grants.Grant g) throws JSONException {
        JSONArray roots = new JSONArray();
        if ("all".equals(g.scope)) roots.put(new JSONObject().put("name", "Phone storage").put("path", ""));
        else for (String s : SHARED) {
            File d = new File(storageRoot(), s);
            if (d.isDirectory()) roots.put(new JSONObject().put("name", s).put("path", s));
        }
        return new JSONObject().put("scope", g.scope).put("until", g.until).put("roots", roots);
    }

    private static JSONObject list(File dir) throws JSONException {
        JSONArray folders = new JSONArray(), files = new JSONArray();
        File[] items = dir.listFiles();
        boolean truncated = false;
        if (items != null) {
            Arrays.sort(items, (a, b) -> a.getName().compareToIgnoreCase(b.getName()));
            int n = 0;
            for (File f : items) {
                if (f.getName().startsWith(".")) continue;
                if (++n > MAX_ITEMS) {
                    truncated = true;
                    break;
                }
                JSONObject o = new JSONObject().put("name", f.getName()).put("path", relOf(f)).put("modified", f.lastModified());
                if (f.isDirectory()) {
                    String[] kids = f.list();
                    folders.put(o.put("count", kids == null ? 0 : kids.length));
                } else files.put(o.put("size", f.length()));
            }
        }
        return new JSONObject().put("path", relOf(dir)).put("folders", folders).put("files", files).put("truncated", truncated);
    }

    private static String enc(String s) {
        try {
            return URLEncoder.encode(s, "UTF-8").replace("+", "%20");
        } catch (Exception e) {
            return s;
        }
    }

    private void answer(String server, String token, String job, String status, String error) throws IOException {
        request(server + "/api/peer/result?job=" + enc(job) + "&status=" + enc(status) + (error == null ? "" : "&error=" + enc(error)),
                token, "POST", 30000, new byte[0], 0);
    }

    private void answerJson(String server, String token, String job, JSONObject o) throws IOException {
        byte[] body = o.toString().getBytes(StandardCharsets.UTF_8);
        request(server + "/api/peer/result?job=" + enc(job) + "&status=ok", token, "POST", 60000, body, body.length);
    }

    private void answerFile(String server, String token, String job, File f) throws IOException {
        HttpURLConnection c = open(server + "/api/peer/result?job=" + enc(job) + "&status=ok", token, "POST", 10 * 60 * 1000);
        try {
            c.setDoOutput(true);
            c.setRequestProperty("Content-Type", "application/octet-stream");
            c.setFixedLengthStreamingMode(f.length());
            try (InputStream in = new FileInputStream(f); OutputStream out = c.getOutputStream()) {
                byte[] buf = new byte[64 * 1024];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            }
            c.getResponseCode();
        } finally {
            c.disconnect();
        }
    }

    private static HttpURLConnection open(String url, String token, String method, int readMs) throws IOException {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setConnectTimeout(8000);
        c.setReadTimeout(readMs);
        c.setUseCaches(false);
        c.setRequestMethod(method);
        c.setRequestProperty("X-Pairing-Token", token);
        c.setRequestProperty("Connection", "close");
        return c;
    }

    private static String request(String url, String token, String method, int readMs, byte[] body, int length) throws IOException {
        HttpURLConnection c = open(url, token, method, readMs);
        try {
            if (body != null) {
                c.setDoOutput(true);
                c.setRequestProperty("Content-Type", "application/json");
                c.setFixedLengthStreamingMode(length);
                try (OutputStream out = c.getOutputStream()) {
                    out.write(body, 0, length);
                }
            }
            int code = c.getResponseCode();
            InputStream in = code >= 400 ? c.getErrorStream() : c.getInputStream();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            if (in != null) try (InputStream i = in) {
                byte[] buf = new byte[8192];
                for (int n; (n = i.read(buf)) > 0; ) out.write(buf, 0, n);
            }
            if (code >= 400) throw new IOException("PC answered HTTP " + code);
            return out.toString("UTF-8");
        } finally {
            c.disconnect();
        }
    }

    // ---- asking this phone's owner -----------------------------------------------------------------------------------

    /** Once a minute at most: the page (when open) and a note with Allow / Deny. */
    private void ask(String pc, String asker) {
        long now = System.currentTimeMillis();
        if (now - lastAsk < 60000) return;
        lastAsk = now;
        JSONObject rec = PcProfiles.get(ctx, pc);
        String name = rec == null ? "" : rec.optString("label", rec.optString("name", ""));
        if (name.isEmpty()) name = "Your PC";
        // Allowing it allows the PC (and so what it lets its laptops see), for the time chosen.
        if (asker != null && !asker.trim().isEmpty() && !asker.trim().equals(name)) name = asker.trim() + " via " + name;
        Listener l = listener;
        if (l != null) l.onAsk(pc, name);
        notifyAsk(pc, name);
    }

    private void notifyAsk(String pc, String name) {
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL) == null)
            nm.createNotificationChannel(new NotificationChannel(CHANNEL, "Requests from your PC", NotificationManager.IMPORTANCE_HIGH));
        Intent open = new Intent(ctx, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0);
        PendingIntent content = PendingIntent.getActivity(ctx, 0, open, flags);
        PendingIntent allow = PendingIntent.getBroadcast(ctx, 1, new Intent(ctx, PeerDecisionReceiver.class)
                .putExtra("pc", pc).putExtra("minutes", 60).putExtra("scope", "shared"), flags);
        PendingIntent deny = PendingIntent.getBroadcast(ctx, 2, new Intent(ctx, PeerDecisionReceiver.class)
                .putExtra("pc", pc).putExtra("minutes", -1), flags);
        Notification.Builder b = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(ctx, CHANNEL) : new Notification.Builder(ctx);
        b.setSmallIcon(android.R.drawable.ic_menu_view)
                .setContentTitle(Tr.t(ctx, "{0} wants to see this phone's files", name))
                .setContentText(Tr.t(ctx, "Allow only if you are at that PC. Photos, Downloads and Documents for 1 hour."))
                .setContentIntent(content)
                .setAutoCancel(true);
        Notification.Action.Builder allowAction = new Notification.Action.Builder(null, Tr.t(ctx, "Allow 1 hour"), allow);
        // Allowing needs the phone unlocked: someone holding a locked phone cannot open it up.
        if (Build.VERSION.SDK_INT >= 31) allowAction.setAuthenticationRequired(true);
        b.addAction(allowAction.build());
        b.addAction(new Notification.Action.Builder(null, Tr.t(ctx, "Deny"), deny).build());
        try {
            nm.notify(NOTE_ID, b.build());
        } catch (SecurityException ignored) {
            // Notifications not allowed: the page asks when the app is open.
        }
    }

    // ---- what this phone allows ----------------------------------------------------------------------------------------

    /** Per PC: what it may see (shared folders or the whole phone storage) and until when (0 = until taken back). */
    static final class Grants {
        static final class Grant {
            final String scope;
            final long until;

            Grant(String scope, long until) {
                this.scope = scope;
                this.until = until;
            }
        }

        private static String key(String pc) {
            return "peer_" + PcProfiles.key(pc);
        }

        static Grant get(Context c, String pc) {
            if (pc == null || pc.isEmpty()) return null;
            SharedPreferences p = c.getSharedPreferences("cloudssd", Context.MODE_PRIVATE);
            String raw = p.getString(key(pc), "");
            if (raw.isEmpty()) return null;
            try {
                JSONObject o = new JSONObject(raw);
                long until = o.optLong("until", 0);
                if (until > 0 && until < System.currentTimeMillis()) {
                    p.edit().remove(key(pc)).apply();
                    return null;
                }
                return new Grant("all".equals(o.optString("scope")) ? "all" : "shared", until);
            } catch (JSONException e) {
                return null;
            }
        }

        /** minutes 0 = until taken back. */
        static void set(Context c, String pc, String scope, int minutes) {
            try {
                long until = minutes > 0 ? System.currentTimeMillis() + minutes * 60_000L : 0;
                c.getSharedPreferences("cloudssd", Context.MODE_PRIVATE).edit()
                        .putString(key(pc), new JSONObject().put("scope", "all".equals(scope) ? "all" : "shared").put("until", until).toString()).apply();
            } catch (JSONException ignored) {
            }
        }

        static void clear(Context c, String pc) {
            c.getSharedPreferences("cloudssd", Context.MODE_PRIVATE).edit().remove(key(pc)).apply();
        }

        static JSONObject forPage(Context c, String pc) {
            JSONObject o = new JSONObject();
            Grant g = get(c, pc);
            try {
                if (g != null) o.put("scope", g.scope).put("until", g.until);
            } catch (JSONException ignored) {
            }
            return o;
        }
    }
}

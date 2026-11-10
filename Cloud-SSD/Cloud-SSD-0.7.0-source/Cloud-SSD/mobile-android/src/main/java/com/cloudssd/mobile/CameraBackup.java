package com.cloudssd.mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.content.ComponentName;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.SystemClock;
import android.provider.MediaStore;

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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Camera backup: copies new photos and videos from DCIM/Camera to the cloud drive through the PC
 * ("Phone Backup/&lt;phone&gt;/Camera/&lt;year-month&gt;"). It runs without the app being open — a few times a day and
 * shortly after a new photo — but only does something when the paired PC answers, i.e. the phone is at home on Wi-Fi.
 * What was already copied is remembered on the phone, and the PC is asked what it has, so nothing is sent twice.
 */
final class CameraBackup {
    static final int JOB_PERIODIC = 7101;
    static final int JOB_NEW_MEDIA = 7102;
    static final int JOB_NOW = 7103;
    static final int JOB_CONTINUE = 7104;

    private static final String PREFS = "cloudssd_backup";
    private static final String FOLDER = "Camera";
    private static final String CHANNEL = "cloudssd_backup";
    private static final int PROGRESS = 7200;
    private static final int SUMMARY = 7201;
    /** Android stops a background job after about ten minutes; stop a little earlier and continue next time. */
    private static final long MAX_RUN_MS = 9 * 60 * 1000;

    private static final AtomicBoolean running = new AtomicBoolean();

    private CameraBackup() {
    }

    // ---- switch and schedule ---------------------------------------------------------------------------------------

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    static boolean enabled(Context c) {
        return prefs(c).getBoolean("enabled", false);
    }

    static void setEnabled(Context c, boolean on) {
        prefs(c).edit().putBoolean("enabled", on).apply();
        JobScheduler jobs = (JobScheduler) c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
        if (jobs == null) return;
        if (!on) {
            jobs.cancel(JOB_PERIODIC);
            jobs.cancel(JOB_NEW_MEDIA);
            jobs.cancel(JOB_NOW);
            jobs.cancel(JOB_CONTINUE);
            return;
        }
        // Survives a restart of the phone; Wi-Fi only, because the PC is only reachable there.
        jobs.schedule(new JobInfo.Builder(JOB_PERIODIC, service(c))
                .setPeriodic(6 * 60 * 60 * 1000L)
                .setPersisted(true)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_UNMETERED)
                .build());
        watchForNewMedia(c);
    }

    private static ComponentName service(Context c) {
        return new ComponentName(c, CameraBackupService.class);
    }

    /** Runs the backup shortly after a photo or video is added. Android forgets this after each run, so it is set again. */
    static void watchForNewMedia(Context c) {
        JobScheduler jobs = (JobScheduler) c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
        if (jobs == null || !enabled(c)) return;
        jobs.schedule(new JobInfo.Builder(JOB_NEW_MEDIA, service(c))
                .addTriggerContentUri(new JobInfo.TriggerContentUri(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, JobInfo.TriggerContentUri.FLAG_NOTIFY_FOR_DESCENDANTS))
                .addTriggerContentUri(new JobInfo.TriggerContentUri(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, JobInfo.TriggerContentUri.FLAG_NOTIFY_FOR_DESCENDANTS))
                .setTriggerContentUpdateDelay(10 * 1000L)      // a burst of photos becomes one run
                .setTriggerContentMaxDelay(2 * 60 * 1000L)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_UNMETERED)
                .build());
    }

    /** "Back up now" in the app. */
    static void runNow(Context c) {
        JobScheduler jobs = (JobScheduler) c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
        if (jobs == null) return;
        jobs.schedule(new JobInfo.Builder(JOB_NOW, service(c))
                .setOverrideDeadline(0)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .build());
    }

    /** What the app shows: {enabled, running, lastRun, lastCount, total, waiting, error}. */
    static String statusJson(Context c) {
        SharedPreferences p = prefs(c);
        try {
            return new JSONObject()
                    .put("enabled", p.getBoolean("enabled", false))
                    .put("running", running.get())
                    .put("lastRun", p.getLong("lastRun", 0))
                    .put("lastCount", p.getInt("lastCount", 0))
                    .put("total", p.getInt("total", 0))
                    .put("waiting", p.getInt("waiting", 0))
                    .put("error", p.getString("error", ""))
                    .toString();
        } catch (JSONException e) {
            return "{}";
        }
    }

    // ---- what is already copied ------------------------------------------------------------------------------------

    private static final class Item {
        String kind;      // "image" or "video"
        long id;
        String name;
        long size;
        long modified;    // when it was taken, ms
        String path;
        Uri uri;
    }

    /** Remembers which camera items were copied, by MediaStore id plus size and time (an edited photo counts as new). */
    private static final class Ledger extends SQLiteOpenHelper {
        Ledger(Context c) {
            super(c, "camera_backup.db", null, 1);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {
            db.execSQL("CREATE TABLE done (kind TEXT NOT NULL, id INTEGER NOT NULL, size INTEGER NOT NULL, modified INTEGER NOT NULL, PRIMARY KEY (kind, id))");
        }

        @Override
        public void onUpgrade(SQLiteDatabase db, int from, int to) {
        }

        Map<String, long[]> all() {
            Map<String, long[]> map = new HashMap<>();
            try (Cursor c = getReadableDatabase().rawQuery("SELECT kind, id, size, modified FROM done", null)) {
                while (c.moveToNext()) map.put(c.getString(0) + c.getLong(1), new long[]{c.getLong(2), c.getLong(3)});
            }
            return map;
        }

        void mark(Item it) {
            ContentValues v = new ContentValues();
            v.put("kind", it.kind);
            v.put("id", it.id);
            v.put("size", it.size);
            v.put("modified", it.modified);
            getWritableDatabase().insertWithOnConflict("done", null, v, SQLiteDatabase.CONFLICT_REPLACE);
        }
    }

    /** Photos and videos in DCIM/Camera that are not copied yet, oldest first. */
    private static List<Item> waiting(Context c, Ledger ledger) {
        Map<String, long[]> done = ledger.all();
        List<Item> items = new ArrayList<>();
        Uri[] tables = {MediaStore.Images.Media.EXTERNAL_CONTENT_URI, MediaStore.Video.Media.EXTERNAL_CONTENT_URI};
        String[] columns = {MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED, "datetaken", MediaStore.MediaColumns.DATA};
        boolean scoped = Build.VERSION.SDK_INT >= 29;
        String where = (scoped ? MediaStore.MediaColumns.RELATIVE_PATH : MediaStore.MediaColumns.DATA) + " LIKE ?";
        String[] args = {scoped ? "DCIM/Camera/%" : "%/DCIM/Camera/%"};
        for (int t = 0; t < tables.length; t++) {
            try (Cursor cur = c.getContentResolver().query(tables[t], columns, where, args, MediaStore.MediaColumns.DATE_MODIFIED + " ASC")) {
                while (cur != null && cur.moveToNext()) {
                    Item it = new Item();
                    it.kind = t == 0 ? "image" : "video";
                    it.id = cur.getLong(0);
                    it.name = cur.getString(1);
                    it.size = cur.getLong(2);
                    long taken = cur.isNull(4) ? 0 : cur.getLong(4);
                    it.modified = taken > 0 ? taken : cur.getLong(3) * 1000L;
                    it.path = cur.getString(5);
                    it.uri = ContentUris.withAppendedId(tables[t], it.id);
                    if (it.name == null || it.name.isEmpty() || it.size <= 0) continue; // still being written by the camera
                    long[] was = done.get(it.kind + it.id);
                    if (was == null || was[0] != it.size || was[1] != it.modified) items.add(it);
                }
            } catch (SecurityException e) {
                // No permission to see photos (any more): nothing to do until the user allows it again.
            }
        }
        return items;
    }

    // ---- talking to the PC -----------------------------------------------------------------------------------------

    private static final class Refused extends IOException {
        final int status;

        Refused(int status, String message) {
            super(message);
            this.status = status;
        }
    }

    private static String enc(String s) throws IOException {
        return URLEncoder.encode(s, "UTF-8").replace("+", "%20");
    }

    private static HttpURLConnection open(String url, String token, String method, int readMs) throws IOException {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setConnectTimeout(3000);
        c.setReadTimeout(readMs);
        c.setUseCaches(false);
        c.setRequestMethod(method);
        c.setRequestProperty("X-Pairing-Token", token);
        c.setRequestProperty("Connection", "close");
        return c;
    }

    private static String body(HttpURLConnection c) throws IOException {
        int code = c.getResponseCode();
        InputStream in = code >= 400 ? c.getErrorStream() : c.getInputStream();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (in != null) {
            byte[] buf = new byte[16 * 1024];
            for (int n; (n = in.read(buf)) > 0; ) out.write(buf, 0, n);
        }
        String text = out.toString("UTF-8");
        if (code >= 400) {
            String message = "The PC refused the backup (" + code + ").";
            try {
                String error = new JSONObject(text).optString("error", "");
                if (!error.isEmpty()) message = error;
            } catch (JSONException ignored) {
            }
            throw new Refused(code, message);
        }
        return text;
    }

    /** "name|size" of everything the PC already holds for this phone's camera folder. */
    private static Set<String> onPc(String server, String token, String device) throws IOException {
        HttpURLConnection c = open(server + "/api/backup/index?device=" + enc(device) + "&folder=" + FOLDER, token, "GET", 60000);
        Set<String> have = new HashSet<>();
        try {
            JSONArray files = new JSONObject(body(c)).optJSONArray("files");
            for (int i = 0; files != null && i < files.length(); i++) {
                JSONObject f = files.getJSONObject(i);
                have.add(f.optString("name") + "|" + f.optLong("size"));
            }
        } catch (JSONException e) {
            throw new IOException("Unexpected answer from the PC.", e);
        } finally {
            c.disconnect();
        }
        return have;
    }

    /** The item's bytes exactly as the camera wrote them (including where the photo was taken), with their length. */
    private static Object[] source(Context c, Item it) throws IOException {
        File f = it.path == null ? null : new File(it.path);
        boolean fullAccess = Build.VERSION.SDK_INT < 29 || (Build.VERSION.SDK_INT >= 30 && Environment.isExternalStorageManager());
        if (f != null && fullAccess && f.canRead()) return new Object[]{new FileInputStream(f), f.length()};
        Uri uri = it.uri;
        // Without this Android blanks the GPS position inside the photo it hands out.
        if (Build.VERSION.SDK_INT >= 29 && c.checkSelfPermission("android.permission.ACCESS_MEDIA_LOCATION") == PackageManager.PERMISSION_GRANTED)
            uri = MediaStore.setRequireOriginal(uri);
        AssetFileDescriptor fd = c.getContentResolver().openAssetFileDescriptor(uri, "r");
        if (fd == null) throw new IOException("Cannot read " + it.name);
        return new Object[]{fd.createInputStream(), fd.getLength()};
    }

    private static void upload(Context c, String server, String token, String device, Item it, AtomicBoolean stop) throws IOException {
        Object[] src = source(c, it);
        long length = (Long) src[1];
        HttpURLConnection conn = open(server + "/api/backup/upload?device=" + enc(device) + "&folder=" + FOLDER + "&name=" + enc(it.name)
                + "&modified=" + it.modified + (length >= 0 ? "&size=" + length : ""), token, "POST", 5 * 60 * 1000);
        try (InputStream in = (InputStream) src[0]) {
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/octet-stream");
            if (length >= 0) conn.setFixedLengthStreamingMode(length);
            else conn.setChunkedStreamingMode(64 * 1024);
            try (OutputStream out = conn.getOutputStream()) {
                byte[] buf = new byte[128 * 1024];
                for (int n; (n = in.read(buf)) >= 0; ) {
                    if (stop.get()) throw new IOException("stopped");
                    out.write(buf, 0, n);
                }
            }
            body(conn);
        } finally {
            conn.disconnect();
        }
    }

    // ---- one run ---------------------------------------------------------------------------------------------------

    /** Copies what is waiting. Returns quietly when the PC is not reachable; safe to call at any time. */
    static void run(Context c, AtomicBoolean stop) {
        if (!running.compareAndSet(false, true)) return;
        try {
            copy(c.getApplicationContext(), stop);
        } finally {
            running.set(false);
            cancelProgress(c);
        }
    }

    /** Re-creates the schedule if Android dropped it (after an app update, for example). */
    static void ensureScheduled(Context c) {
        if (!enabled(c)) return;
        JobScheduler jobs = (JobScheduler) c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
        if (jobs == null) return;
        if (jobs.getPendingJob(JOB_PERIODIC) == null) setEnabled(c, true);
        else if (jobs.getPendingJob(JOB_NEW_MEDIA) == null) watchForNewMedia(c);
    }

    private static void save(Context c, int sent, int left, String error) {
        SharedPreferences p = prefs(c);
        p.edit().putLong("lastRun", System.currentTimeMillis()).putInt("lastCount", sent).putInt("total", p.getInt("total", 0) + sent)
                .putInt("waiting", Math.max(0, left)).putString("error", error)
                // Ran out of time with the PC still there: the rest follows in a moment (see continueIfMore).
                .putBoolean("more", left > 0 && error.isEmpty()).commit();
    }

    /**
     * A first backup can be thousands of photos, more than fits in one ten-minute run: when the last run stopped only
     * because its time was up, the next one starts right away instead of hours later.
     */
    static void continueIfMore(Context c) {
        JobScheduler jobs = (JobScheduler) c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
        if (jobs == null || !enabled(c) || !prefs(c).getBoolean("more", false)) return;
        prefs(c).edit().putBoolean("more", false).apply();
        jobs.schedule(new JobInfo.Builder(JOB_CONTINUE, service(c))
                .setMinimumLatency(3000)
                .setOverrideDeadline(60 * 1000L)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_UNMETERED)
                .build());
    }

    /** Returns how many items were sent. */
    private static int copy(Context c, AtomicBoolean stop) {
        SharedPreferences link = c.getSharedPreferences("cloudssd", Context.MODE_PRIVATE);
        String server = link.getString("server", "");
        String token = link.getString("token", "");
        if (server.isEmpty() || token.isEmpty()) return 0;

        String device = Build.MODEL == null || Build.MODEL.trim().isEmpty() ? "Phone" : Build.MODEL.trim();
        Ledger ledger = new Ledger(c);
        try {
            List<Item> todo = waiting(c, ledger);
            int left = todo.size();
            if (todo.isEmpty()) {
                save(c, 0, 0, "");
                return 0;
            }
            Set<String> have;
            try {
                have = onPc(server, token, device);
            } catch (Refused e) {
                prefs(c).edit().putInt("waiting", left).putString("error", e.getMessage()).apply();
                return 0;
            } catch (IOException e) {
                // Not at home, or the PC is off: try again at the next run, without bothering anyone.
                prefs(c).edit().putInt("waiting", left).putString("error", "").apply();
                return 0;
            }
            int sent = 0;
            String error = "";
            long deadline = SystemClock.elapsedRealtime() + MAX_RUN_MS;
            int total = todo.size();
            for (Item it : todo) {
                if (stop.get() || SystemClock.elapsedRealtime() > deadline) break;
                if (have.contains(it.name + "|" + it.size)) {
                    ledger.mark(it);
                    left--;
                    continue;
                }
                notifyProgress(c, total - left + 1, total, it.name);
                try {
                    upload(c, server, token, device, it, stop);
                    ledger.mark(it);
                    left--;
                    sent++;
                } catch (Refused e) {
                    error = e.getMessage();
                    if (e.status != 400) break;   // 400 = this one file cannot be stored; anything else stops the run
                } catch (IOException e) {
                    if (!stop.get()) error = "The connection to the PC was lost.";
                    break;
                }
            }
            save(c, sent, left, error);
            if (sent > 0) notifyDone(c, sent, Math.max(0, left));
            return sent;
        } finally {
            ledger.close();
        }
    }

    // ---- notifications ---------------------------------------------------------------------------------------------

    private static Notification.Builder builder(Context c) {
        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= 26) {
            if (nm != null) nm.createNotificationChannel(new NotificationChannel(CHANNEL, "Camera backup", NotificationManager.IMPORTANCE_LOW));
            return new Notification.Builder(c, CHANNEL);
        }
        return new Notification.Builder(c);
    }

    private static void show(Context c, int id, Notification.Builder b) {
        try {
            NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) nm.notify(id, b.build());
        } catch (RuntimeException ignored) {
            // Notifications switched off for the app: the backup itself is not affected.
        }
    }

    private static void notifyProgress(Context c, int index, int total, String name) {
        show(c, PROGRESS, builder(c).setSmallIcon(android.R.drawable.stat_sys_upload).setContentTitle("Camera backup · " + index + " of " + total)
                .setContentText(name).setOngoing(true).setProgress(total, index - 1, false));
    }

    private static void notifyDone(Context c, int sent, int left) {
        show(c, SUMMARY, builder(c).setSmallIcon(android.R.drawable.stat_sys_upload_done).setContentTitle("Camera backup")
                .setContentText(sent + (sent == 1 ? " new item saved to the cloud" : " new items saved to the cloud") + (left > 0 ? " · " + left + " waiting" : ""))
                .setAutoCancel(true));
    }

    private static void cancelProgress(Context c) {
        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.cancel(PROGRESS);
    }
}

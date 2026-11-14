// K1 (plan docs\WHEN_OFF_BINA_KEY_PLAN.md), PC side: this PC's own disks as read-only drives "disk-<letter>:" on
// /api/fs/*, so a phone can keep a PC folder on itself. Run: node .work\k1-pc.js <repo>
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

patch('src/CloudSSD.App/LocalMobileBridgeService.Files.cs', [
  [`    private class FsException(int status, string message) : Exception(message)`,
`    /// <summary>Id of one of this PC's own disks as a drive: "disk-c:Users/…".</summary>
    internal const string DiskRootPrefix = "disk-";

    /// <summary>Tests have no disk of their own to show; they supply folders to act as PC disks.</summary>
    internal Func<IReadOnlyList<CloudRoot>>? DiskRootsOverride;

    /// <summary>
    /// This PC's own disks (not the cloud drives), each as a read-only drive "disk-&lt;letter&gt;", so a phone can keep a
    /// folder of the PC on itself ("Offline rakho") and open it while the PC is off. What may be read is decided as on
    /// /api/files: only places shared with the device (see <see cref="Target"/>).
    /// </summary>
    private IReadOnlyList<CloudRoot> DiskRoots()
    {
        if (DiskRootsOverride != null) return DiskRootsOverride();
        var cloud = _host.Mounts.Sessions.Select(s => Path.GetPathRoot(s.Root) ?? "").Where(r => r.Length > 0)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        var roots = new List<CloudRoot>();
        try
        {
            foreach (var d in DriveInfo.GetDrives())
            {
                if (d.DriveType != DriveType.Fixed || !d.IsReady || cloud.Contains(d.Name)) continue;
                var letter = d.Name[..1];
                roots.Add(new CloudRoot(DiskRootPrefix + letter.ToLowerInvariant(), d.Name, true, false, null, letter.ToUpperInvariant() + ": PC disk"));
            }
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { }
        return roots;
    }

    private class FsException(int status, string message) : Exception(message)`],
  [`    private FsTarget Target(Dictionary<string, string> q, string key = "path") => ResolveCloudPath(BrowseRoots(), q.GetValueOrDefault(key));`,
`    private FsTarget Target(Dictionary<string, string> q, string key = "path")
    {
        var raw = q.GetValueOrDefault(key);
        bool disk = raw != null && raw.StartsWith(DiskRootPrefix, StringComparison.OrdinalIgnoreCase);
        var t = ResolveCloudPath(disk ? DiskRoots() : BrowseRoots(), raw);
        // One of this PC's own disks: only what is shared with the device, exactly as on /api/files.
        if (disk && !IsInsideAny(CleanPath(t.FullPath), SharedRoots()))
            throw new FsException(403, "This place is not shared with the phone. Turn on 'PC disks' in Cloud-SSD → Phone → Permissions on the PC.");
        return t;
    }`],
  [`    private object FsRoots(Dictionary<string, string> q) => (q.GetValueOrDefault("include") == "local" ? BrowseRoots() : CloudRoots()).Select(r =>`,
   `    private object FsRoots(Dictionary<string, string> q) => (q.GetValueOrDefault("include") switch { "local" => BrowseRoots(), "disks" => DiskRoots(), _ => CloudRoots() }).Select(r =>`]
]);

patch('src/CloudSSD.App/LocalMobileBridgeService.Security.cs', [[`"fs-local-roots", "links"`, `"fs-local-roots", "fs-disk-roots", "links"`]]);

patch('tests/CloudSSD.Tests/MobileBridgeSecurityTests.cs', [[
`    // ---- device keys ------------------------------------------------------------------------------------------------
`,
`    [Fact]
    public Task A_pc_disk_is_a_read_only_drive_and_only_its_shared_places_open() => With(async env =>
    {
        // A folder standing in for the PC's C: disk, outside every cloud drive.
        var disk = Path.Combine(env.Temp, "disk");
        Directory.CreateDirectory(Path.Combine(disk, "Users", "me", "Documents"));
        await File.WriteAllTextAsync(Path.Combine(disk, "Users", "me", "Documents", "note.txt"), "hello");
        env.Bridge.DiskRootsOverride = () => [new CloudRoot("disk-c", disk, true, false, null, "C: PC disk")];

        // PC disks are not shared: nothing of the disk is listed or read, and it is not one of the cloud drives.
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Get("/api/fs/list?path=" + E("disk-c:Users/me/Documents"))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Get("/api/fs/read?path=" + E("disk-c:Users/me/Documents/note.txt"))).StatusCode);
        Assert.DoesNotContain("disk-c", await (await env.Get("/api/fs/roots")).Content.ReadAsStringAsync());

        env.Host.Settings.MobileBridge.AllowPcDisks = true;
        var roots = await env.Json(await env.Get("/api/fs/roots?include=disks"));
        Assert.Equal("disk-c", roots[0].GetProperty("id").GetString());
        Assert.True(roots[0].GetProperty("readOnly").GetBoolean());
        var list = await env.Json(await env.Get("/api/fs/list?path=" + E("disk-c:Users/me/Documents")));
        var entry = list.GetProperty("entries")[0];
        Assert.Equal("disk-c:Users/me/Documents/note.txt", entry.GetProperty("id").GetString());
        Assert.False(entry.GetProperty("canEdit").GetBoolean());
        Assert.Equal("hello", await (await env.Get("/api/fs/read?path=" + E("disk-c:Users/me/Documents/note.txt"))).Content.ReadAsStringAsync());

        // Read only: nothing on the PC's disk is changed through it, and a path cannot climb out of it.
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Post("/api/fs/delete?path=" + E("disk-c:Users/me/Documents/note.txt"))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await env.Post("/api/fs/create?parent=" + E("disk-c:Users/me/Documents") + "&name=new.txt")).StatusCode);
        Assert.True(File.Exists(Path.Combine(disk, "Users", "me", "Documents", "note.txt")));
        Assert.NotEqual(HttpStatusCode.OK, (await env.Get("/api/fs/list?path=" + E("disk-c:../"))).StatusCode);
    });

    // ---- device keys ------------------------------------------------------------------------------------------------
`]]);

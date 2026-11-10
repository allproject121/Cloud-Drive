using System.Globalization;
using System.Net.Sockets;
using System.Text.RegularExpressions;

namespace CloudSSD.App;

/// <summary>
/// Camera backup from the phone: /api/backup/index tells the phone what is already saved, /api/backup/upload takes
/// one photo or video. Files land in "Phone Backup\&lt;device&gt;\&lt;folder&gt;\&lt;yyyy-MM&gt;" on the All Accounts
/// drive (or under the folder chosen in settings), one sub-folder per month so no folder grows without end.
/// </summary>
public sealed partial class LocalMobileBridgeService
{
    internal const string BackupFolderName = "Phone Backup";

    /// <summary>Where backups go, and the disk whose free space limits what can be received.</summary>
    private (string Folder, string SpaceCheckedOn) BackupBase(Dictionary<string, string> q)
    {
        string baseDir, space;
        if (_host.Settings.MobileBridge.PhotoBackupDirectory is { Length: > 0 } chosen)
        {
            baseDir = space = chosen;
        }
        else
        {
            var root = CloudRoots().FirstOrDefault(r => string.Equals(r.Id, AppHost.CombinedMountId, StringComparison.OrdinalIgnoreCase) && !r.ReadOnly)
                ?? throw new FsException(503, "The All Accounts drive is not connected on the PC.");
            baseDir = Path.Combine(root.Root, BackupFolderName);
            space = root.CacheDir ?? root.Root;
        }
        return (Path.Combine(baseDir, BackupPart(q.GetValueOrDefault("device"), "Phone"), BackupPart(q.GetValueOrDefault("folder"), "Camera")), space);
    }

    private static string BackupPart(string? raw, string fallback)
    {
        if (string.IsNullOrWhiteSpace(raw)) return fallback;
        var name = SafeUploadName(raw);
        return IsPlainName(name) ? name : fallback;
    }

    private static bool IsMonth(string? s) => s != null && Regex.IsMatch(s, @"^\d{4}-(0[1-9]|1[0-2])$");

    /// <summary>What is already backed up: one month when "month" is given, otherwise every month.</summary>
    private object BackupIndex(Dictionary<string, string> q)
    {
        var folder = BackupBase(q).Folder;
        var month = q.GetValueOrDefault("month");
        if (month != null && !IsMonth(month)) throw new FsException(400, "A month looks like 2026-11.");
        var files = new List<object>();
        if (Directory.Exists(folder))
        {
            List<string> months = month != null ? [month]
                : new DirectoryInfo(folder).EnumerateDirectories().Select(d => d.Name).Where(n => IsMonth(n)).Order().ToList();
            foreach (var m in months)
            {
                var dir = new DirectoryInfo(Path.Combine(folder, m));
                if (!dir.Exists) continue;
                files.AddRange(dir.EnumerateFiles().Where(f => !f.Name.EndsWith(PartSuffix, StringComparison.OrdinalIgnoreCase))
                    .Select(f => (object)new { month = m, name = f.Name, size = f.Length }));
            }
        }
        return new { files };
    }

    private async Task<object> BackupUploadAsync(Dictionary<string, string> q, Dictionary<string, string> headers, NetworkStream stream, string clientIp, CancellationToken ct)
    {
        var (baseFolder, space) = BackupBase(q);
        var wanted = (q.GetValueOrDefault("name") ?? "").Trim();
        if (wanted.Length == 0) throw new FsException(400, "Missing file name.");
        var name = IsPlainName(wanted) ? wanted : SafeUploadName(wanted);
        var modified = ModifiedTime(q);
        var month = (modified ?? DateTime.UtcNow).ToLocalTime().ToString("yyyy-MM", CultureInfo.InvariantCulture);
        var folder = Path.Combine(baseFolder, month);
        Directory.CreateDirectory(folder);

        long incoming = -1;
        if (!(headers.TryGetValue("Content-Length", out var cl) && long.TryParse(cl, out incoming)) &&
            !long.TryParse(q.GetValueOrDefault("size"), out incoming)) incoming = -1;

        // Same name and same size: this photo is already here. The body is read and dropped so the phone gets its answer.
        var existing = new FileInfo(Path.Combine(folder, name));
        if (existing.Exists && existing.Length == incoming)
        {
            await DrainBodyAsync(headers, stream, ct);
            return new { skipped = true, month, name, size = existing.Length };
        }
        // Same name, different content (two phones, or an edited photo): keep both.
        name = FreeName(folder, name);
        long saved = await ReceiveFileAsync(headers, stream, clientIp, folder, name, overwrite: false, modified, space, ct);
        return new { skipped = false, month, name, size = saved };
    }

    private static async Task DrainBodyAsync(Dictionary<string, string> headers, NetworkStream stream, CancellationToken ct)
    {
        bool chunked = headers.TryGetValue("Transfer-Encoding", out var te) && te.Contains("chunked", StringComparison.OrdinalIgnoreCase);
        long left = !chunked && headers.TryGetValue("Content-Length", out var cl) && long.TryParse(cl, out var n) ? n : chunked ? long.MaxValue : 0;
        var body = chunked ? (Stream)new ChunkedBodyStream(stream) : stream;
        var buffer = new byte[64 * 1024];
        try
        {
            while (left > 0)
            {
                int read = await body.ReadAsync(buffer.AsMemory(0, (int)Math.Min(buffer.Length, left)), ct);
                if (read == 0) break;
                left -= read;
            }
        }
        catch (Exception e) when (e is IOException or InvalidDataException) { }
    }
}

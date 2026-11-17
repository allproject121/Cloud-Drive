using System.Diagnostics;
using System.Text;
using CloudSSD.App;
using CloudSSD.Core;
using CloudSSD.Diagnostics;
using CloudSSD.Games;
using CloudSSD.Mount;
using CloudSSD.SimCloud;

namespace CloudSSD.Cli;

public static class Program
{
    private const string Banner = """
        +==============================================================================+
        |   CLOUD-SSD  v0.9.0  -  Virtual Cloud Disk & Storage Engine                  |
        |              Terminal Shell (Interactive Claude & Codex Style)               |
        +==============================================================================+
        """;

    private const string Usage = """
        cloudssd (or cpx) - Cloud-SSD command line & interactive terminal

        USAGE:
          cloudssd                     Start interactive terminal shell (Claude & Codex style)
          cloudssd status              Show live virtual drives (Z:, Y:), storage & system health
          cloudssd open [letter]       Open virtual drive in File Explorer (default: Z:)
          cloudssd remotes             List configured Google Drive & cloud accounts
          cloudssd mounts              List configured virtual drives and drive letters
          cloudssd phone               Show connected & paired mobile devices (Android)
          cloudssd cache               Show local SSD cache usage and disk safety status
          cloudssd clean               Clean temporary files and stale cache safely
          cloudssd mirror              Show cloud backup / mirror status
          cloudssd start               Start Cloud-SSD desktop app in background
          cloudssd stop                Gracefully stop running Cloud-SSD processes
          cloudssd deps                Check WinFsp, rclone, and system prerequisites
          cloudssd mount <id> [--letter X]
                                       Mount a configured drive in the foreground (Ctrl+C to unmount)
          cloudssd scan <folder> [--mbps 70]
                                       Scan a game folder and print the compatibility report
          cloudssd pe <file.exe>       Show PE architecture and imported DLLs
          cloudssd profile <game-id>   Show learned access profile of a game
          cloudssd simcloud --root <dir> [--port 8080] [--mbps 70] [--latency-ms 150]
                                       Serve a folder as a throttled local test cloud
          cloudssd secret emit-config-pass [--home dir]
                                       Emit DPAPI-protected encryption key for rclone

        Options:
          --home <dir>                 Overrides the data folder (default: %LOCALAPPDATA%\Cloud-SSD).
        """;

    public static async Task<int> Main(string[] args)
    {
        var home = Opt(args, "--home");
        var paths = new AppPaths(home);

        if (args.Length == 0)
        {
            return await RunInteractiveShellAsync(paths);
        }

        if (args[0] is "-h" or "--help" or "help")
        {
            Console.WriteLine(Usage);
            return 0;
        }

        return await DispatchCommandAsync(args, paths);
    }

    private static async Task<int> RunInteractiveShellAsync(AppPaths paths)
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine(Banner);
        Console.ResetColor();

        // Show brief startup summary
        PrintQuickSummary(paths);

        Console.WriteLine("Type 'help' for command list, or 'exit' to quit.\n");

        while (true)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("cloudssd");
            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.Write(" > ");
            Console.ResetColor();

            var line = Console.ReadLine();
            if (line == null) break;

            line = line.Trim();
            if (string.IsNullOrEmpty(line)) continue;

            var tokens = SplitCommandLine(line);
            if (tokens.Length == 0) continue;

            var cmd = tokens[0].ToLowerInvariant();
            if (cmd is "exit" or "quit" or "q")
            {
                Console.WriteLine("Bye!");
                break;
            }

            if (cmd is "cls" or "clear")
            {
                Console.Clear();
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine(Banner);
                Console.ResetColor();
                PrintQuickSummary(paths);
                continue;
            }

            if (cmd is "help" or "?")
            {
                PrintInteractiveHelp();
                continue;
            }

            try
            {
                await DispatchCommandAsync(tokens, paths);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Error: " + Redactor.Redact(ex.Message));
                Console.ResetColor();
            }
            Console.WriteLine();
        }

        return 0;
    }

    private static void PrintQuickSummary(AppPaths paths)
    {
        try
        {
            var proc = Process.GetProcessesByName("Cloud-SSD").FirstOrDefault()
                       ?? Process.GetProcessesByName("CloudPlayX").FirstOrDefault();
            var statusStr = proc != null ? $"Online (PID: {proc.Id})" : "Stopped";
            var statusColor = proc != null ? ConsoleColor.Green : ConsoleColor.Yellow;

            Console.Write("  Status: ");
            Console.ForegroundColor = statusColor;
            Console.Write(statusStr);
            Console.ResetColor();

            var mountedLetters = DriveInfo.GetDrives()
                .Where(d => d.IsReady && (d.DriveFormat.Contains("rclone", StringComparison.OrdinalIgnoreCase) ||
                                          d.Name.StartsWith("Z", StringComparison.OrdinalIgnoreCase) ||
                                          d.Name.StartsWith("Y", StringComparison.OrdinalIgnoreCase)))
                .Select(d => $"{d.Name.TrimEnd('\\')} ({ByteSize.Format(d.TotalFreeSpace)} free)")
                .ToList();

            if (mountedLetters.Count > 0)
            {
                Console.Write("  |  Drives: ");
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.Write(string.Join(", ", mountedLetters));
                Console.ResetColor();
            }

            Console.WriteLine();
            Console.WriteLine("  Data Root: " + paths.DataRoot);
            Console.WriteLine(new string('-', 78));
        }
        catch
        {
            // Fallback gracefully
        }
    }

    private static void PrintInteractiveHelp()
    {
        Console.WriteLine("""

        AVAILABLE COMMANDS:
          status (s)         Show live virtual drives (Z:, Y:), storage & system health
          open [letter]      Open virtual drive in File Explorer (e.g. 'open Z:' or just 'open')
          mounts (drives)    List configured virtual drives and drive letters
          remotes (accounts) List configured Google Drive & cloud accounts
          phone (devices)    Show connected & paired mobile devices (Android)
          cache              Show local SSD cache usage and disk safety status
          clean              Clean temporary files and stale cache safely
          mirror (sync)      Show cloud backup / mirror status
          start              Start Cloud-SSD desktop app in background
          stop               Gracefully stop running Cloud-SSD processes
          deps               Check WinFsp, rclone, and system prerequisites
          scan <folder>      Scan a game folder and print compatibility analysis
          pe <file.exe>      Inspect PE dependencies of an executable
          clear (cls)        Clear terminal screen
          exit (quit, q)     Exit terminal shell

        """);
    }

    private static async Task<int> DispatchCommandAsync(string[] args, AppPaths paths)
    {
        var cmd = args[0].ToLowerInvariant();
        switch (cmd)
        {
            case "status" or "s":
                PrintStatus(paths);
                return 0;

            case "open":
                return OpenDrive(args.Length > 1 ? args[1] : "Z:");

            case "start":
                return StartApp();

            case "stop":
                return StopApp();

            case "phone" or "devices":
                PrintDevices(paths);
                return 0;

            case "cache":
                PrintCache(paths);
                return 0;

            case "clean":
                return CleanTempAndCache(paths);

            case "mirror" or "sync":
                PrintMirror(paths);
                return 0;

            case "secret" when args.Length > 1 && args[1] == "emit-config-pass":
            {
                var pass = SecretStore.Load(paths.ConfigPasswordFile);
                if (pass is null)
                {
                    Console.Error.WriteLine("No configuration key found for this Windows user.");
                    return 1;
                }
                Console.Out.Write(pass);
                return 0;
            }

            case "deps":
            {
                var rclone = await RcloneLocator.LocateAsync(null, paths.DataRoot);
                var settings = new JsonSettingsStore(paths.SettingsFile).Load();
                foreach (var d in DependencyChecker.CheckAll(rclone?.Path, rclone?.Version, paths.CacheRootFor(settings), settings.Cache.MinFreeSpaceBytes))
                    Console.WriteLine($"[{d.State,-7}] {d.Name}: {d.Detail}{(d.Remedy != null ? $"\n           → {d.Remedy}" : "")}");
                return 0;
            }

            case "remotes" or "accounts":
            {
                await using var host = AppHost.Create(paths);
                await host.InitializeAsync(restoreMounts: false);
                foreach (var r in host.Remotes) Console.WriteLine($"{r.Name,-20} {r.Type}");
                if (host.Remotes.Count == 0) Console.WriteLine("No cloud accounts configured. Connect cloud accounts in the Cloud-SSD app.");
                return 0;
            }

            case "mounts" or "drives":
            {
                var s = new JsonSettingsStore(paths.SettingsFile).Load();
                foreach (var m in s.Mounts) Console.WriteLine($"{m.Id}  {m.DisplayName,-20} {m.RemoteSpec,-30} letter={m.DriveLetter ?? "auto"} auto={m.AutoMount}");
                return 0;
            }

            case "mount" when args.Length > 1:
            {
                await using var host = AppHost.Create(paths);
                if (!host.TryAcquireInstanceLock())
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("Cloud-SSD is already running in background. Drives are mounted.");
                    Console.WriteLine("Use 'cloudssd status' to view active drives, or 'cloudssd open' to explore.");
                    Console.ResetColor();
                    return 0;
                }
                await host.InitializeAsync(restoreMounts: false);
                var def = host.Settings.Mounts.FirstOrDefault(m => m.Id == args[1] || m.DisplayName == args[1])
                          ?? throw new ArgumentException($"No configured drive '{args[1]}'. See 'cloudssd mounts'.");
                if (Opt(args, "--letter") is { } l) def.DriveLetter = l;
                var s = await host.MountAsync(def);
                Console.WriteLine($"Mounted {def.RemoteSpec} at {s.DriveLetter}:. Press Ctrl+C to unmount.");
                var done = new TaskCompletionSource();
                Console.CancelKeyPress += (_, e) => { e.Cancel = true; done.TrySetResult(); };
                await done.Task;
                await host.ShutdownAsync(keepMounts: false);
                return 0;
            }

            case "scan" when args.Length > 1:
            {
                var scan = GameScanner.Scan(args[1]);
                var mbps = double.TryParse(Opt(args, "--mbps"), out var v) ? v : 70;
                var r = CompatibilityAnalyzer.Analyze(scan, null, mbps, null, 0);
                if (r.Executable != null && PeInspector.TryRead(Path.Combine(args[1], r.Executable)) is { } pe)
                    CompatibilityAnalyzer.AddDependencyIssues(r, DependencyResolver.Check(pe, Path.GetDirectoryName(Path.Combine(args[1], r.Executable))!, args[1]));
                Console.WriteLine($"{scan.FileCount:N0} files, {ByteSize.Format(scan.TotalBytes)}, engine: {scan.Engine ?? "unknown"}, scanned in {scan.Elapsed.TotalSeconds:0.00} s");
                Console.WriteLine("Executables:");
                foreach (var e in scan.Executables) Console.WriteLine($"  [{e.Score,3}] {e.RelativePath} ({e.Reason})");
                Console.WriteLine($"Markers: {string.Join(", ", scan.Markers)}");
                Console.WriteLine($"Compatibility: {r.Summary}; recommended mode: {r.RecommendedMode}");
                foreach (var i in r.Issues) Console.WriteLine($"  {i.Severity,-7} {i.Message}{(i.Suggestion != null ? $"\n          → {i.Suggestion}" : "")}");
                return 0;
            }

            case "pe" when args.Length > 1:
            {
                var pe = PeInspector.TryRead(args[1]);
                if (pe is null) { Console.Error.WriteLine("Not a readable PE file."); return 1; }
                Console.WriteLine($"{pe.Machine} {pe.Subsystem} .NET={pe.IsDotNet}");
                foreach (var i in pe.AllImports) Console.WriteLine("  " + i);
                foreach (var d in DependencyResolver.Check(pe, Path.GetDirectoryName(Path.GetFullPath(args[1]))!, Path.GetDirectoryName(Path.GetFullPath(args[1]))!))
                    Console.WriteLine($"  MISSING {d.Dll}: {d.Problem}{(d.Remedy != null ? " → " + d.Remedy : "")}");
                return 0;
            }

            case "profile" when args.Length > 1:
            {
                var store = new CloudSSD.Streaming.ProfileStore(paths.DatabaseFile);
                var s = store.Summary(args[1], TimeSpan.FromMinutes(2));
                Console.WriteLine($"Sessions: {s.Sessions}, distinct blocks: {s.DistinctBlocks}, startup estimate: {ByteSize.Format(s.StartupBytesEstimate)}, last: {s.LastSession}");
                foreach (var p in store.LoadPredictorStats(args[1]))
                    Console.WriteLine($"  {p.Predictor,-12} issued {p.Issued} useful {p.Useful} wasted {p.Wasted} accuracy {(p.Accuracy is { } a ? a.ToString("P0") : "n/a")}{(p.Disabled ? " DISABLED" : "")}");
                return 0;
            }

            case "simcloud":
            {
                var root = Opt(args, "--root") ?? throw new ArgumentException("--root is required");
                var port = int.TryParse(Opt(args, "--port"), out var p) ? p : 8080;
                await using var server = new SimCloudServer(root, port)
                {
                    BandwidthMbps = double.TryParse(Opt(args, "--mbps"), out var mb) ? mb : 0,
                    Latency = TimeSpan.FromMilliseconds(double.TryParse(Opt(args, "--latency-ms"), out var lat) ? lat : 0)
                };
                Console.WriteLine($"Serving {server.Root} at {server.Url} ({server.BandwidthMbps:0} Mbps, {server.Latency.TotalMilliseconds:0} ms). Ctrl+C to stop.");
                var done = new TaskCompletionSource();
                Console.CancelKeyPress += (_, e) => { e.Cancel = true; done.TrySetResult(); };
                await done.Task;
                Console.WriteLine($"Requests {server.Requests}, bytes sent {ByteSize.Format(server.BytesSent)}");
                return 0;
            }

            default:
                Console.Error.WriteLine("Unknown command: " + cmd + "\nType 'cloudssd help' for usage.");
                return 64;
        }
    }

    private static void PrintStatus(AppPaths paths)
    {
        Console.WriteLine("\n" + new string('=', 78));
        Console.WriteLine("                        CLOUD-SSD SYSTEM DASHBOARD                             ");
        Console.WriteLine(new string('=', 78));

        // 1. Process Status
        var proc = Process.GetProcessesByName("Cloud-SSD").FirstOrDefault()
                   ?? Process.GetProcessesByName("CloudPlayX").FirstOrDefault();
        if (proc != null)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($" [Process]   RUNNING (PID: {proc.Id}, Memory: {ByteSize.Format(proc.WorkingSet64)})");
            Console.ResetColor();
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine(" [Process]   STOPPED (run 'cloudssd start' to launch background engine)");
            Console.ResetColor();
        }

        var settings = new JsonSettingsStore(paths.SettingsFile).Load();

        // 2. Virtual Drives
        Console.WriteLine("\n [Virtual Drives]");
        var virtualDrives = DriveInfo.GetDrives()
            .Where(d => d.IsReady && (d.DriveFormat.Contains("rclone", StringComparison.OrdinalIgnoreCase) ||
                                      d.Name.StartsWith("Z", StringComparison.OrdinalIgnoreCase) ||
                                      d.Name.StartsWith("Y", StringComparison.OrdinalIgnoreCase)))
            .ToList();

        if (virtualDrives.Count > 0)
        {
            foreach (var d in virtualDrives)
            {
                var letter = d.Name.TrimEnd('\\');
                var def = settings.Mounts.FirstOrDefault(m => string.Equals(m.DriveLetter, letter, StringComparison.OrdinalIgnoreCase));
                var name = def?.DisplayName ?? d.VolumeLabel;
                if (string.IsNullOrWhiteSpace(name)) name = "Virtual Cloud Drive";

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.Write($"   * {d.Name} ");
                Console.ResetColor();
                Console.WriteLine($"[{name}]  {ByteSize.Format(d.TotalFreeSpace)} Free of {ByteSize.Format(d.TotalSize)}  ({d.DriveFormat})");
            }
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.WriteLine("   No virtual drives mounted currently.");
            Console.ResetColor();
        }

        // 3. Cache Health
        Console.WriteLine("\n [Local SSD Cache]");
        try
        {
            var cDrive = new DriveInfo("C");
            Console.WriteLine($"   * Host Drive C: {ByteSize.Format(cDrive.TotalFreeSpace)} Free of {ByteSize.Format(cDrive.TotalSize)} (Min reserve: {ByteSize.Format(settings.Cache.MinFreeSpaceBytes)})");
            Console.WriteLine($"   * Cache Budget: {ByteSize.Format(settings.Cache.BudgetBytes)} (Path: {paths.CacheRootFor(settings)})");
        }
        catch { }

        // 4. Accounts
        Console.WriteLine("\n [Google Drive Accounts]");
        if (settings.AccountEmails.Count > 0)
        {
            foreach (var kvp in settings.AccountEmails)
            {
                Console.WriteLine($"   * {kvp.Key,-12} -> {kvp.Value}");
            }
        }
        else
        {
            Console.WriteLine("   * Accounts configured in rclone configuration");
        }

        // 5. Mobile Bridge
        Console.WriteLine("\n [Mobile Bridge]");
        Console.WriteLine($"   * Local Port: {settings.MobileBridge.Port} (Status: {(proc != null ? "Active" : "Offline")})");
        if (settings.MobileBridge.PairedDevices.Count > 0)
        {
            foreach (var dev in settings.MobileBridge.PairedDevices)
            {
                var st = dev.IsBlocked ? "BLOCKED" : "PAIRED";
                var lastSeenStr = dev.LastSeen != default ? dev.LastSeen.ToLocalTime().ToString("g") : "Never";
                Console.WriteLine($"   * {dev.Name} ({dev.IpAddress ?? "unknown IP"}) [{st}] - Last seen: {lastSeenStr}");
            }
        }

        Console.WriteLine(new string('=', 78) + "\n");
    }

    private static int OpenDrive(string? letter)
    {
        var target = letter?.Trim().ToUpperInvariant() ?? "Z:";
        if (!target.EndsWith(":")) target += ":";
        target += "\\";

        if (!Directory.Exists(target))
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"Notice: Drive {target} is not currently detected in Windows File System.");
            Console.ResetColor();
            return 1;
        }

        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"Opening {target} in Windows File Explorer...");
        Console.ResetColor();
        Process.Start(new ProcessStartInfo("explorer.exe", target) { UseShellExecute = true });
        return 0;
    }

    private static int StartApp()
    {
        var proc = Process.GetProcessesByName("Cloud-SSD").FirstOrDefault()
                   ?? Process.GetProcessesByName("CloudPlayX").FirstOrDefault();
        if (proc != null)
        {
            Console.WriteLine($"Cloud-SSD is already running (PID: {proc.Id}).");
            return 0;
        }

        var appPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "Cloud-SSD", "Cloud-SSD.exe");
        if (!File.Exists(appPath))
        {
            Console.Error.WriteLine($"Application executable not found at: {appPath}");
            return 1;
        }

        Console.WriteLine("Launching Cloud-SSD in background...");
        Process.Start(new ProcessStartInfo(appPath) { UseShellExecute = true });
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("Cloud-SSD started successfully.");
        Console.ResetColor();
        return 0;
    }

    private static int StopApp()
    {
        var list = Process.GetProcessesByName("Cloud-SSD").Concat(Process.GetProcessesByName("CloudPlayX")).ToList();
        if (list.Count == 0)
        {
            Console.WriteLine("Cloud-SSD is not running.");
            return 0;
        }

        foreach (var p in list)
        {
            try
            {
                Console.WriteLine($"Closing Cloud-SSD (PID: {p.Id})...");
                p.CloseMainWindow();
                if (!p.WaitForExit(3000))
                {
                    p.Kill();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Could not stop process {p.Id}: {ex.Message}");
            }
        }

        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("Cloud-SSD stopped.");
        Console.ResetColor();
        return 0;
    }

    private static void PrintDevices(AppPaths paths)
    {
        var settings = new JsonSettingsStore(paths.SettingsFile).Load();
        Console.WriteLine("\n[Connected & Paired Android Devices]");
        if (settings.MobileBridge.PairedDevices.Count == 0)
        {
            Console.WriteLine("No mobile devices currently paired.");
            return;
        }

        foreach (var dev in settings.MobileBridge.PairedDevices)
        {
            Console.WriteLine($"Device:      {dev.Name}");
            Console.WriteLine($"ID:          {dev.Id}");
            Console.WriteLine($"IP Address:  {dev.IpAddress ?? "unknown"}");
            Console.WriteLine($"Paired At:   {dev.PairedAt.ToLocalTime():g}");
            Console.WriteLine($"Last Seen:   {(dev.LastSeen != default ? dev.LastSeen.ToLocalTime().ToString("g") : "Never")}");
            Console.WriteLine($"When-Off:    PC={dev.WhenOffPc}, Device={dev.WhenOffDevice}");
            Console.WriteLine($"Transferred: To: {ByteSize.Format(dev.BytesToDevice)} | From: {ByteSize.Format(dev.BytesFromDevice)}");
            Console.WriteLine($"Status:      {(dev.IsBlocked ? "BLOCKED" : "ACTIVE")}");
            Console.WriteLine(new string('-', 50));
        }
    }

    private static void PrintCache(AppPaths paths)
    {
        var settings = new JsonSettingsStore(paths.SettingsFile).Load();
        var cacheRoot = paths.CacheRootFor(settings);
        Console.WriteLine("\n[Local SSD Cache Configuration]");
        Console.WriteLine($"Cache Root:            {cacheRoot}");
        Console.WriteLine($"Budget:                {ByteSize.Format(settings.Cache.BudgetBytes)}");
        Console.WriteLine($"Minimum Free Reserve:  {ByteSize.Format(settings.Cache.MinFreeSpaceBytes)}");
        Console.WriteLine($"Max Age:               {settings.Cache.MaxAge}");
        Console.WriteLine($"Write-back Delay:      {settings.Cache.WriteBack}");

        try
        {
            var drive = new DriveInfo(Path.GetPathRoot(cacheRoot) ?? "C:");
            Console.WriteLine($"Drive ({drive.Name}):         {ByteSize.Format(drive.TotalFreeSpace)} Free of {ByteSize.Format(drive.TotalSize)}");
        }
        catch { }
    }

    private static int CleanTempAndCache(AppPaths paths)
    {
        Console.WriteLine("Running safe cleanup of old temporary files...");
        try
        {
            var res = TempCleanup.Clean(TempCleanup.UserTempDirectory, DateTime.UtcNow);
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"Clean complete: Removed {res.Files} temporary files ({ByteSize.Format(res.Bytes)} freed).");
            Console.ResetColor();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Notice: {ex.Message}");
        }
        return 0;
    }

    private static void PrintMirror(AppPaths paths)
    {
        var settings = new JsonSettingsStore(paths.SettingsFile).Load();
        Console.WriteLine("\n[Cloud Mirror & Offload Status]");
        Console.WriteLine($"Account:       {settings.Mirror.Account}");
        Console.WriteLine($"State:         {(settings.Mirror.Paused ? "PAUSED" : "ACTIVE")}");
        Console.WriteLine($"Include System:{settings.Mirror.IncludeSystem}");
        Console.WriteLine($"Keep Trash:    {settings.Mirror.KeepTrashDays} days");
        Console.WriteLine($"Smart Offload: {(settings.SmartOffload.Enabled ? "ENABLED" : "DISABLED")}");
        Console.WriteLine($"Last Offload:  {(settings.SmartOffload.LastOffloadTime.HasValue ? settings.SmartOffload.LastOffloadTime.Value.ToLocalTime().ToString("g") : "Never")}");
        Console.WriteLine($"Offloaded:     {ByteSize.Format(settings.SmartOffload.TotalBytesOffloaded)}");
    }

    private static string[] SplitCommandLine(string input)
    {
        var list = new List<string>();
        var inQuotes = false;
        var current = new StringBuilder();

        foreach (var c in input)
        {
            if (c == '"')
            {
                inQuotes = !inQuotes;
            }
            else if (char.IsWhiteSpace(c) && !inQuotes)
            {
                if (current.Length > 0)
                {
                    list.Add(current.ToString());
                    current.Clear();
                }
            }
            else
            {
                current.Append(c);
            }
        }

        if (current.Length > 0)
        {
            list.Add(current.ToString());
        }

        return list.ToArray();
    }

    private static string? Opt(string[] args, string name)
    {
        var i = Array.IndexOf(args, name);
        return i >= 0 && i + 1 < args.Length ? args[i + 1] : null;
    }
}

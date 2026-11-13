using System.Collections.ObjectModel;
using CloudSSD.App;
using CloudSSD.Core;
using CommunityToolkit.Mvvm.ComponentModel;

namespace CloudSSD.Desktop.ViewModels;

public sealed partial class MainViewModel : ObservableObject
{
    public MainViewModel(AppHost host)
    {
        Host = host;
        Pages = new ObservableCollection<PageViewModel>
        {
            new DashboardViewModel(host, Navigate),
            new CloudDrivesViewModel(host),
            new MobileHubViewModel(host, Navigate),
            new DevicesViewModel(host, Navigate),
            new RemotePcsViewModel(host),
            new GameLibraryViewModel(host),
            new MemoryViewModel(host),
            new SpaceViewModel(host),
            new SmartCacheViewModel(host),
            new SettingsViewModel(host),
        };
        _selected = Pages[0];
        host.StateChanged += () => Ui(() =>
        {
            Selected.OnStateChanged();
            UpdateStatus(host.Metrics.Latest);
        });
        host.Metrics.Updated += m => Ui(() =>
        {
            Selected.OnMetrics(m);
            UpdateStatus(m);
        });

        // The bell at the top right: every note the app showed, newest first; a click opens its place.
        NotificationCenter.Load(System.IO.Path.Combine(host.Paths.DataRoot, "notifications.json"));
        NotificationCenter.Opener = OpenTarget;
        NotificationCenter.Changed += () => Ui(() => UnreadCount = NotificationCenter.Unread);
        UnreadCount = NotificationCenter.Unread;
    }

    // ---- notifications (the bell) ---------------------------------------------------------------------------------------

    public ObservableCollection<NotificationItem> Notifications => NotificationCenter.Items;

    [ObservableProperty] private int _unreadCount;
    [ObservableProperty] private bool _notificationsOpen;

    public bool HasUnread => UnreadCount > 0;
    public string UnreadText => UnreadCount > 99 ? "99+" : UnreadCount.ToString(System.Globalization.CultureInfo.InvariantCulture);
    public bool HasNotifications => Notifications.Count > 0;

    partial void OnUnreadCountChanged(int value)
    {
        OnPropertyChanged(nameof(HasUnread));
        OnPropertyChanged(nameof(UnreadText));
        OnPropertyChanged(nameof(HasNotifications));
    }

    partial void OnNotificationsOpenChanged(bool value)
    {
        if (value) NotificationCenter.RefreshTimes();
        OnPropertyChanged(nameof(HasNotifications));
    }

    [CommunityToolkit.Mvvm.Input.RelayCommand]
    private void ToggleNotifications() => NotificationsOpen = !NotificationsOpen;

    [CommunityToolkit.Mvvm.Input.RelayCommand]
    private void MarkAllRead() => NotificationCenter.MarkAllRead();

    [CommunityToolkit.Mvvm.Input.RelayCommand]
    private void ClearNotifications()
    {
        NotificationCenter.Clear();
        OnPropertyChanged(nameof(HasNotifications));
    }

    [CommunityToolkit.Mvvm.Input.RelayCommand]
    private void OpenNotification(NotificationItem? item)
    {
        if (item is null) return;
        NotificationsOpen = false;
        NotificationCenter.Open(item);
    }

    /// <summary>
    /// Goes to where a notification is about: "page:&lt;title&gt;", "device:&lt;id&gt;" (Devices), "perm:&lt;id&gt;" (its
    /// permissions), "access:&lt;request&gt;:&lt;device&gt;" (the request while it waits, else the device's permissions),
    /// "folder:&lt;path&gt;" (File Explorer). The window comes to the front first.
    /// </summary>
    public bool OpenTarget(string target)
    {
        var w = System.Windows.Application.Current?.MainWindow;
        if (w != null)
        {
            if (!w.IsVisible) w.Show();
            if (w.WindowState == System.Windows.WindowState.Minimized) w.WindowState = System.Windows.WindowState.Normal;
            w.Activate();
        }
        int colon = target.IndexOf(':');
        if (colon < 0) return false;
        string kind = target[..colon], rest = target[(colon + 1)..];
        switch (kind)
        {
            case "page":
                Navigate(rest);
                return true;
            case "device":
                Navigate("Devices");
                return true;
            case "perm":
                return OpenPermissions(rest);
            case "access":
            {
                var parts = rest.Split(':');
                var r = Host.MobileBridge.Access.Get(parts[0]);
                if (r is { State: "pending" })
                {
                    DeviceNotifications.ShowRequest(r);
                    return true;
                }
                // Answered or ran out: what that device may do now, where it can be changed.
                return parts.Length > 1 && OpenPermissions(parts[1]);
            }
            case "folder":
                if (!System.IO.Directory.Exists(rest)) { Navigate("Devices"); return true; }
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("explorer.exe", "\"" + rest + "\"") { UseShellExecute = true });
                return true;
        }
        return false;
    }

    private bool OpenPermissions(string deviceId)
    {
        Navigate("Devices");
        var device = Host.Settings.MobileBridge.PairedDevices.FirstOrDefault(d => d.Id == deviceId);
        if (device is null) return true;   // removed since: the Devices page is the place
        new Views.DevicePermissionsWindow(Host, device, justPaired: false, () => Navigate("Phone (Mobile Hub)"))
        { Owner = System.Windows.Application.Current?.MainWindow }.ShowDialog();
        return true;
    }

    public AppHost Host { get; }
    public ObservableCollection<PageViewModel> Pages { get; }

    [ObservableProperty] private PageViewModel _selected;
    [ObservableProperty] private string _storageSummary = "";
    [ObservableProperty] private string _drivesStatus = "No drives connected";
    [ObservableProperty] private string _rateStatus = "";
    [ObservableProperty] private string _engineStatus = "";
    [ObservableProperty] private string _gameStatus = "";
    [ObservableProperty] private string _version = "v" + (typeof(App).Assembly.GetName().Version?.ToString(3) ?? "0");

    partial void OnSelectedChanged(PageViewModel value)
    {
        value?.OnShown();
        Ui(() => LocalizationManager.TranslateTree(System.Windows.Application.Current.MainWindow));
        // The page's own view is made after this (when it is laid out): its words are translated once it is there.
        LocalizationManager.TranslateSoon(System.Windows.Application.Current?.MainWindow);
    }

    public void Navigate(string title)
    {
        if (title.Contains("Cache", StringComparison.OrdinalIgnoreCase) || title.Contains("Storage", StringComparison.OrdinalIgnoreCase))
        {
            // Storage is a page of its own in the sidebar, like PC Memory.
            var s = Pages.OfType<SmartCacheViewModel>().FirstOrDefault();
            if (s != null)
            {
                Selected = s;
                return;
            }
        }
        if (title.Contains("Accelerator", StringComparison.OrdinalIgnoreCase) || title.Contains("Speed", StringComparison.OrdinalIgnoreCase))
        {
            var s = Pages.OfType<SettingsViewModel>().FirstOrDefault();
            if (s != null)
            {
                s.SwitchSubTab("Speed");
                Selected = s;
                return;
            }
        }
        if (title.Contains("Performance", StringComparison.OrdinalIgnoreCase))
        {
            var s = Pages.OfType<SettingsViewModel>().FirstOrDefault();
            if (s != null)
            {
                s.SwitchSubTab("Performance");
                Selected = s;
                return;
            }
        }
        if (title.Contains("Diagnostics", StringComparison.OrdinalIgnoreCase) || title.Contains("Log", StringComparison.OrdinalIgnoreCase))
        {
            var s = Pages.OfType<SettingsViewModel>().FirstOrDefault();
            if (s != null)
            {
                s.SwitchSubTab("Advanced");
                Selected = s;
                return;
            }
        }
        var p = Pages.FirstOrDefault(x => x.Title.Equals(title, StringComparison.OrdinalIgnoreCase) || x.Title.Contains(title, StringComparison.OrdinalIgnoreCase));
        if (p != null) Selected = p;
    }

    private void UpdateStatus(EngineMetrics m)
    {
        // Real total over the connected accounts (asked from the provider), not a fixed marketing figure.
        StorageSummary = Host.Remotes.Count == 0 ? "No cloud account connected"
            : AccountText.Totals(Host) is { } t ? $"{ByteSize.Format(t.Total)} cloud · {t.Accounts} account(s)"
            : $"{Host.Remotes.Count(r => !AppHost.IsGeneratedType(r.Type))} account(s) connected";
        var sessions = Host.Mounts.Sessions;
        DrivesStatus = sessions.Count == 0 ? "No drives connected"
            : string.Join("  ", sessions.Select(s => $"{s.DriveLetter}: {s.State}"));
        RateStatus = m.DownloadBytesPerSec is { } r ? $"↓ {Bandwidth.BytesPerSecondToMbps(r):0.0} Mbps" : "";
        EngineStatus = Host.DiskPressure ? "Prefetch paused (disk space)" : Host.Engine.Scheduler.Active > 0 ? $"Prefetching ({Host.Engine.Queue.Count} queued)" : "";
        GameStatus = Host.CurrentLaunch is { State: Games.LaunchState.Running } l ? $"▶ {l.Game.Name}" : "";
    }

    private static void Ui(Action a)
    {
        var d = System.Windows.Application.Current?.Dispatcher;
        if (d is null) return;
        if (d.CheckAccess()) a();
        else d.InvokeAsync(a);
    }
}

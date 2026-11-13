using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Threading;
using CloudSSD.App;
using CloudSSD.Core;

namespace CloudSSD.Desktop.Views;

/// <summary>
/// A phone's files seen from this PC, as far as the phone allows (it asks its owner the first time). Folders open with
/// a double-click; a file is copied to this PC's Downloads folder. Needs the Cloud-SSD app running on the phone.
/// </summary>
public sealed class BrowsePhoneWindow : Window
{
    private sealed record Entry(string Name, string Path, bool IsDir, long Size);

    /// <summary>Asks the phone something (fs.roots, fs.list, fs.read): here, or through another PC it is paired with.</summary>
    private readonly Func<string, Dictionary<string, string>, TimeSpan, Task<PeerResult>> _ask;
    private readonly string _name;
    private readonly TextBlock _status;
    private readonly TextBlock _where;
    private readonly ListBox _list;
    private readonly Button _up, _save;
    private readonly DispatcherTimer _retry = new() { Interval = TimeSpan.FromSeconds(3) };
    private string? _path;          // null = the places the phone allows
    private int _retries;
    private bool _busy;

    private static string T(string s) => LocalizationManager.T(s);
    private static string L(string f, params object[] a) => string.Format(T(f), a);

    /// <summary>A phone paired with this PC.</summary>
    public BrowsePhoneWindow(AppHost host, PairedDevice device)
        : this(device.Name, (kind, args, timeout) => host.MobileBridge.AskDeviceAsync(device.Id, kind, args, timeout)) { }

    /// <summary>Any phone, asked through <paramref name="ask"/> (another PC's phone, through that PC).</summary>
    public BrowsePhoneWindow(string name, Func<string, Dictionary<string, string>, TimeSpan, Task<PeerResult>> ask)
    {
        _ask = ask;
        _name = name;
        Title = L("{0}'s files", name);
        Width = 620;
        Height = 560;
        WindowStartupLocation = WindowStartupLocation.CenterOwner;
        if (Application.Current?.TryFindResource("DialogWindow") is Style st) Style = st;
        SizeToContent = SizeToContent.Manual;

        var root = new DockPanel { Margin = new Thickness(22, 18, 22, 18) };
        var head = new TextBlock { Text = L("{0}'s files", name) };
        if (Application.Current?.TryFindResource("H1") is Style h1) head.Style = h1;
        DockPanel.SetDock(head, Dock.Top);
        root.Children.Add(head);

        _status = new TextBlock { TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 8) };
        if (Application.Current?.TryFindResource("Caption") is Style cap) _status.Style = cap;
        DockPanel.SetDock(_status, Dock.Top);
        root.Children.Add(_status);

        var bar = new DockPanel { Margin = new Thickness(0, 0, 0, 8) };
        _up = new Button { Content = "", Padding = new Thickness(8, 3, 8, 3), Margin = new Thickness(0, 0, 8, 0), ToolTip = T("Up") };
        if (Application.Current?.TryFindResource("IconFont") is System.Windows.Media.FontFamily icons) _up.FontFamily = icons;
        _up.Click += (_, _) => GoUp();
        DockPanel.SetDock(_up, Dock.Left);
        bar.Children.Add(_up);
        _where = new TextBlock { VerticalAlignment = VerticalAlignment.Center, TextTrimming = TextTrimming.CharacterEllipsis, FontFamily = new System.Windows.Media.FontFamily("Consolas") };
        bar.Children.Add(_where);
        DockPanel.SetDock(bar, Dock.Top);
        root.Children.Add(bar);

        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 12, 0, 0) };
        _save = new Button { Content = T("Save to this PC"), Padding = new Thickness(14, 6, 14, 6), IsEnabled = false };
        if (Application.Current?.TryFindResource("Primary") is Style p) _save.Style = p;
        _save.Click += async (_, _) => { if (_list!.SelectedItem is ListBoxItem { Tag: Entry e } && !e.IsDir) await SaveAsync(e); };
        var close = new Button { Content = T("Close"), IsCancel = true, Padding = new Thickness(14, 6, 14, 6), Margin = new Thickness(0) };
        buttons.Children.Add(_save);
        buttons.Children.Add(close);
        DockPanel.SetDock(buttons, Dock.Bottom);
        root.Children.Add(buttons);

        _list = new ListBox();
        _list.SetResourceReference(BackgroundProperty, "Surface");
        _list.SetResourceReference(ForegroundProperty, "Text");
        _list.SetResourceReference(BorderBrushProperty, "BorderBrush");
        _list.MouseDoubleClick += async (_, _) => await OpenSelectedAsync();
        _list.KeyDown += async (_, e) => { if (e.Key == Key.Enter) await OpenSelectedAsync(); else if (e.Key == Key.Back) GoUp(); };
        _list.SelectionChanged += (_, _) => _save.IsEnabled = _list.SelectedItem is ListBoxItem { Tag: Entry { IsDir: false } };
        root.Children.Add(_list);
        Content = root;

        _retry.Tick += async (_, _) => { _retry.Stop(); await LoadAsync(_path); };
        Closed += (_, _) => _retry.Stop();
        Loaded += async (_, _) => await LoadAsync(null);
    }

    private async Task OpenSelectedAsync()
    {
        if (_list.SelectedItem is not ListBoxItem { Tag: Entry e }) return;
        if (e.IsDir) await LoadAsync(e.Path);
        else await SaveAsync(e);
    }

    private void GoUp()
    {
        if (_path is null) return;
        int slash = _path.LastIndexOf('/');
        _ = LoadAsync(slash > 0 ? _path[..slash] : null);
    }

    /// <summary>The places the phone allows (null) or one folder. Asks again every few seconds while the phone's owner decides.</summary>
    private async Task LoadAsync(string? path)
    {
        if (_busy) return;
        _busy = true;
        _status.Text = L("Asking {0}…", _name);
        try
        {
            var args = new Dictionary<string, string>();
            if (path != null) args["path"] = path;
            var r = await _ask(path is null ? "fs.roots" : "fs.list", args, TimeSpan.FromSeconds(20));
            if (!IsLoaded) return;
            switch (r.Status)
            {
                case "ok":
                    _retries = 0;
                    _path = path;
                    Show(r.Json!.Value, path is null);
                    break;
                case "needs-permission" when _retries++ < 40:
                    _status.Text = L("Allow it on {0}: a note is waiting there (Allow 1 hour), or open Cloud-SSD on it.", _name);
                    _retry.Start();
                    break;
                case "timeout":
                    _status.Text = L("{0} is not answering. Open the Cloud-SSD app on it (it must be running), on the same Wi-Fi.", _name);
                    break;
                case "denied":
                    _status.Text = L("{0} does not allow that.", _name);
                    break;
                default:
                    _status.Text = r.Error ?? T("Something went wrong.");
                    break;
            }
        }
        finally { _busy = false; }
    }

    private void Show(JsonElement json, bool roots)
    {
        var entries = new List<Entry>();
        if (roots)
        {
            foreach (var r in json.GetProperty("roots").EnumerateArray())
                entries.Add(new Entry(r.GetProperty("name").GetString() ?? "", r.GetProperty("path").GetString() ?? "", true, 0));
            var scope = json.TryGetProperty("scope", out var s) && s.GetString() == "all" ? T("the whole phone storage") : T("photos, downloads, documents and music");
            _status.Text = L("{0} lets this PC see {1}.", _name, scope);
        }
        else
        {
            foreach (var f in json.GetProperty("folders").EnumerateArray())
                entries.Add(new Entry(f.GetProperty("name").GetString() ?? "", f.GetProperty("path").GetString() ?? "", true, 0));
            foreach (var f in json.GetProperty("files").EnumerateArray())
                entries.Add(new Entry(f.GetProperty("name").GetString() ?? "", f.GetProperty("path").GetString() ?? "", false, f.TryGetProperty("size", out var z) ? z.GetInt64() : 0));
            _status.Text = L("{0} folders · {1} files", entries.Count(e => e.IsDir), entries.Count(e => !e.IsDir));
        }
        _where.Text = _path is null ? "/" : "/" + _path;
        _up.IsEnabled = _path != null;
        _list.Items.Clear();
        foreach (var e in entries)
        {
            var row = new DockPanel();
            if (!e.IsDir)
            {
                var size = new TextBlock { Text = ByteSize.Format(e.Size), FontSize = 11.5, Margin = new Thickness(10, 0, 0, 0) };
                size.SetResourceReference(TextBlock.ForegroundProperty, "Muted");
                DockPanel.SetDock(size, Dock.Right);
                row.Children.Add(size);
            }
            var icon = new TextBlock { Text = e.IsDir ? "" : "", Margin = new Thickness(0, 0, 8, 0), VerticalAlignment = VerticalAlignment.Center };
            if (Application.Current?.TryFindResource("IconFont") is System.Windows.Media.FontFamily icons) icon.FontFamily = icons;
            icon.SetResourceReference(TextBlock.ForegroundProperty, "Accent");
            DockPanel.SetDock(icon, Dock.Left);
            row.Children.Add(icon);
            row.Children.Add(new TextBlock { Text = e.Name, TextTrimming = TextTrimming.CharacterEllipsis });
            _list.Items.Add(new ListBoxItem { Content = row, Tag = e, Padding = new Thickness(6, 4, 6, 4) });
        }
    }

    /// <summary>Copies one file from the phone into this PC's Downloads folder and shows it there.</summary>
    private async Task SaveAsync(Entry e)
    {
        _save.IsEnabled = false;
        _status.Text = L("Copying {0} from {1}…", e.Name, _name);
        var r = await _ask("fs.read", new Dictionary<string, string> { ["path"] = e.Path }, TimeSpan.FromMinutes(15));
        if (!IsLoaded) { if (r.FilePath != null) try { File.Delete(r.FilePath); } catch (IOException) { } return; }
        if (!r.Ok || r.FilePath is null)
        {
            _status.Text = r.Status == "needs-permission" ? L("Allow it on {0} first.", _name) : r.Error ?? T("The copy did not finish.");
            _save.IsEnabled = true;
            return;
        }
        var folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
        Directory.CreateDirectory(folder);
        var dest = Path.Combine(folder, LocalMobileBridgeService.FreeLocalName(folder, e.Name));
        File.Move(r.FilePath, dest);
        _status.Text = L("Saved to {0}", dest);
        _save.IsEnabled = true;
        try { Process.Start(new ProcessStartInfo("explorer.exe", $"/select,\"{dest}\"") { UseShellExecute = true }); } catch (System.ComponentModel.Win32Exception) { }
    }
}

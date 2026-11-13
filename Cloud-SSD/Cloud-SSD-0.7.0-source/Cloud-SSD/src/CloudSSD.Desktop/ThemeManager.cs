using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Data;
using System.Windows.Interop;
using System.Windows.Media;
using CloudSSD.Desktop.Controls;
using Microsoft.Win32;

namespace CloudSSD.Desktop;

/// <summary>
/// Dark / Light / follow-Windows colour theme for the desktop app. The palette is the first merged dictionary of the
/// application resources (Themes/Dark.xaml or Themes/Light.xaml); views use its brushes as DynamicResource, so
/// swapping it recolours every open window at once. The choice is kept in %LOCALAPPDATA%\Cloud-SSD\theme.txt.
/// </summary>
public static class ThemeManager
{
    public const string Dark = "Dark";
    public const string Light = "Light";
    public const string System = "System";

    /// <summary>Choices shown in the sidebar, in order.</summary>
    public static IReadOnlyList<ThemeOption> Options { get; } =
    [
        new(Dark, "Dark"),
        new(Light, "Light"),
        new(System, "Windows jaisa (System)"),
    ];

    /// <summary>What the user chose: Dark, Light or System.</summary>
    public static string Choice { get; private set; } = Light;

    /// <summary>The theme actually on screen (System resolved to Dark or Light).</summary>
    public static bool IsDark { get; private set; } = false;

    public static event Action? ThemeChanged;

    private static readonly string ConfigPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Cloud-SSD", "theme.txt");

    private static bool _initialized;

    /// <summary>Loads the saved choice and applies it. Call once at start-up, before the first window is shown.</summary>
    public static void Initialize()
    {
        if (_initialized) return;
        _initialized = true;
        try
        {
            if (File.Exists(ConfigPath))
            {
                var saved = File.ReadAllText(ConfigPath).Trim();
                if (Options.Any(o => o.Key == saved)) Choice = saved;
            }
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { }

        // Every window gets a title bar that matches the theme when it opens.
        EventManager.RegisterClassHandler(typeof(Window), FrameworkElement.LoadedEvent,
            new RoutedEventHandler((s, _) => { if (s is Window w) ApplyTitleBar(w); }));
        // "Windows jaisa" follows the Windows setting while the app is running.
        SystemEvents.UserPreferenceChanged += (_, e) =>
        {
            if (e.Category == UserPreferenceCategory.General && Choice == System)
                Application.Current?.Dispatcher.BeginInvoke(() => Apply(System, save: false));
        };
        Apply(Choice, save: false);
    }

    /// <summary>Switches to <paramref name="choice"/> (Dark, Light or System) and, by default, remembers it.</summary>
    public static void Apply(string choice, bool save = true)
    {
        if (Options.All(o => o.Key != choice)) choice = Dark;
        Choice = choice;
        var dark = choice switch { Light => false, System => !WindowsUsesLightApps(), _ => true };
        var app = Application.Current;
        if (app is null) return;

        var merged = app.Resources.MergedDictionaries;
        var palette = new ResourceDictionary { Source = new Uri(dark ? "Themes/Dark.xaml" : "Themes/Light.xaml", UriKind.Relative) };
        int index = -1;
        for (int i = 0; i < merged.Count; i++)
        {
            var src = merged[i].Source?.OriginalString ?? "";
            if (src.EndsWith("Dark.xaml", StringComparison.OrdinalIgnoreCase) || src.EndsWith("Light.xaml", StringComparison.OrdinalIgnoreCase)) { index = i; break; }
        }
        if (index >= 0) merged[index] = palette; else merged.Insert(0, palette);
        IsDark = dark;

        foreach (Window w in app.Windows)
        {
            ApplyTitleBar(w);
            RefreshConvertedBrushes(w);
        }

        if (save)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(ConfigPath)!);
                File.WriteAllText(ConfigPath, choice);
            }
            catch (Exception e) when (e is IOException or UnauthorizedAccessException) { }
        }
        ThemeChanged?.Invoke();
    }

    /// <summary>Windows "Choose your app mode": HKCU\...\Themes\Personalize\AppsUseLightTheme (1 = light).</summary>
    private static bool WindowsUsesLightApps()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            return key?.GetValue("AppsUseLightTheme") is int v && v != 0;
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException or global::System.Security.SecurityException)
        {
            return false;
        }
    }

    /// <summary>
    /// Brushes handed out by converters (status colours) and drawn by charts are picked once; re-run those bindings
    /// and redraw the charts so they take the new palette too.
    /// </summary>
    private static void RefreshConvertedBrushes(DependencyObject root)
    {
        var stack = new Stack<DependencyObject>();
        stack.Push(root);
        while (stack.Count > 0)
        {
            var d = stack.Pop();
            var local = d.GetLocalValueEnumerator();
            var refresh = new List<BindingExpression>();
            while (local.MoveNext())
            {
                if (BindingOperations.GetBindingExpression(d, local.Current.Property) is { ParentBinding.Converter: ToneToBrush } be)
                    refresh.Add(be);
            }
            foreach (var be in refresh) be.UpdateTarget();
            if (d is Sparkline s) s.InvalidateVisual();

            if (d is Visual or global::System.Windows.Media.Media3D.Visual3D)
            {
                int n = VisualTreeHelper.GetChildrenCount(d);
                for (int i = 0; i < n; i++) stack.Push(VisualTreeHelper.GetChild(d, i));
            }
        }
    }

    // ---- title bar --------------------------------------------------------------------------------------------------

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    private const int DwmUseImmersiveDarkMode = 20;       // Windows 10 20H1 and later
    private const int DwmUseImmersiveDarkModeOld = 19;    // Windows 10 1809-1909

    private static void ApplyTitleBar(Window w)
    {
        var hwnd = new WindowInteropHelper(w).Handle;
        if (hwnd == IntPtr.Zero) return;
        int on = IsDark ? 1 : 0;
        if (DwmSetWindowAttribute(hwnd, DwmUseImmersiveDarkMode, ref on, sizeof(int)) != 0)
            DwmSetWindowAttribute(hwnd, DwmUseImmersiveDarkModeOld, ref on, sizeof(int));
    }
}

public sealed record ThemeOption(string Key, string Label)
{
    public override string ToString() => Label;
}

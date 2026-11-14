using System.Windows;

namespace CloudSSD.Desktop;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        // Started by Windows at sign-in ("Start Cloud-SSD with Windows"): the window stays out of the way.
        if (Environment.GetCommandLineArgs().Contains(CloudSSD.App.StartWithWindows.MinimizedArgument)) WindowState = System.Windows.WindowState.Minimized;
    }

    /// <summary>The section already chosen, clicked again from a page inside it: back to the section's own page.</summary>
    private void OnNavClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if (DataContext is not ViewModels.MainViewModel vm) return;
        var item = (e.OriginalSource as DependencyObject) is { } d
            ? System.Windows.Controls.ItemsControl.ContainerFromElement((System.Windows.Controls.ItemsControl)sender, d) as System.Windows.Controls.ListBoxItem : null;
        if (item?.DataContext is ViewModels.PageViewModel top) vm.OpenTop(top);
    }
}

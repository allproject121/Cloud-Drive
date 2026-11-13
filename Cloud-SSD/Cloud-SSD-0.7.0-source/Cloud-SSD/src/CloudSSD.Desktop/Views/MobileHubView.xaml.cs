using System.Windows;
using System.Windows.Controls;
using CloudSSD.Desktop.ViewModels;

namespace CloudSSD.Desktop.Views;

public partial class MobileHubView : UserControl
{
    public MobileHubView()
    {
        InitializeComponent();
    }

    private void OnDropZoneDrop(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent(DataFormats.FileDrop))
        {
            var files = e.Data.GetData(DataFormats.FileDrop) as string[];
            if (files != null && files.Length > 0 && DataContext is MobileHubViewModel vm)
            {
                // Choose the device (or copy a link); the phone accepts it on its screen.
                var w = new SendToDevicesWindow(vm.Host, files) { Owner = Window.GetWindow(this) };
                w.ShowDialog();
                foreach (var line in w.Sent) vm.RecentTransfers.Insert(0, $"• {LocalizationManager.T("Sent")} → {line}  ({DateTime.Now:HH:mm})");
                while (vm.RecentTransfers.Count > 10) vm.RecentTransfers.RemoveAt(vm.RecentTransfers.Count - 1);
            }
        }
    }
}

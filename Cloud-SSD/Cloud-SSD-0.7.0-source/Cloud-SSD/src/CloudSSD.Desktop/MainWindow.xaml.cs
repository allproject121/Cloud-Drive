using System.Windows;
using System.Windows.Controls;

namespace CloudSSD.Desktop;

public partial class MainWindow : Window
{
    private bool _initializing = true;

    public MainWindow()
    {
        InitializeComponent();

        CmbLanguage.ItemsSource = LocalizationManager.SupportedLanguages;
        CmbLanguage.SelectedItem = LocalizationManager.CurrentLanguage;
        CmbTheme.ItemsSource = ThemeManager.Options;
        CmbTheme.SelectedItem = ThemeManager.Options.FirstOrDefault(o => o.Key == ThemeManager.Choice);
        _initializing = false;
    }

    private void OnThemeSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_initializing) return;
        if (CmbTheme.SelectedItem is ThemeOption option) ThemeManager.Apply(option.Key);
    }

    private void OnLanguageSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_initializing) return;
        if (CmbLanguage.SelectedItem is string lang)
        {
            LocalizationManager.SetLanguage(lang);
        }
    }
}

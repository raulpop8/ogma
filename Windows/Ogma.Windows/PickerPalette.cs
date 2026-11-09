using Microsoft.Win32;

namespace Ogma.Windows;

internal sealed record PickerPalette(Color Background, Color Text, Color Secondary, Color Border,
    Color Selection, Color SelectedText, Color Recent, Color Frequent)
{
    internal static PickerPalette Resolve(bool? darkOverride = null)
    {
        if (SystemInformation.HighContrast)
            return new(SystemColors.Window, SystemColors.WindowText, SystemColors.WindowText,
                SystemColors.WindowText, SystemColors.Highlight, SystemColors.HighlightText,
                SystemColors.Window, SystemColors.Window);
        var dark = darkOverride ?? UsesDarkApps();
        return dark
            ? new(Color.FromArgb(28, 28, 28), Color.FromArgb(245, 245, 245), Color.FromArgb(197, 197, 197),
                Color.FromArgb(96, 96, 96), Color.FromArgb(0, 90, 158), Color.White,
                Color.FromArgb(69, 60, 38), Color.FromArgb(36, 59, 80))
            : new(Color.White, Color.FromArgb(32, 32, 32), Color.FromArgb(93, 93, 93),
                Color.FromArgb(189, 189, 189), Color.FromArgb(0, 90, 158), Color.White,
                Color.FromArgb(255, 242, 204), Color.FromArgb(230, 241, 255));
    }

    private static bool UsesDarkApps()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            return key?.GetValue("AppsUseLightTheme") is int value && value == 0;
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException or System.Security.SecurityException)
        { return false; }
    }
}

using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
using Ogma.Core;
using Ogma.Windows;

internal static class StoreScreenshots
{
    // Render the actual app windows with sample data on an isolated Windows
    // runner. No generated mockups, overlays, or changes to production UI.
    internal static void Capture(string outputDirectory)
    {
        if (Environment.GetEnvironmentVariable("GITHUB_ACTIONS") != "true")
            throw new InvalidOperationException("Store capture runs only on an isolated GitHub Actions Windows runner.");

        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);
        var store = new LocalStore();
        if (Directory.Exists(store.DirectoryPath))
            throw new InvalidOperationException("Capture requires a clean app-data directory; existing user data will not be altered.");
        Directory.CreateDirectory(outputDirectory);
        try
        {
            store.SaveSnippet(null, "email", "hello@example.com", true);
            store.SaveSnippet(null, "meeting", "Thanks for your time. I'll send a summary shortly.", true);
            store.SaveSnippet(null, "signature", "Best regards,\r\nAlex", true);
            store.Preferences.DateFormat = DateDisplayFormat.Iso8601;
            store.SavePreferences();

            using var app = new TrayApplication();
            var showSettings = typeof(TrayApplication).GetMethod("ShowSettings", BindingFlags.Instance | BindingFlags.NonPublic)
                ?? throw new InvalidOperationException("Could not find the app's Settings action.");
            showSettings.Invoke(app, null);
            var settings = Application.OpenForms.OfType<SettingsWindow>().Single();
            settings.StartPosition = FormStartPosition.Manual;
            settings.WindowState = FormWindowState.Normal;
            settings.Bounds = new Rectangle(0, 0, 1366, 768);

            Exception? failure = null;
            var stage = 0;
            using var timer = new System.Windows.Forms.Timer { Interval = 800 };
            timer.Tick += (_, _) =>
            {
                try
                {
                    if (stage == 0)
                    {
                        if (!Descendants(settings).OfType<Label>().Any(c => c.Text == "Keyboard listener: Ready"))
                            throw new InvalidOperationException("The real app keyboard listener did not become ready.");
                        Save(settings, outputDirectory, "01-general-settings.png");
                        var tabs = settings.Controls.OfType<TabControl>().Single();
                        tabs.SelectedIndex = 1;
                        var list = Descendants(settings).OfType<ListBox>().Single();
                        list.SelectedItem = list.Items.OfType<TextSnippet>().Single(s => s.Trigger == "email");
                        stage++;
                    }
                    else if (stage == 1)
                    {
                        Save(settings, outputDirectory, "02-text-shortcuts.png");
                        var list = Descendants(settings).OfType<ListBox>().Single();
                        list.SelectedItem = list.Items.OfType<TextSnippet>().Single(s => s.Trigger == "signature");
                        stage++;
                    }
                    else
                    {
                        Save(settings, outputDirectory, "03-multiline-shortcut.png");
                        timer.Stop();
                        app.ExitThread();
                    }
                }
                catch (Exception e)
                {
                    failure = e;
                    timer.Stop();
                    app.ExitThread();
                }
            };
            timer.Start();
            Application.Run(app);
            if (failure != null) throw new InvalidOperationException("Store screenshot capture failed.", failure);
            Console.WriteLine("Captured three actual Windows app screenshots at 1366 × 768 using sample shortcuts.");
        }
        finally
        {
            if (Directory.Exists(store.DirectoryPath)) Directory.Delete(store.DirectoryPath, recursive: true);
        }
    }

    private static System.Collections.Generic.IEnumerable<Control> Descendants(Control parent)
    {
        foreach (Control child in parent.Controls)
        {
            yield return child;
            foreach (var descendant in Descendants(child)) yield return descendant;
        }
    }

    private static void Save(Form window, string directory, string name)
    {
        window.PerformLayout();
        window.Refresh();
        if (window.Width != 1366 || window.Height != 768)
            throw new InvalidOperationException($"Unexpected window size: {window.Width} × {window.Height}.");
        using var bitmap = new Bitmap(window.Width, window.Height);
        window.DrawToBitmap(bitmap, new Rectangle(Point.Empty, window.Size));
        bitmap.Save(Path.Combine(directory, name), ImageFormat.Png);
    }
}

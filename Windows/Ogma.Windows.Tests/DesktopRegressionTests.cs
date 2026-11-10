using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Ogma.Core;
using Ogma.Windows;

internal static class DesktopRegressionTests
{
    internal static void Run(string outputDirectory)
    {
        if (Environment.GetEnvironmentVariable("GITHUB_ACTIONS") != "true")
            throw new InvalidOperationException("Input tests may run only on the isolated Windows CI desktop.");
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles();
        Directory.CreateDirectory(outputDirectory);
        VerifyRendering(outputDirectory);
        VerifyInput();
    }

    private static void Require(bool condition, string message)
    {
        if (!condition) throw new InvalidOperationException(message);
    }

    private static void VerifyRendering(string directory)
    {
        using var renderer = new ColorEmojiRenderer();
        foreach (var dark in new[] { false, true })
        {
            var palette = PickerPalette.Resolve(dark);
            foreach (var background in new[] { palette.Background, palette.Recent, palette.Frequent })
                Require(Contrast(palette.Text, background) >= 4.5, "Picker text must contrast with every background.");
            Require(Contrast(palette.Secondary, palette.Background) >= 4.5, "Picker footer contrast.");
            Require(Contrast(palette.SelectedText, palette.Selection) >= 4.5, "Picker selected text contrast.");
            using var glyph = new Bitmap(64, 64);
            using (var graphics = Graphics.FromImage(glyph))
            {
                graphics.Clear(palette.Background);
                Require(renderer.TryDraw(graphics, new[] { new EmojiGlyph("😊", new RectangleF(0, 0, 64, 64), palette.Text, palette.Background) }, 1),
                    "DirectWrite emoji rendering failed: " + renderer.LastError);
            }
            var yellowPixels = 0;
            for (var y = 0; y < glyph.Height; y++)
                for (var x = 0; x < glyph.Width; x++)
                {
                    var pixel = glyph.GetPixel(x, y);
                    if (pixel.R > 170 && pixel.G > 80 && pixel.B < 110 && pixel.R - pixel.B > 80) yellowPixels++;
                }
            Require(yellowPixels > 40, "Emoji must contain colored pixels, not just monochrome outlines.");
            var sample = new[]
            {
                new Suggestion("smiling face with smiling eyes", "😊", "😊", "smile"),
                new Suggestion("face with tears of joy", "😂", "😂", "joy"),
                new Suggestion("red heart", "❤️", "❤️", "heart"),
                new Suggestion("thumbs up", "👍", "👍", "thumbs"),
                new Suggestion("party popper", "🎉", "🎉", "party")
            };
            foreach (var grid in new[] { true, false })
            {
                using var panel = new SuggestionWindow(dark);
                panel.Present(sample, new Rectangle(20, 20, 1, 20), grid);
                panel.Refresh();
                using var capture = new Bitmap(panel.Width, panel.Height);
                panel.DrawToBitmap(capture, new Rectangle(Point.Empty, panel.Size));
                capture.Save(Path.Combine(directory, $"picker-{(dark ? "dark" : "light")}-{(grid ? "grid" : "list")}.png"), ImageFormat.Png);
                var scale = panel.DeviceDpi / 96f;
                var visibleColor = 0;
                for (var y = (int)(36 * scale); y < Math.Min(capture.Height, 82 * scale); y++)
                    for (var x = (int)(12 * scale); x < Math.Min(capture.Width, 58 * scale); x++)
                    {
                        var p = capture.GetPixel(x, y);
                        if (p.R > 170 && p.G > 80 && p.B < 110 && p.R - p.B > 80) visibleColor++;
                    }
                Require(visibleColor > 40, "The actual picker must display the smile emoji in color.");
            }
        }
        Console.WriteLine("Color emoji pixels and light/dark picker contrast checks passed.");
    }

    private static double Contrast(Color a, Color b)
    {
        static double L(Color c)
        {
            static double Linear(byte value) { var s = value / 255d; return s <= 0.04045 ? s / 12.92 : Math.Pow((s + 0.055) / 1.055, 2.4); }
            return 0.2126 * Linear(c.R) + 0.7152 * Linear(c.G) + 0.0722 * Linear(c.B);
        }
        var first = L(a); var second = L(b);
        return (Math.Max(first, second) + 0.05) / (Math.Min(first, second) + 0.05);
    }

    private static void VerifyInput()
    {
        Exception? failure = null;
        using var form = new Form { Text = "Ogma input regression — test data only", Width = 600, Height = 400 };
        using var plain = new TextBox { Multiline = true, Dock = DockStyle.Top, Height = 140 };
        using var rich = new RichTextBox { Dock = DockStyle.Fill };
        form.Controls.Add(rich); form.Controls.Add(plain);
        form.Shown += async (_, _) =>
        {
            try
            {
                var romanian = new DateTime(2026, 11, 9).ToString("D", CultureInfo.GetCultureInfo("ro-RO"));
                var replacements = new[] { romanian, "2026-11-09", "noiembrie șțăîâ", "😊 ❤️ 👨‍👩‍👧‍👦", "第一行\r\n第二行" };
                foreach (var editor in new TextBoxBase[] { plain, rich })
                {
                    foreach (var replacement in replacements.Concat(Enumerable.Repeat(romanian, 5)))
                    {
                        editor.Text = "Before /date after";
                        editor.Select("Before /date".Length, 0);
                        form.Activate(); editor.Focus();
                        SetForegroundWindow(form.Handle);
                        await System.Threading.Tasks.Task.Delay(80);
                        var focus = NativeMethods.ForegroundInfo().Focus;
                        Require(NativeMethods.GetForegroundWindow() == form.Handle && focus == editor.Handle, "Test editor did not receive focus.");
                        var snapshot = new FocusSnapshot(form.Handle, focus, Array.Empty<int>(), Rectangle.Empty);
                        Require(await TextInsertionService.ReplaceAsync(snapshot, 5, replacement), "Paced Unicode insertion failed.");
                        await System.Threading.Tasks.Task.Delay(80);
                        var expected = "Before " + replacement.Replace("\r\n", "\n").Replace('\r', '\n') + " after";
                        var actual = editor.Text.Replace("\r\n", "\n").Replace('\r', '\n');
                        Require(actual == expected, $"{editor.GetType().Name}: received '{actual}' instead of '{expected}'.");
                    }
                    editor.Text = "/date"; editor.Select(editor.TextLength, 0); editor.Focus();
                    await System.Threading.Tasks.Task.Delay(30);
                    var target = new FocusSnapshot(form.Handle, editor.Handle, Array.Empty<int>(), Rectangle.Empty);
                    Require(!await TextInsertionService.ReplaceAsync(target, 5, "must not be inserted", () => false), "Cancelled insertion must not run.");
                    Require(editor.Text == "/date", "Cancelled insertion altered the editor.");
                    var checks = 0;
                    Require(!await TextInsertionService.ReplaceAsync(target, 5, "must stop", () => ++checks < 3), "Interrupted insertion must stop.");
                    Require(editor.Text == (editor is RichTextBox ? "/date" : "/dat"), "Insertion continued after its cancellation guard changed.");
                }
                Console.WriteLine("Insertion passed in native TextBox and RichTextBox: Romanian dates, diacritics, emoji, joined sequences, CJK, multiline, surrounding text preservation, and cancellation.");
            }
            catch (Exception e) { failure = e; }
            finally { form.Close(); }
        };
        Application.Run(form);
        if (failure != null) throw new InvalidOperationException("Desktop input regression failed.", failure);
    }

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetForegroundWindow(nint window);
}

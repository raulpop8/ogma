using System;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows.Forms;
using Ogma.Core;
using Ogma.Windows;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        if (args.Length == 2 && args[0] == "--capture")
        {
            StoreScreenshots.Capture(args[1]);
            return;
        }
        if (args.Length == 2 && args[0] == "--desktop-tests")
        {
            DesktopRegressionTests.Run(args[1]);
            return;
        }
        void Check(bool condition, string message)
        {
            if (!condition) throw new Exception(message);
        }
        // Incorrect union padding silently breaks SendInput on 64-bit Windows.
        Check(Marshal.SizeOf<NativeMethods.Input>() == (Environment.Is64BitProcess ? 40 : 28), "INPUT ABI size");
        Check(Marshal.OffsetOf<NativeMethods.Input>(nameof(NativeMethods.Input.Data)).ToInt32() == (Environment.Is64BitProcess ? 8 : 4), "INPUT union alignment");
        Check(Marshal.SizeOf<NativeMethods.KeyboardInput>() == (Environment.Is64BitProcess ? 24 : 16), "KEYBDINPUT ABI size");
        Check(NativeMethods.GetModuleHandleW(null) != 0, "Windows module import");

        const string replacement = "👨‍👩‍👧‍👦\r\n第二行\n";
        var inputs = TextInsertionService.CreateInputs(4, replacement);
        Check(inputs.Length == 8 + (replacement.Length - 1) * 2, "UTF-16 unit count, including CRLF normalization");
        Check(inputs.All(i => i.Type == NativeMethods.InputKeyboard && i.Data.Keyboard.ExtraInfo == NativeMethods.EventMarker), "Replacement events are marked");
        Check(inputs.Take(8).All(i => i.Data.Keyboard.VirtualKey == 8), "Only trigger characters are erased");
        Check(inputs.Skip(8).All(i => i.Data.Keyboard.VirtualKey == 0 && (i.Data.Keyboard.Flags & NativeMethods.Unicode) != 0), "Replacement uses Unicode, never Return commands");
        var actual = new string(inputs.Skip(8).Where(i => (i.Data.Keyboard.Flags & NativeMethods.KeyUp) == 0).Select(i => (char)i.Data.Keyboard.Scan).ToArray());
        Check(actual == "👨‍👩‍👧‍👦\r第二行\r", "Preserve joined emoji, non-Latin text, and line breaks");

        var assembly = typeof(TrayApplication).Assembly;
        using var catalog = assembly.GetManifestResourceStream("Ogma.Resources.emoji.json") ?? throw new Exception("Missing embedded catalog");
        Check(JsonSerializer.Deserialize<EmojiItem[]>(catalog, LocalStore.JsonOptions)!.Length >= 3900, "Embedded catalog is usable");
        using var stream = assembly.GetManifestResourceStream("Ogma.Assets.Ogma.ico") ?? throw new Exception("Missing icon");
        using var icon = new Icon(stream);
        Check(icon.Width > 0, "Windows icon is usable");

        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        using var panel = new SuggestionWindow();
        // Create a hidden HWND: check native styles without installing hooks or
        // sending any input to the CI desktop.
        Check((NativeMethods.GetWindowLong(panel.Handle, -20) & 0x08000000) != 0, "Picker cannot activate its window");
        Check(!panel.Visible && !panel.ShowInTaskbar, "Hidden tray picker stays out of the taskbar");
        Console.WriteLine("Windows interop, Unicode payload, embedded resources, and picker window checks passed.");
    }
}

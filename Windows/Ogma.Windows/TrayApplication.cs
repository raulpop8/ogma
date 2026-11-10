using System.ComponentModel;
using System.Reflection;
using System.Text.Json;
using Ogma.Core;

namespace Ogma.Windows;

internal sealed class TrayApplication : ApplicationContext
{
    private readonly Control dispatcher = new();
    private readonly KeyboardMonitor monitor = new();
    private readonly TriggerEngine trigger = new();
    private readonly FocusService focus = new();
    private readonly LocalStore store = new();
    private readonly SuggestionService suggestions;
    private readonly SuggestionWindow panel = new();
    private readonly NotifyIcon tray;
    private readonly Icon icon;
    private readonly ToolStripMenuItem enabledItem;
    private readonly System.Windows.Forms.Timer updateTimer = new() { Interval = 35 };
    private readonly System.Windows.Forms.Timer focusTimer = new() { Interval = 100 };
    private SettingsWindow? settings;
    private FocusSnapshot? snapshot;
    private int[]? targetRuntimeId;
    private nint targetWindow, targetFocus;
    private int revision, insertionRevision;
    private bool enabled = true, updating, disposed;
    private string listenerStatus = "Ready";

    public TrayApplication()
    {
        _ = dispatcher.Handle;
        var assembly = Assembly.GetExecutingAssembly();
        using var catalog = assembly.GetManifestResourceStream("Ogma.Resources.emoji.json")
            ?? throw new IOException("The emoji catalog is missing.");
        var items = JsonSerializer.Deserialize<EmojiItem[]>(catalog, LocalStore.JsonOptions)
            ?? throw new IOException("The emoji catalog is invalid.");
        suggestions = new SuggestionService(new EmojiSearch(items), store);
        using var iconStream = assembly.GetManifestResourceStream("Ogma.Assets.Ogma.ico")
            ?? throw new IOException("The Ogma icon is missing.");
        icon = new Icon(iconStream);
        var menu = new ContextMenuStrip();
        enabledItem = new ToolStripMenuItem("Enable Ogma") { Checked = true, CheckOnClick = false };
        enabledItem.Click += (_, _) => SetEnabled(!enabled);
        menu.Items.Add(enabledItem);
        menu.Items.Add("Settings…", null, (_, _) => ShowSettings());
        menu.Items.Add("View releases", null, (_, _) => System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("https://github.com/raulpop8/ogma/releases") { UseShellExecute = true }));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Quit Ogma", null, (_, _) => ExitThread());
        tray = new NotifyIcon { Icon = icon, Text = "Ogma · emoji and text shortcuts", ContextMenuStrip = menu, Visible = true };
        tray.DoubleClick += (_, _) => ShowSettings();
        monitor.OnKey = HandleKey;
        monitor.OnPointerDown = point => { if (!panel.Visible || !panel.Bounds.Contains(point)) Cancel(); };
        panel.OnSelect += Choose;
        updateTimer.Tick += async (_, _) => { updateTimer.Stop(); await UpdateSuggestions(); };
        focusTimer.Tick += (_, _) =>
        {
            if (trigger.IsActive && (NativeMethods.GetForegroundWindow() != targetWindow || NativeMethods.ForegroundInfo().Focus != targetFocus)) Cancel();
        };
        focusTimer.Start();
        SetEnabled(true);
        // Make the tray-only app discoverable on its first run.
        var firstLaunch = !File.Exists(Path.Combine(store.DirectoryPath, "preferences.json"));
        if (firstLaunch)
        {
            try { store.SavePreferences(); }
            catch (Exception e) when (LocalStore.IsStorageError(e)) { Notify("Could not save preferences", e.Message); }
        }
        if (firstLaunch || store.SnippetLoadError != null || store.PreferencesLoadError != null) dispatcher.BeginInvoke(ShowSettings);
    }

    private void Post(Action action) { if (!disposed) dispatcher.BeginInvoke(action); }

    private void SetEnabled(bool value)
    {
        enabled = value;
        Cancel();
        monitor.Stop();
        listenerStatus = "Off";
        if (value)
        {
            try { monitor.Start(); listenerStatus = "Ready"; }
            catch (Win32Exception e) { enabled = false; listenerStatus = "Could not start"; Notify("Keyboard listener could not start", e.Message); }
        }
        enabledItem.Checked = enabled;
        tray.Text = enabled ? "Ogma · emoji and text shortcuts" : "Ogma · paused";
        settings?.UpdateStatus(enabled, listenerStatus);
    }

    private void ShowSettings()
    {
        Cancel();
        if (settings == null || settings.IsDisposed)
        {
            settings = new SettingsWindow(store, enabled, icon, SetEnabled);
            settings.UpdateStatus(enabled, listenerStatus);
        }
        settings.Show();
        settings.WindowState = FormWindowState.Normal;
        settings.Activate();
    }

    private bool HandleKey(KeyKind key, string text)
    {
        insertionRevision++;
        if (!enabled) return false;
        var window = NativeMethods.GetForegroundWindow();
        var info = NativeMethods.ForegroundInfo();
        NativeMethods.GetWindowThreadProcessId(window, out var pid);
        if (pid == Environment.ProcessId || window == 0 || FocusService.IsNativePassword(info.Focus)) { Cancel(); return false; }
        if (trigger.IsActive && (targetWindow != window || targetFocus != info.Focus)) { Cancel(); return false; }
        var wasActive = trigger.IsActive;
        // Until the displayed results match the current query, navigation keeps
        // its normal editor behavior. Never swallow keys for a hidden picker.
        if (key is KeyKind.Up or KeyKind.Down or KeyKind.Left or KeyKind.Right or KeyKind.Enter or KeyKind.Escape
            && wasActive && (!panel.HasResults || snapshot == null || updateTimer.Enabled || updating)) { Cancel(); return false; }
        var outcome = trigger.Handle(key, text);
        if (!wasActive && trigger.IsActive) { targetWindow = window; targetFocus = info.Focus; }
        switch (outcome)
        {
            case Outcome.Updated:
                revision++;
                snapshot = null;
                panel.Hide();
                updateTimer.Stop();
                updateTimer.Start();
                return false;
            case Outcome.Previous: panel.MoveSelection(-1, vertical: true); return true;
            case Outcome.Next: panel.MoveSelection(1, vertical: true); return true;
            case Outcome.Left: panel.MoveSelection(-1); return true;
            case Outcome.Right: panel.MoveSelection(1); return true;
            case Outcome.Accept:
                var ticket = insertionRevision;
                if (panel.SelectedItem is { } item) Post(() => { if (ticket == insertionRevision) Choose(item); });
                return true;
            case Outcome.CancelAndConsume: Cancel(); return true;
            case Outcome.Cancel: Cancel(); return false;
            default: return false;
        }
    }

    private async Task UpdateSuggestions()
    {
        if (updating) { updateTimer.Start(); return; }
        if (!trigger.IsActive) return;
        var current = revision;
        var window = targetWindow;
        updating = true;
        var result = await focus.InspectAsync(window);
        updating = false;
        if (disposed || current != revision || !trigger.IsActive) return;
        if (result == null || result.FocusHandle != targetFocus
            || targetRuntimeId != null && !result.RuntimeId.SequenceEqual(targetRuntimeId)) { Cancel(); return; }
        targetRuntimeId ??= result.RuntimeId;
        snapshot = result;
        var mode = trigger.Mode!.Value;
        var items = suggestions.Search(mode, trigger.Query);
        panel.Present(items, result.Anchor, mode == TriggerMode.Emoji && store.Preferences.PickerLayout == PickerLayout.Grid);
    }

    private async void Choose(Suggestion item)
    {
        if (!trigger.IsActive || snapshot == null) return;
        var target = snapshot;
        var length = trigger.TypedLength;
        Cancel();
        var ticket = insertionRevision;
        var current = await focus.InspectAsync(target.Window);
        if (disposed || ticket != insertionRevision || current == null || current.FocusHandle != target.FocusHandle
            || !current.RuntimeId.SequenceEqual(target.RuntimeId)) return;
        // Wait for Enter/mouse dispatch and any physically held Shift to finish.
        for (var i = 0; i < 20 && NativeMethods.IsDown(0x10); i++) await Task.Delay(10);
        if (disposed || ticket != insertionRevision || !FocusService.Matches(current)) return;
        if (!await TextInsertionService.ReplaceAsync(current, length, item.InsertionText,
                () => !disposed && ticket == insertionRevision))
        {
            if (!disposed && ticket == insertionRevision && FocusService.Matches(current))
                Notify("Could not insert text", "The editor may not accept simulated typing. Insertion stopped; check the text before trying again.");
            return;
        }
        if (disposed) return;
        try { suggestions.Record(item); }
        catch (Exception e) when (LocalStore.IsStorageError(e)) { Notify("Could not save emoji usage", e.Message); }
    }

    private void Cancel()
    {
        revision++;
        insertionRevision++;
        trigger.Reset();
        targetWindow = targetFocus = 0;
        snapshot = null;
        targetRuntimeId = null;
        updateTimer.Stop();
        panel.Hide();
    }

    private void Notify(string title, string message)
    {
        tray.BalloonTipTitle = title;
        tray.BalloonTipText = message;
        tray.ShowBalloonTip(5000);
    }

    protected override void ExitThreadCore()
    {
        monitor.Stop();
        tray.Visible = false;
        base.ExitThreadCore();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing && !disposed)
        {
            disposed = true;
            monitor.Dispose();
            updateTimer.Dispose();
            focusTimer.Dispose();
            settings?.Dispose();
            panel.Dispose();
            tray.ContextMenuStrip?.Dispose();
            tray.Dispose();
            icon.Dispose();
            dispatcher.Dispose();
        }
        base.Dispose(disposing);
    }
}

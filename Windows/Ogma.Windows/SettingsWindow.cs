using Ogma.Core;

namespace Ogma.Windows;

internal sealed class SettingsWindow : Form
{
    private readonly LocalStore store;
    private readonly ListBox shortcuts = new() { Dock = DockStyle.Fill, DisplayMember = nameof(TextSnippet.Trigger), IntegralHeight = false };
    private readonly Label status = new() { AutoSize = true };
    private readonly CheckBox enabled = new() { Text = "Enable Ogma", AutoSize = true };
    private readonly TextBox trigger = new() { Dock = DockStyle.Fill, MaxLength = 32, AccessibleName = "Shortcut name" };
    private readonly TextBox replacement = new() { Dock = DockStyle.Fill, Multiline = true, AcceptsReturn = true, ScrollBars = ScrollBars.Vertical, AccessibleName = "Replacement text" };
    private readonly CheckBox shortcutEnabled = new() { Text = "Shortcut enabled", AutoSize = true, Checked = true };
    private readonly Label error = new() { AutoSize = true, ForeColor = Color.Firebrick, MaximumSize = new Size(400, 0) };
    private Guid? editing;
    private bool updatingStatus;

    public SettingsWindow(LocalStore store, bool isEnabled, Icon icon, Action<bool> setEnabled)
    {
        this.store = store;
        Icon = icon;
        Text = "Ogma Settings";
        Font = new Font("Segoe UI", 10);
        StartPosition = FormStartPosition.CenterScreen;
        AutoScaleMode = AutoScaleMode.Dpi;
        MinimumSize = new Size(720, 530);
        ClientSize = new Size(780, 550);
        var tabs = new TabControl { Dock = DockStyle.Fill };
        var general = new TabPage("General") { Padding = new Padding(20), AutoScroll = true };
        var generalContent = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true };
        generalContent.Controls.Add(new Label { Text = "Ogma", AutoSize = true, Font = new Font(Font.FontFamily, 22, FontStyle.Bold) });
        generalContent.Controls.Add(new Label { Text = "Emoji and text shortcuts · Windows preview " + Application.ProductVersion, AutoSize = true, Margin = new Padding(3, 0, 3, 20) });
        enabled.Checked = isEnabled;
        enabled.CheckedChanged += (_, _) => { if (!updatingStatus) setEnabled(enabled.Checked); };
        generalContent.Controls.Add(enabled);
        generalContent.Controls.Add(status);
        generalContent.Controls.Add(new Label
        {
            Text = "Type : for emoji, / for saved text, or /date for today's date.\nUse arrow keys to choose, Enter to insert, and Escape to close.",
            AutoSize = true, Margin = new Padding(3, 16, 3, 20)
        });
        AddChoice(generalContent, "Emoji picker", new[] { "Five-column grid", "Named list" }, (int)store.Preferences.PickerLayout,
            i => store.Preferences.PickerLayout = (PickerLayout)i);
        AddChoice(generalContent, "Date format", new[] { "System short", "System long", "YYYY-MM-DD" }, (int)store.Preferences.DateFormat,
            i => store.Preferences.DateFormat = (DateDisplayFormat)i);
        generalContent.Controls.Add(new Label
        {
            Text = "Ogma runs in the notification area. Close this window to keep it running.\nShortcuts and emoji usage stay on this PC. Ogma does not use the clipboard.\nWindows prevents insertion into apps running as administrator.",
            AutoSize = true, Margin = new Padding(3, 20, 3, 12)
        });
        var updates = new Button { Text = "View releases", AutoSize = true };
        updates.Click += (_, _) => System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("https://github.com/raulpop8/ogma/releases") { UseShellExecute = true });
        generalContent.Controls.Add(updates);
        general.Controls.Add(generalContent);
        tabs.TabPages.Add(general);
        tabs.TabPages.Add(BuildShortcuts());
        Controls.Add(tabs);
        ReloadShortcuts();
        if (store.SnippetLoadError != null) error.Text = "Saved shortcuts could not be read. The file was left unchanged.\n" + store.SnippetLoadError;
        if (store.PreferencesLoadError != null)
            generalContent.Controls.Add(new Label { Text = "Saved preferences could not be read. The file was left unchanged.\n" + store.PreferencesLoadError, AutoSize = true, ForeColor = Color.Firebrick, MaximumSize = new Size(640, 0) });
    }

    public void UpdateStatus(bool value, string text)
    {
        updatingStatus = true;
        enabled.Checked = value;
        updatingStatus = false;
        status.Text = "Keyboard listener: " + text;
    }

    private void AddChoice(FlowLayoutPanel parent, string title, string[] options, int selected, Action<int> change)
    {
        parent.Controls.Add(new Label { Text = title, AutoSize = true, Margin = new Padding(3, 10, 3, 3) });
        var choice = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 260, AccessibleName = title };
        choice.Items.AddRange(options);
        choice.SelectedIndex = Math.Clamp(selected, 0, options.Length - 1);
        choice.SelectedIndexChanged += (_, _) =>
        {
            change(choice.SelectedIndex);
            try { store.SavePreferences(); }
            catch (Exception e) when (LocalStore.IsStorageError(e)) { MessageBox.Show(this, e.Message, "Could not save preferences", MessageBoxButtons.OK, MessageBoxIcon.Error); }
        };
        parent.Controls.Add(choice);
    }

    private TabPage BuildShortcuts()
    {
        var page = new TabPage("Shortcuts") { Padding = new Padding(16) };
        var layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1 };
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 32));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 68));
        var left = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 2, ColumnCount = 1, Padding = new Padding(0, 0, 16, 0) };
        left.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        left.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        shortcuts.AccessibleName = "Saved shortcuts";
        shortcuts.SelectedIndexChanged += (_, _) =>
        {
            if (shortcuts.SelectedItem is not TextSnippet s) return;
            editing = s.Id; trigger.Text = s.Trigger; replacement.Text = s.Replacement; shortcutEnabled.Checked = s.IsEnabled; error.Text = "";
        };
        left.Controls.Add(shortcuts, 0, 0);
        var add = new Button { Text = "New shortcut", AutoSize = true };
        add.Click += (_, _) => { shortcuts.ClearSelected(); editing = null; trigger.Clear(); replacement.Clear(); shortcutEnabled.Checked = true; error.Text = ""; trigger.Focus(); };
        left.Controls.Add(add, 0, 1);
        var right = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 7 };
        right.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        right.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        right.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        right.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        for (var i = 0; i < 3; i++) right.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        right.Controls.Add(new Label { Text = "Shortcut name (without /)", AutoSize = true }, 0, 0);
        right.Controls.Add(trigger, 0, 1);
        right.Controls.Add(new Label { Text = "Replacement text", AutoSize = true, Margin = new Padding(3, 16, 3, 6) }, 0, 2);
        right.Controls.Add(replacement, 0, 3);
        right.Controls.Add(shortcutEnabled, 0, 4);
        right.Controls.Add(error, 0, 5);
        var actions = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill };
        var save = new Button { Text = "Save shortcut", AutoSize = true };
        save.Click += (_, _) => Save();
        var delete = new Button { Text = "Delete", AutoSize = true };
        delete.Click += (_, _) =>
        {
            if (editing is not { } id) return;
            if (MessageBox.Show(this, "Delete /" + trigger.Text + "?", "Delete shortcut", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
            try { store.DeleteSnippet(id); editing = null; trigger.Clear(); replacement.Clear(); error.Text = ""; ReloadShortcuts(); }
            catch (Exception e) when (LocalStore.IsStorageError(e)) { error.Text = e.Message; }
        };
        actions.Controls.Add(save);
        actions.Controls.Add(delete);
        right.Controls.Add(actions, 0, 6);
        layout.Controls.Add(left, 0, 0);
        layout.Controls.Add(right, 1, 0);
        page.Controls.Add(layout);
        return page;
    }

    private void ReloadShortcuts()
    {
        shortcuts.Items.Clear();
        foreach (var snippet in store.Snippets.OrderBy(s => s.Trigger, StringComparer.Ordinal)) shortcuts.Items.Add(snippet);
    }

    private void Save()
    {
        try
        {
            store.SaveSnippet(editing, trigger.Text, replacement.Text, shortcutEnabled.Checked);
            editing = store.Snippets.First(s => s.Trigger == trigger.Text.Trim().ToLowerInvariant()).Id;
            error.Text = "";
            ReloadShortcuts();
            shortcuts.SelectedItem = store.Snippets.First(s => s.Id == editing);
        }
        catch (Exception e) when (e is ArgumentException || LocalStore.IsStorageError(e)) { error.Text = e.Message; }
    }
}

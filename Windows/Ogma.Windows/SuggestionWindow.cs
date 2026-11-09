using Ogma.Core;
using Microsoft.Win32;

namespace Ogma.Windows;

internal sealed class SuggestionWindow : Form
{
    private IReadOnlyList<Suggestion> items = [];
    private bool grid;
    private int selected, firstRow;
    private readonly Font emojiFont = new("Segoe UI Emoji", 30, FontStyle.Regular, GraphicsUnit.Pixel);
    private readonly Font labelFont = new("Segoe UI", 12, FontStyle.Regular, GraphicsUnit.Pixel);
    private readonly ToolTip tooltip = new();
    private readonly ColorEmojiRenderer colorEmoji = new();
    private readonly bool? darkOverride;
    private PickerPalette palette = PickerPalette.Resolve();
    private const int Header = 34, Footer = 32, Rows = 6, Cell = 52;
    private Rectangle anchor;
    private int Columns => grid ? 5 : 1;
    private int RowHeight => grid ? Cell : 48;
    public Suggestion? SelectedItem => items.Count > 0 ? items[selected] : null;
    public bool HasResults => Visible && items.Count > 0;
    public event Action<Suggestion>? OnSelect;
    protected override bool ShowWithoutActivation => true;
    protected override CreateParams CreateParams
    {
        get { var p = base.CreateParams; p.ExStyle |= 0x08000000 | 0x80; return p; }
    }

    public SuggestionWindow(bool? darkModeOverride = null)
    {
        darkOverride = darkModeOverride;
        palette = PickerPalette.Resolve(darkOverride);
        Text = "Ogma suggestions";
        AccessibleName = Text;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        TopMost = true;
        BackColor = palette.Background;
        DoubleBuffered = true;
        AutoScaleMode = AutoScaleMode.None;
        SystemEvents.UserPreferenceChanged += OnUserPreferenceChanged;
    }

    private void OnUserPreferenceChanged(object? sender, UserPreferenceChangedEventArgs e)
    {
        if (IsDisposed || !IsHandleCreated) return;
        BeginInvoke(() =>
        {
            if (IsDisposed) return;
            palette = PickerPalette.Resolve(darkOverride);
            BackColor = palette.Background;
            Invalidate();
        });
    }

    public void Present(IReadOnlyList<Suggestion> results, Rectangle anchor, bool useGrid)
    {
        items = results;
        grid = useGrid;
        this.anchor = anchor;
        selected = firstRow = 0;
        if (items.Count == 0) { Hide(); return; }
        PositionBesideAnchor();
        UpdateAccessibility();
        Invalidate();
        if (!Visible) Show();
    }

    private void PositionBesideAnchor()
    {
        var scale = DeviceDpi / 96f;
        var width = grid ? Cell * 5 + 16 : 370;
        var rows = Math.Min(Rows, (items.Count + Columns - 1) / Columns);
        Size = new Size((int)(width * scale), (int)((Header + rows * RowHeight + Footer) * scale));
        var work = Screen.FromRectangle(anchor).WorkingArea;
        var x = Math.Clamp(anchor.Right + (int)(16 * scale), work.Left, Math.Max(work.Left, work.Right - Width));
        var y = anchor.Bottom + (int)(6 * scale);
        if (y + Height > work.Bottom) y = anchor.Top - Height - (int)(6 * scale);
        Location = new Point(x, Math.Clamp(y, work.Top, Math.Max(work.Top, work.Bottom - Height)));
    }

    protected override void OnShown(EventArgs e) { base.OnShown(e); PositionBesideAnchor(); }

    protected override void OnDpiChanged(DpiChangedEventArgs e)
    {
        e.Cancel = true;
        base.OnDpiChanged(e);
        PositionBesideAnchor();
    }

    public void MoveSelection(int delta, bool vertical = false)
    {
        if (items.Count == 0) return;
        selected = Math.Clamp(selected + delta * (vertical ? Columns : 1), 0, items.Count - 1);
        var row = selected / Columns;
        if (row < firstRow) firstRow = row;
        if (row >= firstRow + Rows) firstRow = row - Rows + 1;
        UpdateAccessibility();
        Invalidate();
    }

    private void UpdateAccessibility()
    {
        AccessibleDescription = SelectedItem?.Title;
        AccessibilityNotifyClients(AccessibleEvents.Selection, -1);
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x21) { message.Result = 3; return; } // MA_NOACTIVATE
        base.WndProc(ref message);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        var g = e.Graphics;
        var scale = DeviceDpi / 96f;
        g.ScaleTransform(scale, scale);
        var width = ClientSize.Width / scale;
        var height = ClientSize.Height / scale;
        var glyphs = new List<EmojiGlyph>();
        using var border = new Pen(palette.Border);
        g.DrawRectangle(border, 0, 0, width - 1, height - 1);
        Draw(g, "OGMA", labelFont, palette.Secondary, new RectangleF(12, 8, width - 24, 22));
        var end = Math.Min(items.Count, (firstRow + Rows) * Columns);
        for (var i = firstRow * Columns; i < end; i++)
        {
            var item = items[i];
            var cell = new RectangleF(8 + i % Columns * (grid ? Cell : 0), Header + (i / Columns - firstRow) * RowHeight,
                grid ? Cell : width - 16, RowHeight);
            var background = i == selected ? palette.Selection : item.Usage == "Recently used"
                ? palette.Recent : item.Usage == "Most used" ? palette.Frequent : palette.Background;
            using var fill = new SolidBrush(background);
            g.FillRectangle(fill, RectangleF.Inflate(cell, -2, -2));
            var foreground = i == selected ? palette.SelectedText : palette.Text;
            if (grid) glyphs.Add(new(item.Emoji ?? "", RectangleF.Inflate(cell, -2, -2), foreground, background));
            else if (item.Emoji != null)
            {
                glyphs.Add(new(item.Emoji, new RectangleF(cell.X + 4, cell.Y + 2, 46, cell.Height - 4), foreground, background));
                Draw(g, item.Title, labelFont, foreground, new RectangleF(cell.X + 56, cell.Y, cell.Width - 60, cell.Height));
            }
            else
            {
                Draw(g, item.Title, labelFont, foreground, new RectangleF(cell.X + 8, cell.Y + 2, cell.Width - 16, 21));
                Draw(g, item.Replacement.Replace("\r", "").Replace("\n", " ↵ "), labelFont, foreground,
                    new RectangleF(cell.X + 8, cell.Y + 23, cell.Width - 16, 21));
            }
        }
        var hint = grid ? SelectedItem?.Title ?? "" : "↑ ↓ Choose    Enter Insert    Esc Close";
        Draw(g, hint, labelFont, palette.Secondary, new RectangleF(12, height - Footer + 3, width - 24, 24));
        if (!colorEmoji.TryDraw(g, glyphs, scale))
        {
            foreach (var glyph in glyphs)
            {
                using var fill = new SolidBrush(glyph.Background);
                g.FillRectangle(fill, glyph.Bounds);
                Draw(g, glyph.Text, emojiFont, glyph.Foreground, glyph.Bounds, center: true);
            }
        }
    }

    private static void Draw(Graphics g, string text, Font font, Color color, RectangleF bounds, bool center = false)
    {
        using var brush = new SolidBrush(color);
        using var format = new StringFormat
        {
            Alignment = center ? StringAlignment.Center : StringAlignment.Near,
            LineAlignment = StringAlignment.Center,
            Trimming = StringTrimming.EllipsisCharacter,
            FormatFlags = StringFormatFlags.NoWrap
        };
        g.DrawString(text, font, brush, bounds, format);
    }

    private int Hit(Point point)
    {
        var scale = DeviceDpi / 96f;
        var x = point.X / scale - 8;
        var y = point.Y / scale - Header;
        if (x < 0 || y < 0 || point.Y >= ClientSize.Height - Footer * scale) return -1;
        var column = grid ? (int)(x / Cell) : 0;
        if (column >= Columns) return -1;
        var index = (firstRow + (int)(y / RowHeight)) * Columns + column;
        return index < items.Count ? index : -1;
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        var index = Hit(e.Location);
        if (index < 0 || index == selected) return;
        selected = index;
        tooltip.SetToolTip(this, items[index].Title + (items[index].Usage is { } usage ? " · " + usage : ""));
        UpdateAccessibility();
        Invalidate();
    }
    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        var index = Hit(e.Location);
        if (e.Button == MouseButtons.Left && index >= 0) OnSelect?.Invoke(items[index]);
    }
    protected override void OnMouseWheel(MouseEventArgs e)
    {
        base.OnMouseWheel(e);
        firstRow = Math.Clamp(firstRow - Math.Sign(e.Delta) * 2, 0, Math.Max(0, (items.Count + Columns - 1) / Columns - Rows));
        selected = Math.Clamp(selected, firstRow * Columns, Math.Min(items.Count - 1, (firstRow + Rows) * Columns - 1));
        UpdateAccessibility();
        Invalidate();
    }
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            SystemEvents.UserPreferenceChanged -= OnUserPreferenceChanged;
            colorEmoji.Dispose(); emojiFont.Dispose(); labelFont.Dispose(); tooltip.Dispose();
        }
        base.Dispose(disposing);
    }
}

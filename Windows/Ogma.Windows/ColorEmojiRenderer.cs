using System.Runtime.InteropServices;

namespace Ogma.Windows;

internal sealed record EmojiGlyph(string Text, RectangleF Bounds, Color Foreground, Color Background);

// GDI+ DrawString ignores the color layers in Segoe UI Emoji. Use the system's
// DirectWrite/Direct2D renderer, retaining shaping for variation selectors,
// skin tones and joined emoji. No font files or third-party images are bundled.
internal sealed unsafe class ColorEmojiRenderer : IDisposable
{
    private nint d2dFactory, writeFactory, target, brush, format;
    private float currentFontSize;
    internal string? LastError { get; private set; }

    internal bool TryDraw(Graphics graphics, IReadOnlyList<EmojiGlyph> glyphs, float scale)
    {
        if (glyphs.Count == 0) return true;
        nint dc = 0;
        try
        {
            EnsureResources(30 * scale);
            dc = graphics.GetHdc();
            foreach (var glyph in glyphs)
            {
                var bounds = new NativeMethods.Rect
                {
                    Left = (int)Math.Floor(glyph.Bounds.Left * scale),
                    Top = (int)Math.Floor(glyph.Bounds.Top * scale),
                    Right = (int)Math.Ceiling(glyph.Bounds.Right * scale),
                    Bottom = (int)Math.Ceiling(glyph.Bounds.Bottom * scale)
                };
                if (bounds.Right <= bounds.Left || bounds.Bottom <= bounds.Top) continue;
                // ID2D1DCRenderTarget::BindDC. Bind only the emoji rectangle:
                // clearing it must not erase the GDI labels already painted.
                Check(((delegate* unmanaged[Stdcall]<nint, nint, NativeMethods.Rect*, int>)Slot(target, 57))(target, dc, &bounds));
                ((delegate* unmanaged[Stdcall]<nint, void>)Slot(target, 48))(target); // BeginDraw
                var background = Rgba.From(glyph.Background);
                ((delegate* unmanaged[Stdcall]<nint, Rgba*, void>)Slot(target, 47))(target, &background); // Clear
                var foreground = Rgba.From(glyph.Foreground);
                ((delegate* unmanaged[Stdcall]<nint, Rgba*, void>)Slot(brush, 8))(brush, &foreground); // SetColor
                var layout = new FloatRect { Right = bounds.Right - bounds.Left, Bottom = bounds.Bottom - bounds.Top };
                fixed (char* text = glyph.Text)
                {
                    // ID2D1RenderTarget::DrawText; 0x4 enables color fonts,
                    // 0x2 clips to the cell. Natural measuring mode = 0.
                    ((delegate* unmanaged[Stdcall]<nint, char*, uint, nint, FloatRect*, nint, uint, uint, void>)Slot(target, 27))
                        (target, text, (uint)glyph.Text.Length, format, &layout, brush, 0x6, 0);
                }
                Check(((delegate* unmanaged[Stdcall]<nint, nint, nint, int>)Slot(target, 49))(target, 0, 0)); // EndDraw
            }
            LastError = null;
            return true;
        }
        catch (Exception e) when (e is COMException or DllNotFoundException or EntryPointNotFoundException)
        {
            LastError = e.Message;
            DisposeResources(); // Includes device-loss recovery on next paint.
            return false;
        }
        finally { if (dc != 0) graphics.ReleaseHdc(dc); }
    }

    private void EnsureResources(float fontSize)
    {
        if (d2dFactory == 0)
        {
            var id = new Guid("06152247-6f50-465a-9245-118bfd3b6007");
            nint result = 0;
            Check(D2D1CreateFactory(0, &id, 0, &result));
            d2dFactory = result;
            id = new Guid("b859ee5a-d838-4b5b-a2e8-1adc7d93db48");
            Check(DWriteCreateFactory(0, &id, &result));
            writeFactory = result;
        }
        if (target == 0)
        {
            // D2D1_RENDER_TARGET_PROPERTIES: software target, BGRA8, alpha
            // ignored, 96 DPI. Coordinates below are physical pixel units.
            var properties = new TargetProperties { Type = 2, Format = 87, Alpha = 3, DpiX = 96, DpiY = 96 };
            nint result = 0;
            Check(((delegate* unmanaged[Stdcall]<nint, TargetProperties*, nint*, int>)Slot(d2dFactory, 16))
                (d2dFactory, &properties, &result));
            target = result;
            var ink = Rgba.From(Color.Black);
            Check(((delegate* unmanaged[Stdcall]<nint, Rgba*, nint, nint*, int>)Slot(target, 8))(target, &ink, 0, &result));
            brush = result;
            ((delegate* unmanaged[Stdcall]<nint, uint, void>)Slot(target, 34))(target, 2); // Grayscale antialiasing
        }
        if (format != 0 && Math.Abs(fontSize - currentFontSize) < 0.01f) return;
        Release(ref format);
        nint created = 0;
        fixed (char* family = "Segoe UI Emoji")
        fixed (char* locale = "en-US")
            Check(((delegate* unmanaged[Stdcall]<nint, char*, nint, int, int, int, float, char*, nint*, int>)Slot(writeFactory, 15))
                (writeFactory, family, 0, 400, 0, 5, fontSize, locale, &created));
        format = created;
        Check(((delegate* unmanaged[Stdcall]<nint, int, int>)Slot(format, 3))(format, 2)); // Center
        Check(((delegate* unmanaged[Stdcall]<nint, int, int>)Slot(format, 4))(format, 2)); // Paragraph center
        Check(((delegate* unmanaged[Stdcall]<nint, int, int>)Slot(format, 5))(format, 1)); // No wrap
        currentFontSize = fontSize;
    }

    private static void* Slot(nint instance, int index) => (*(void***)instance)[index];
    private static void Check(int result) { if (result < 0) Marshal.ThrowExceptionForHR(result); }
    private static void Release(ref nint instance)
    {
        if (instance == 0) return;
        ((delegate* unmanaged[Stdcall]<nint, uint>)Slot(instance, 2))(instance);
        instance = 0;
    }
    private void DisposeResources()
    {
        Release(ref format); Release(ref brush); Release(ref target);
        Release(ref writeFactory); Release(ref d2dFactory);
    }
    public void Dispose() => DisposeResources();

    [StructLayout(LayoutKind.Sequential)]
    private struct TargetProperties { public uint Type, Format, Alpha; public float DpiX, DpiY; public uint Usage, FeatureLevel; }
    [StructLayout(LayoutKind.Sequential)]
    private struct FloatRect { public float Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    private struct Rgba
    {
        public float R, G, B, A;
        public static Rgba From(Color value) => new() { R = value.R / 255f, G = value.G / 255f, B = value.B / 255f, A = value.A / 255f };
    }
    [DllImport("d2d1.dll", ExactSpelling = true)]
    private static extern int D2D1CreateFactory(uint factoryType, Guid* interfaceId, nint options, nint* factory);
    [DllImport("dwrite.dll", ExactSpelling = true)]
    private static extern int DWriteCreateFactory(uint factoryType, Guid* interfaceId, nint* factory);
}

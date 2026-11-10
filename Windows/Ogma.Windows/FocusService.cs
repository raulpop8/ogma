using System.Runtime.InteropServices;
using System.Windows.Automation;
using System.Windows.Automation.Text;

namespace Ogma.Windows;

internal sealed record FocusSnapshot(nint Window, nint FocusHandle, int[] RuntimeId, Rectangle Anchor);

internal sealed class FocusService
{
    // Limit outstanding calls: a broken accessibility provider must not create
    // an unbounded queue of worker threads when the user keeps typing.
    private int inspecting;

    public async Task<FocusSnapshot?> InspectAsync(nint window)
    {
        if (Interlocked.CompareExchange(ref inspecting, 1, 0) != 0) return null;
        var work = Task.Run(() =>
        {
            try { return Inspect(window); }
            finally { Volatile.Write(ref inspecting, 0); }
        });
        var completed = await Task.WhenAny(work, Task.Delay(500));
        return completed == work ? await work : null;
    }

    public static bool Matches(FocusSnapshot snapshot)
    {
        if (NativeMethods.GetForegroundWindow() != snapshot.Window) return false;
        return NativeMethods.ForegroundInfo().Focus == snapshot.FocusHandle;
    }

    public static bool IsNativePassword(nint focus) => focus != 0 && (NativeMethods.GetWindowLong(focus, -16) & 0x20) != 0
        && IsEditControl(focus);

    private static bool IsEditControl(nint window)
    {
        var name = new System.Text.StringBuilder(256);
        GetClassNameW(window, name, name.Capacity);
        return name.ToString().Contains("edit", StringComparison.OrdinalIgnoreCase);
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassNameW(nint window, System.Text.StringBuilder name, int count);

    private static FocusSnapshot? Inspect(nint window)
    {
        try
        {
            if (NativeMethods.GetForegroundWindow() != window) return null;
            var info = NativeMethods.ForegroundInfo();
            if (info.Focus == 0 || IsNativePassword(info.Focus)) return null;
            var element = AutomationElement.FocusedElement;
            // Fail closed for unavailable or password providers. Never read text.
            if (element == null || element.Current.IsPassword || !element.Current.IsEnabled) return null;
            NativeMethods.GetWindowThreadProcessId(window, out var pid);
            // Browser content and hosted Windows apps can expose accessibility
            // elements from a different process than their top-level window.
            if (element.Current.ProcessId != pid && !BelongsToWindow(element, window, info.Focus)) return null;
            var bounds = element.Current.BoundingRectangle;
            var anchor = bounds.IsEmpty ? Rectangle.Empty : new Rectangle((int)bounds.Left, (int)bounds.Top,
                (int)bounds.Width, (int)bounds.Height);
            if (info.Caret != 0)
            {
                var topLeft = new NativeMethods.Point { X = info.CaretRect.Left, Y = info.CaretRect.Top };
                var bottomRight = new NativeMethods.Point { X = info.CaretRect.Right, Y = info.CaretRect.Bottom };
                if (NativeMethods.ClientToScreen(info.Caret, ref topLeft) && NativeMethods.ClientToScreen(info.Caret, ref bottomRight)
                    && bottomRight.Y > topLeft.Y)
                    anchor = Rectangle.FromLTRB(topLeft.X, topLeft.Y, Math.Max(topLeft.X + 1, bottomRight.X), bottomRight.Y);
            }
            else if (element.TryGetCurrentPattern(TextPattern.Pattern, out var pattern))
            {
                var selection = ((TextPattern)pattern).GetSelection();
                if (selection.Length > 0)
                {
                    var range = selection[0].Clone();
                    range.MoveEndpointByRange(TextPatternRangeEndpoint.Start, range, TextPatternRangeEndpoint.End);
                    var rectangles = range.GetBoundingRectangles();
                    if (rectangles.Length == 0)
                    {
                        range.MoveEndpointByUnit(TextPatternRangeEndpoint.Start, TextUnit.Character, -1);
                        rectangles = range.GetBoundingRectangles();
                    }
                    if (rectangles.Length > 0)
                    {
                        var caret = rectangles[^1];
                        anchor = new Rectangle((int)caret.Right, (int)caret.Top, 1, Math.Max(1, (int)caret.Height));
                    }
                }
            }
            if (anchor.IsEmpty && NativeMethods.GetWindowRect(window, out var rect))
                anchor = new Rectangle((rect.Left + rect.Right) / 2, (rect.Top + rect.Bottom) / 2, 1, 20);
            // Large field/window bounds are approximate anchors; use their center.
            if (anchor.Height > 80) anchor = new Rectangle(anchor.Left + anchor.Width / 2, anchor.Top + anchor.Height / 2, 1, 20);
            var snapshot = new FocusSnapshot(window, info.Focus, element.GetRuntimeId(), anchor);
            return Matches(snapshot) ? snapshot : null;
        }
        catch (Exception e) when (e is ElementNotAvailableException or InvalidOperationException or COMException or UnauthorizedAccessException
            or NotSupportedException or ArgumentException) { return null; }
    }

    private static bool BelongsToWindow(AutomationElement element, nint window, nint focusHandle)
    {
        AutomationElement? current = element;
        for (var depth = 0; current != null && depth < 64; depth++)
        {
            var handle = (nint)current.Current.NativeWindowHandle;
            if (handle == window || handle != 0 && handle == focusHandle) return true;
            current = TreeWalker.RawViewWalker.GetParent(current);
        }
        return false;
    }
}

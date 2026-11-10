using System.Runtime.InteropServices;
using System.Text;

namespace Ogma.Windows;

internal enum NativeInsertionResult { NotApplicable, Succeeded, Failed }

internal static unsafe class RichEditInsertion
{
    // RichEdit (including editors built on it) supports a direct Unicode range
    // replacement. This avoids both VK_PACKET timing and dropped line breaks.
    // Only selection indices are read; document text and the clipboard are not.
    internal static NativeInsertionResult TryReplace(FocusSnapshot target, int length, string replacement, Func<bool> canContinue)
    {
        var name = new StringBuilder(256);
        GetClassNameW(target.FocusHandle, name, name.Capacity);
        if (!name.ToString().Contains("RichEdit", StringComparison.OrdinalIgnoreCase) || replacement.Contains('\0'))
            return NativeInsertionResult.NotApplicable;
        if (!canContinue() || FocusService.IsNativePassword(target.FocusHandle)
            || (NativeMethods.GetWindowLong(target.FocusHandle, -16) & 0x0800) != 0)
            return NativeInsertionResult.Failed;
        if (!ReadSelection(target.FocusHandle, out var start, out var end)
            || start != end || start < length || start > int.MaxValue)
            return NativeInsertionResult.Failed;

        if (!canContinue()) return NativeInsertionResult.Failed;
        var from = start - (uint)length;
        if (!Send(target.FocusHandle, 0x00B1, from, (nint)end) // EM_SETSEL
            || !ReadSelection(target.FocusHandle, out var selectedStart, out var selectedEnd)
            || selectedStart != from || selectedEnd != end)
            return NativeInsertionResult.Failed;
        if (!canContinue()) return NativeInsertionResult.Failed;
        var text = replacement.Replace("\r\n", "\n").Replace('\r', '\n').Replace('\n', '\r');
        fixed (char* buffer = text)
        {
            // TRUE preserves the editor's undo operation. Never send Return,
            // which could submit a message instead of inserting a newline.
            if (!Send(target.FocusHandle, 0x00C2, 1, (nint)buffer)) return NativeInsertionResult.Failed; // EM_REPLACESEL
        }
        return ReadSelection(target.FocusHandle, out var afterStart, out var afterEnd)
            && afterStart == from + text.Length && afterEnd == afterStart
            ? NativeInsertionResult.Succeeded : NativeInsertionResult.Failed;
    }

    private static bool ReadSelection(nint window, out uint start, out uint end)
    {
        uint first = uint.MaxValue, last = uint.MaxValue;
        var read = Send(window, 0x00B0, (nuint)(&first), (nint)(&last)); // EM_GETSEL
        start = first; end = last;
        return read && first != uint.MaxValue && last != uint.MaxValue;
    }

    private static bool Send(nint window, uint message, nuint first, nint second) =>
        SendMessageTimeoutW(window, message, first, second, 0x3, 100, out _) != 0;

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassNameW(nint window, StringBuilder name, int count);
    [DllImport("user32.dll", ExactSpelling = true, SetLastError = true)]
    private static extern nint SendMessageTimeoutW(nint window, uint message, nuint first, nint second,
        uint flags, uint timeout, out nuint result);
}

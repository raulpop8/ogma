using System.Runtime.InteropServices;

namespace Ogma.Windows;

internal static class TextInsertionService
{
    public static async Task<bool> ReplaceAsync(FocusSnapshot target, int length, string replacement, Func<bool>? isCurrent = null)
    {
        if (length <= 0 || replacement.Length == 0) return false;
        // Held modifiers can turn backspaces into commands or alter insertion.
        bool CanContinue() => isCurrent?.Invoke() != false && FocusService.Matches(target)
            && !new[] { 0x10, 0x11, 0x12, 0x5B, 0x5C }.Any(NativeMethods.IsDown);
        if (!CanContinue()) return false;
        var direct = RichEditInsertion.TryReplace(target, length, replacement, CanContinue);
        if (direct != NativeInsertionResult.NotApplicable) return direct == NativeInsertionResult.Succeeded;
        var inputs = CreateInputs(length, replacement);
        var size = Marshal.SizeOf<NativeMethods.Input>();
        for (var index = 0; index < inputs.Length; index += 2)
        {
            if (!CanContinue()) return false;
            var pair = new[] { inputs[index], inputs[index + 1] };
            if (NativeMethods.SendInput(2, pair, size) != 2) return false;
            // VK_PACKET text is processed asynchronously by modern editors.
            // Give the editor a message-loop turn before the next UTF-16 unit,
            // rather than posting a whole date/snippet in one unpaced burst.
            await Task.Delay(8);
        }
        return true;
    }

    internal static NativeMethods.Input[] CreateInputs(int length, string replacement)
    {
        var inputs = new List<NativeMethods.Input>();
        void Add(ushort key, ushort scan, uint flags) => inputs.Add(new NativeMethods.Input
        {
            Type = NativeMethods.InputKeyboard,
            Data = new NativeMethods.InputUnion { Keyboard = new NativeMethods.KeyboardInput
            { VirtualKey = key, Scan = scan, Flags = flags, ExtraInfo = NativeMethods.EventMarker } }
        });
        for (var i = 0; i < length; i++) { Add(8, 0, 0); Add(8, 0, NativeMethods.KeyUp); }
        // Send UTF-16 units, including surrogate pairs and emoji joiners, without
        // touching the clipboard. Newlines use Unicode carriage returns rather
        // than Return key presses, which could submit a form or chat message.
        foreach (var c in replacement.Replace("\r\n", "\n").Replace('\r', '\n'))
        {
            var unit = c == '\n' ? '\r' : c;
            Add(0, unit, NativeMethods.Unicode);
            Add(0, unit, NativeMethods.Unicode | NativeMethods.KeyUp);
        }
        return inputs.ToArray();
    }
}

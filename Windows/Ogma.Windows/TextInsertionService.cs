using System.Runtime.InteropServices;

namespace Ogma.Windows;

internal static class TextInsertionService
{
    public static bool Replace(FocusSnapshot target, int length, string replacement)
    {
        if (length <= 0 || replacement.Length == 0 || !FocusService.Matches(target)) return false;
        // Held modifiers can turn backspaces into commands or alter insertion.
        if (new[] { 0x10, 0x11, 0x12, 0x5B, 0x5C }.Any(NativeMethods.IsDown)) return false;
        var inputs = CreateInputs(length, replacement);
        return NativeMethods.SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<NativeMethods.Input>()) == inputs.Length;
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

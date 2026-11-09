using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Ogma.Core;

namespace Ogma.Windows;

// Hook callbacks only translate keys and update the trigger. UI Automation and
// file operations run outside callbacks so a slow editor cannot remove the hook.
internal sealed class KeyboardMonitor : IDisposable
{
    private readonly NativeMethods.HookProc keyboardCallback;
    private readonly NativeMethods.HookProc mouseCallback;
    private nint keyboardHook, mouseHook;
    private readonly HashSet<uint> swallowedKeys = [];
    public Func<KeyKind, string, bool>? OnKey { get; set; }
    public Action<Point>? OnPointerDown { get; set; }

    public KeyboardMonitor()
    {
        keyboardCallback = KeyboardCallback;
        mouseCallback = MouseCallback;
    }

    public void Start()
    {
        if (keyboardHook != 0) return;
        var module = NativeMethods.GetModuleHandleW(null);
        keyboardHook = NativeMethods.SetWindowsHookExW(NativeMethods.WhKeyboardLl, keyboardCallback, module, 0);
        if (keyboardHook == 0) throw new Win32Exception(Marshal.GetLastWin32Error());
        mouseHook = NativeMethods.SetWindowsHookExW(NativeMethods.WhMouseLl, mouseCallback, module, 0);
        if (mouseHook == 0) { var error = Marshal.GetLastWin32Error(); Stop(); throw new Win32Exception(error); }
    }

    public void Stop()
    {
        if (keyboardHook != 0) NativeMethods.UnhookWindowsHookEx(keyboardHook);
        if (mouseHook != 0) NativeMethods.UnhookWindowsHookEx(mouseHook);
        keyboardHook = mouseHook = 0;
        swallowedKeys.Clear();
    }

    private nint KeyboardCallback(int code, nint message, nint data)
    {
        if (code < 0) return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
        var key = Marshal.PtrToStructure<NativeMethods.KeyboardData>(data);
        // Own replacements do not change session state. Other synthetic input
        // cancels stale triggers without interpreting the injected text.
        if (key.ExtraInfo == NativeMethods.EventMarker)
            return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
        if ((key.Flags & 0x10) != 0)
        {
            if (message == 0x100 || message == 0x104) OnKey?.Invoke(KeyKind.Other, "");
            return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
        }
        if (message == 0x101 || message == 0x105)
        {
            if (swallowedKeys.Remove(key.VirtualKey)) return 1;
            return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
        }
        if (message != 0x100 && message != 0x104) return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
        if (key.VirtualKey is 0x10 or 0xA0 or 0xA1) return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);

        var text = "";
        var kind = key.VirtualKey switch
        {
            8 => KeyKind.Backspace, 13 => KeyKind.Enter, 27 => KeyKind.Escape,
            37 => KeyKind.Left, 38 => KeyKind.Up, 39 => KeyKind.Right, 40 => KeyKind.Down,
            _ => KeyKind.Other
        };
        if (NativeMethods.IsDown(0x11) || NativeMethods.IsDown(0x12) || NativeMethods.IsDown(0x5B) || NativeMethods.IsDown(0x5C)
            || key.VirtualKey is 0x11 or 0x12 or 0x5B or 0x5C or 0xA2 or 0xA3 or 0xA4 or 0xA5)
            kind = KeyKind.Other;
        else if (kind == KeyKind.Other)
        {
            var state = new byte[256];
            for (var i = 0; i < state.Length; i++) if (NativeMethods.IsDown(i)) state[i] = 0x80;
            state[0x14] |= (byte)(NativeMethods.GetKeyState(0x14) & 1);
            state[key.VirtualKey] |= 0x80;
            var thread = NativeMethods.GetWindowThreadProcessId(NativeMethods.GetForegroundWindow(), out _);
            var buffer = new StringBuilder(8);
            // Flag 4 preserves the editor's dead-key state.
            var length = NativeMethods.ToUnicodeEx(key.VirtualKey, key.ScanCode, state, buffer, buffer.Capacity, 4,
                NativeMethods.GetKeyboardLayout(thread));
            if (length > 0) { kind = KeyKind.Character; text = buffer.ToString(0, length); }
        }
        if (OnKey?.Invoke(kind, text) == true) { swallowedKeys.Add(key.VirtualKey); return 1; }
        return NativeMethods.CallNextHookEx(keyboardHook, code, message, data);
    }

    private nint MouseCallback(int code, nint message, nint data)
    {
        if (code >= 0 && (message == 0x201 || message == 0x204 || message == 0x207 || message == 0x20B))
        {
            var mouse = Marshal.PtrToStructure<NativeMethods.MouseData>(data);
            OnPointerDown?.Invoke(new Point(mouse.Point.X, mouse.Point.Y));
        }
        return NativeMethods.CallNextHookEx(mouseHook, code, message, data);
    }

    public void Dispose() => Stop();
}

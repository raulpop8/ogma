using System.Runtime.InteropServices;
using System.Text;

namespace Ogma.Windows;

internal static class NativeMethods
{
    internal const int WhKeyboardLl = 13, WhMouseLl = 14;
    internal const uint InputKeyboard = 1, KeyUp = 2, Unicode = 4;
    internal const nuint EventMarker = 0x4F474D41;
    internal delegate nint HookProc(int code, nint message, nint data);

    [StructLayout(LayoutKind.Sequential)]
    internal struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)]
    internal struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    internal struct KeyboardData { public uint VirtualKey, ScanCode, Flags, Time; public nuint ExtraInfo; }
    [StructLayout(LayoutKind.Sequential)]
    internal struct MouseData { public Point Point; public uint MouseDataValue, Flags, Time; public nuint ExtraInfo; }
    [StructLayout(LayoutKind.Sequential)]
    internal struct GuiThreadInfo
    {
        public uint Size, Flags;
        public nint Active, Focus, Capture, MenuOwner, MoveSize, Caret;
        public Rect CaretRect;
    }
    [StructLayout(LayoutKind.Sequential)]
    internal struct Input { public uint Type; public InputUnion Data; }
    [StructLayout(LayoutKind.Explicit)]
    internal struct InputUnion
    {
        [FieldOffset(0)] public KeyboardInput Keyboard;
        [FieldOffset(0)] public MouseInput Mouse;
    }
    [StructLayout(LayoutKind.Sequential)]
    internal struct KeyboardInput { public ushort VirtualKey, Scan; public uint Flags, Time; public nuint ExtraInfo; }
    [StructLayout(LayoutKind.Sequential)]
    internal struct MouseInput { public int X, Y; public uint MouseData, Flags, Time; public nuint ExtraInfo; }

    [DllImport("user32.dll", SetLastError = true)]
    internal static extern nint SetWindowsHookExW(int id, HookProc callback, nint module, uint threadId);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool UnhookWindowsHookEx(nint hook);
    [DllImport("user32.dll")] internal static extern nint CallNextHookEx(nint hook, int code, nint message, nint data);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] internal static extern nint GetModuleHandleW(string? name);
    [DllImport("user32.dll")] internal static extern nint GetForegroundWindow();
    [DllImport("user32.dll")] internal static extern uint GetWindowThreadProcessId(nint window, out uint processId);
    [DllImport("user32.dll")] internal static extern nint GetKeyboardLayout(uint threadId);
    [DllImport("user32.dll")] internal static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] internal static extern short GetKeyState(int key);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    internal static extern int ToUnicodeEx(uint key, uint scan, byte[] state, StringBuilder text, int size, uint flags, nint layout);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool GetGUIThreadInfo(uint thread, ref GuiThreadInfo info);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool ClientToScreen(nint window, ref Point point);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool GetWindowRect(nint window, out Rect rect);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongW")] internal static extern int GetWindowLong(nint window, int index);
    [DllImport("user32.dll", SetLastError = true)] internal static extern uint SendInput(uint count, Input[] inputs, int size);

    internal static GuiThreadInfo ForegroundInfo()
    {
        var info = new GuiThreadInfo { Size = (uint)Marshal.SizeOf<GuiThreadInfo>() };
        GetGUIThreadInfo(0, ref info);
        return info;
    }
    internal static bool IsDown(int key) => (GetAsyncKeyState(key) & 0x8000) != 0;
}

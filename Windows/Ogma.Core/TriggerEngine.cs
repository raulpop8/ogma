namespace Ogma.Core;

public enum TriggerMode { Emoji, Snippet }
public enum KeyKind { Character, Backspace, Up, Down, Left, Right, Enter, Escape, Other }
public enum Outcome { None, Updated, Previous, Next, Left, Right, Accept, Cancel, CancelAndConsume }

public sealed class TriggerEngine
{
    public TriggerMode? Mode { get; private set; }
    public string Query { get; private set; } = "";
    public bool IsActive => Mode.HasValue;
    public int TypedLength => IsActive ? Query.Length + 1 : 0;

    public void Reset() { Mode = null; Query = ""; }

    public Outcome Handle(KeyKind key, string text = "")
    {
        if (!IsActive)
        {
            if (key != KeyKind.Character || text is not (":" or "/")) return Outcome.None;
            Mode = text == ":" ? TriggerMode.Emoji : TriggerMode.Snippet;
            Query = "";
            return Outcome.Updated;
        }
        switch (key)
        {
            case KeyKind.Character when text.Length == 1 && IsAllowed(text[0]) && Query.Length < 32:
                Query += text.ToLowerInvariant();
                return Outcome.Updated;
            case KeyKind.Backspace when Query.Length > 0:
                Query = Query[..^1];
                return Outcome.Updated;
            case KeyKind.Up: return Outcome.Previous;
            case KeyKind.Down: return Outcome.Next;
            case KeyKind.Left: return Outcome.Left;
            case KeyKind.Right: return Outcome.Right;
            case KeyKind.Enter: return Outcome.Accept;
            case KeyKind.Escape: Reset(); return Outcome.CancelAndConsume;
            default: Reset(); return Outcome.Cancel;
        }
    }

    public static bool IsAllowed(char c) => c is >= 'a' and <= 'z' or >= 'A' and <= 'Z'
        or >= '0' and <= '9' or '_' or '+' or '-';
}

using System.Globalization;

namespace Ogma.Core;

public sealed record EmojiItem(string Id, string Emoji, string Name, string[] Keywords, string[] Aliases);
public sealed record TextSnippet(Guid Id, string Trigger, string Replacement, bool IsEnabled = true);
public enum DateDisplayFormat { SystemShort, SystemLong, Iso8601 }
public enum PickerLayout { Grid, List }

public sealed class Preferences
{
    public DateDisplayFormat DateFormat { get; set; }
    public PickerLayout PickerLayout { get; set; }
    public List<string> RecentIds { get; set; } = [];
    public Dictionary<string, long> EmojiCounts { get; set; } = [];

    public string FormatDate(DateTime? date = null) => (date ?? DateTime.Now).ToString(DateFormat switch
    {
        DateDisplayFormat.SystemLong => "D",
        DateDisplayFormat.Iso8601 => "yyyy-MM-dd",
        _ => "d"
    }, DateFormat == DateDisplayFormat.Iso8601 ? CultureInfo.InvariantCulture : CultureInfo.CurrentCulture);
}

public sealed record Suggestion(string Title, string Replacement, string? Emoji = null,
    string? EmojiId = null, string? Usage = null)
{
    public string InsertionText => Replacement.Length > 0 && char.IsWhiteSpace(Replacement[^1])
        ? Replacement : Replacement + " ";
}

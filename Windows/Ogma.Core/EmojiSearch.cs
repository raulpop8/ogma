using System.Globalization;
using System.Text;

namespace Ogma.Core;

public sealed class EmojiSearch
{
    private sealed record Entry(EmojiItem Item, string Name, string[] Aliases, string[] Keywords, string[] Words);
    private readonly Entry[] index;
    public IReadOnlyList<EmojiItem> Items { get; }

    public EmojiSearch(IReadOnlyList<EmojiItem> items)
    {
        Items = items;
        index = items.Select(item =>
        {
            var name = Normalize(item.Name);
            var aliases = item.Aliases.Select(Normalize).ToArray();
            var keywords = item.Keywords.Select(Normalize).ToArray();
            var words = aliases.Concat(keywords).Prepend(name).SelectMany(s => s.Split(' ')).Distinct().ToArray();
            return new Entry(item, name, aliases, keywords, words);
        }).ToArray();
    }

    public IReadOnlyList<EmojiItem> Search(string rawQuery, int limit = 8)
    {
        if (limit <= 0) return [];
        var query = Normalize(rawQuery);
        if (query.Length == 0) return Items.Take(limit).ToArray();
        var words = query.Split(' ');
        int Score(Entry e) => e.Aliases.Contains(query) ? 0 : e.Name == query ? 1
            : e.Aliases.Any(a => a.StartsWith(query, StringComparison.Ordinal)) ? 2
            : e.Name.StartsWith(query, StringComparison.Ordinal) ? 3
            : e.Keywords.Contains(query) ? 4
            : words.All(w => e.Words.Any(s => s.StartsWith(w, StringComparison.Ordinal))) ? 5 : -1;
        var matches = index.Select((e, i) => (Entry: e, Score: Score(e), Index: i)).Where(e => e.Score >= 0).ToArray();
        if (matches.Length == 0 && query.Length >= 4 && words.Length == 1)
            matches = index.Select((e, i) => (Entry: e, Score: 7, Index: i))
                .Where(e => e.Entry.Words.Any(w => IsNear(query, w))).ToArray();
        return matches.OrderBy(e => e.Score).ThenBy(e => e.Index).Take(limit).Select(e => e.Entry.Item).ToArray();
    }

    private static string Normalize(string value)
    {
        if (value.Trim() == "-1") return "-1";
        var folded = new string(value.Normalize(NormalizationForm.FormD)
            .Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark).ToArray());
        return string.Join(' ', folded.ToLowerInvariant().Replace('_', ' ').Replace('-', ' ')
            .Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    }

    private static bool IsNear(string a, string b)
    {
        if (Math.Abs(a.Length - b.Length) > 1) return false;
        if (a.Length == b.Length)
        {
            var mismatches = Enumerable.Range(0, a.Length).Where(i => a[i] != b[i]).ToArray();
            return mismatches.Length <= 1 || mismatches.Length == 2 && mismatches[1] == mismatches[0] + 1
                && a[mismatches[0]] == b[mismatches[1]] && a[mismatches[1]] == b[mismatches[0]];
        }
        var shorter = a.Length < b.Length ? a : b;
        var longer = a.Length < b.Length ? b : a;
        return Enumerable.Range(0, longer.Length).Any(i => longer.Remove(i, 1) == shorter);
    }
}

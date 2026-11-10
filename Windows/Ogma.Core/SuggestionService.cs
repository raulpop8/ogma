namespace Ogma.Core;

public sealed class SuggestionService(EmojiSearch search, LocalStore store)
{
    public IReadOnlyList<Suggestion> Search(TriggerMode mode, string query)
    {
        if (mode == TriggerMode.Emoji)
        {
            var results = search.Search(query, search.Items.Count);
            if (query.Length != 0) return results.Select(ToSuggestion).ToArray();
            var picks = QuickPicks();
            var included = picks.Select(p => p.EmojiId).ToHashSet();
            return picks.Concat(results.Where(e => !included.Contains(e.Id)).Select(ToSuggestion)).ToArray();
        }
        var saved = store.Snippets.Where(s => s.IsEnabled && s.Trigger != "date" && s.Trigger.Contains(query, StringComparison.Ordinal))
            .OrderBy(s => s.Trigger == query ? 0 : s.Trigger.StartsWith(query, StringComparison.Ordinal) ? 1 : 2)
            .ThenBy(s => s.Trigger, StringComparer.Ordinal)
            .Select(s => new Suggestion("/" + s.Trigger, s.Replacement));
        return ("date".Contains(query, StringComparison.Ordinal)
            ? saved.Prepend(new Suggestion("/date", store.Preferences.FormatDate())) : saved).ToArray();
    }

    public void Record(Suggestion item)
    {
        if (item.EmojiId is not { } id) return;
        var history = store.Preferences;
        history.EmojiCounts.TryGetValue(id, out var count);
        history.EmojiCounts[id] = count < long.MaxValue ? count + 1 : count;
        history.RecentIds.RemoveAll(s => s == id);
        history.RecentIds.Insert(0, id);
        store.SavePreferences();
    }

    private IReadOnlyList<Suggestion> QuickPicks()
    {
        var history = store.Preferences;
        var byId = search.Items.ToDictionary(e => e.Id);
        var picks = new List<Suggestion>();
        var included = new HashSet<string>();
        var common = new[] { "😊", "😂", "❤️", "👍", "🎉" }
            .Select(e => search.Items.FirstOrDefault(item => item.Emoji == e)).OfType<EmojiItem>().Concat(search.Items).ToArray();
        void Add(EmojiItem e, string? usage)
        {
            if (included.Add(e.Id)) picks.Add(ToSuggestion(e) with { Usage = usage });
        }
        foreach (var id in history.RecentIds.Distinct().Where(id => byId.ContainsKey(id) && history.EmojiCounts.GetValueOrDefault(id) > 0).Take(2))
            Add(byId[id], "Recently used");
        foreach (var e in common) { if (picks.Count >= 2) break; Add(e, null); }
        var recency = history.RecentIds.Distinct().Select((id, i) => (id, i)).ToDictionary(e => e.id, e => e.i);
        foreach (var id in history.EmojiCounts.Where(e => e.Value > 0 && byId.ContainsKey(e.Key))
                     .OrderByDescending(e => e.Value).ThenBy(e => recency.GetValueOrDefault(e.Key, int.MaxValue))
                     .ThenBy(e => e.Key, StringComparer.Ordinal).Select(e => e.Key))
        {
            if (picks.Count >= 5) break;
            Add(byId[id], "Most used");
        }
        foreach (var e in common) { if (picks.Count >= 5) break; Add(e, null); }
        return picks;
    }

    private static Suggestion ToSuggestion(EmojiItem e) => new(e.Name, e.Emoji, e.Emoji, e.Id);
}

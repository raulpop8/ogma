using System.Globalization;
using System.Text.Json;
using Ogma.Core;

var assertions = 0;
void Check(bool condition, string message)
{
    assertions++;
    if (!condition) throw new Exception(message);
}
void Reject(Action action, string message)
{
    try { action(); }
    catch (Exception e) when (e is ArgumentException or IOException) { assertions++; return; }
    throw new Exception(message);
}

var trigger = new TriggerEngine();
Check(trigger.Handle(KeyKind.Character, ":") == Outcome.Updated && trigger.Mode == TriggerMode.Emoji, "Start emoji trigger");
Check(trigger.Handle(KeyKind.Character, "S") == Outcome.Updated && trigger.Query == "s", "Normalize query");
Check(trigger.TypedLength == 2, "Track trigger length");
Check(trigger.Handle(KeyKind.Backspace) == Outcome.Updated && trigger.Query == "", "Backspace query");
Check(trigger.Handle(KeyKind.Backspace) == Outcome.Cancel && !trigger.IsActive, "Delete trigger");
trigger.Handle(KeyKind.Character, "/");
Check(trigger.Mode == TriggerMode.Snippet, "Start snippet trigger");
foreach (var (key, outcome) in new[] { (KeyKind.Up, Outcome.Previous), (KeyKind.Down, Outcome.Next), (KeyKind.Left, Outcome.Left), (KeyKind.Right, Outcome.Right), (KeyKind.Enter, Outcome.Accept) })
    Check(trigger.Handle(key) == outcome, "Navigate " + key);
Check(trigger.Handle(KeyKind.Escape) == Outcome.CancelAndConsume && !trigger.IsActive, "Escape consumes and resets");
foreach (var invalid in new[] { " ", ":", "/", "é", "😀", "ab" })
{
    trigger.Handle(KeyKind.Character, ":");
    Check(trigger.Handle(KeyKind.Character, invalid) == Outcome.Cancel && !trigger.IsActive, "Reject query " + invalid);
}
trigger.Handle(KeyKind.Character, ":");
for (var i = 0; i < 32; i++) trigger.Handle(KeyKind.Character, "a");
Check(trigger.TypedLength == 33, "Query limit");
Check(trigger.Handle(KeyKind.Character, "a") == Outcome.Cancel, "Cancel beyond query limit");

var catalog = JsonSerializer.Deserialize<EmojiItem[]>(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "emoji.json")), LocalStore.JsonOptions)!;
var search = new EmojiSearch(catalog);
Check(catalog.Length >= 3900, "Full shared emoji catalog");
foreach (var (query, emoji) in new[] { ("smile", "😊"), ("coffee", "☕"), ("cofee", "☕"), ("dog", "🐶"), ("hug", "🤗"), (" HUG ", "🤗"), ("broken-heart", "💔"), ("thumbs_up", "👍"), ("-1", "👎"), ("+1", "👍") })
    Check(search.Search(query).FirstOrDefault()?.Emoji == emoji, "Search " + query);
Check(search.Search("café").Any(e => e.Emoji == "☕"), "Accent folding");
Check(search.Search("", catalog.Length).Count == catalog.Length, "Browse full catalog");
Check(search.Search("sad", 0).Count == 0 && search.Search("", -1).Count == 0, "Search limit");
Check(search.Search("zzzzzzzz").Count == 0, "No invented results");
Check(!search.Search("tired", catalog.Length).Any(e => e.Emoji == "🛞"), "Do not mix fuzzy and direct results");
var sad = search.Search("sad", catalog.Length).Select(e => e.Emoji).ToHashSet();
foreach (var emoji in new[] { "😭", "😔", "😢", "😞", "🥺", "😟", "😕", "🙁", "☹️", "😖", "😫", "😩", "😥", "😓", "😪", "😿", "💧", "💔" })
    Check(sad.Contains(emoji), "Related emotions " + emoji);
var boundary = new EmojiSearch([
    new("happy", "😀", "happy face", [], []), new("unhappy", "😢", "unhappy face", [], []),
    new("red", "🔴", "red circle", [], []), new("tired", "😫", "tired face", [], []),
    new("art", "🎨", "artist palette", [], []), new("heart", "❤️", "red heart", [], [])]);
Check(boundary.Search("happy").Select(e => e.Id).SequenceEqual(["happy"]), "Match word boundaries");
Check(boundary.Search("art").Select(e => e.Id).SequenceEqual(["art"]), "Do not match inside words");

var directory = Path.Combine(Path.GetTempPath(), "ogma-tests-" + Guid.NewGuid().ToString("N"));
try
{
    var store = new LocalStore(directory);
    store.SaveSnippet(null, " Email ", "hello@example.com", true);
    store.SaveSnippet(null, "signature", "Best,\nTeam", true);
    var saved = new LocalStore(directory);
    Check(saved.Snippets.Count == 2 && saved.Snippets.Any(s => s.Replacement == "Best,\nTeam"), "Persist multiline snippets");
    Reject(() => store.SaveSnippet(null, "EMAIL", "duplicate", true), "Duplicate trigger");
    Reject(() => store.SaveSnippet(null, "date", "reserved", true), "Reserved trigger");
    Reject(() => store.SaveSnippet(null, "hello world", "invalid", true), "Invalid trigger");
    Reject(() => store.SaveSnippet(null, "empty", "", true), "Empty replacement");
    var service = new SuggestionService(search, store);
    Check(service.Search(TriggerMode.Snippet, "em").Single().Replacement == "hello@example.com", "Snippet search");
    Check(service.Search(TriggerMode.Snippet, "at").First().Title == "/date", "Built-in date");
    var email = store.Snippets.First(s => s.Trigger == "email");
    store.SaveSnippet(email.Id, "contact", "new@example.com", false);
    Check(!new LocalStore(directory).Snippets.Single(s => s.Id == email.Id).IsEnabled, "Persist disabled state");
    Check(service.Search(TriggerMode.Snippet, "contact").Count == 0, "Exclude disabled shortcuts");
    store.DeleteSnippet(email.Id);
    Check(new LocalStore(directory).Snippets.Count == 1, "Delete shortcut");
    Check(new Suggestion("", "Hello ").InsertionText == "Hello ", "Preserve trailing space");
    Check(new Suggestion("", "Hello\n").InsertionText == "Hello\n", "Preserve trailing newline");
    Check(new Suggestion("", "👨‍👩‍👧‍👦").InsertionText == "👨‍👩‍👧‍👦 ", "Preserve Unicode sequences");
    var picks = service.Search(TriggerMode.Emoji, "");
    Check(picks.Take(5).Select(s => s.Emoji).SequenceEqual(["😊", "😂", "❤️", "👍", "🎉"]), "Default quick picks");
    var coffee = service.Search(TriggerMode.Emoji, "coffee").First();
    var dog = service.Search(TriggerMode.Emoji, "dog").First();
    var hug = service.Search(TriggerMode.Emoji, "hug").First();
    service.Record(coffee); service.Record(coffee); service.Record(coffee); service.Record(dog); service.Record(hug);
    picks = service.Search(TriggerMode.Emoji, "");
    Check(picks[0].Emoji == hug.Emoji && picks[1].Emoji == dog.Emoji && picks[2].Emoji == coffee.Emoji, "Recent then frequent quick picks");
    Check(picks[0].Usage == "Recently used" && picks[2].Usage == "Most used", "Usage labels");
    Check(picks.Select(p => p.EmojiId).Distinct().Count() == catalog.Length, "No duplicate quick picks");
    Check(new LocalStore(directory).Preferences.EmojiCounts[coffee.EmojiId!] == 3, "Persist usage");
    store.Preferences.EmojiCounts[coffee.EmojiId!] = long.MaxValue;
    service.Record(coffee);
    Check(store.Preferences.EmojiCounts[coffee.EmojiId!] == long.MaxValue, "Saturate counts");
    store.Preferences.DateFormat = DateDisplayFormat.Iso8601;
    var previousCulture = CultureInfo.CurrentCulture;
    CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("ar-SA");
    Check(store.Preferences.FormatDate(new DateTime(2026, 11, 2)) == "2026-11-02", "ISO date uses Gregorian calendar");
    CultureInfo.CurrentCulture = previousCulture;
    store.Preferences.PickerLayout = PickerLayout.List;
    store.SavePreferences();
    Check(new LocalStore(directory).Preferences.PickerLayout == PickerLayout.List, "Persist picker preference");

    foreach (var invalid in new[] { "not json", "null", "[null]", "[{\"trigger\":null}]" })
    {
        File.WriteAllText(Path.Combine(directory, "snippets.json"), invalid);
        var broken = new LocalStore(directory);
        Check(broken.SnippetLoadError != null, "Detect corrupt snippets: " + invalid);
        Reject(() => broken.SaveSnippet(null, "new", "do not overwrite", true), "Protect corrupt snippet file");
        Check(File.ReadAllText(Path.Combine(directory, "snippets.json")) == invalid, "Leave corrupt file intact");
    }
    File.WriteAllText(Path.Combine(directory, "preferences.json"), "{\"recentIds\":null}");
    var badPreferences = new LocalStore(directory);
    Check(badPreferences.PreferencesLoadError != null, "Detect corrupt preferences");
    Reject(badPreferences.SavePreferences, "Protect corrupt preferences");
}
finally { if (Directory.Exists(directory)) Directory.Delete(directory, true); }
Console.WriteLine($"Passed {assertions} Windows core checks.");

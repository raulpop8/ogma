using System.Text.Json;

namespace Ogma.Core;

public sealed class LocalStore
{
    public static JsonSerializerOptions JsonOptions { get; } = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        WriteIndented = true
    };
    private readonly string directory;
    public IReadOnlyList<TextSnippet> Snippets { get; private set; } = [];
    public Preferences Preferences { get; }
    public string? SnippetLoadError { get; }
    public string? PreferencesLoadError { get; }
    public string DirectoryPath => directory;

    public LocalStore(string? directory = null)
    {
        this.directory = directory ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Ogma");
        try
        {
            Snippets = Read<List<TextSnippet>>("snippets.json") ?? [];
            if (Snippets.Any(s => s is null || s.Trigger is null || s.Replacement is null)
                || Snippets.Select(s => s.Id).Distinct().Count() != Snippets.Count)
                throw new JsonException("Invalid saved shortcuts.");
        }
        catch (Exception e) when (IsStorageError(e)) { Snippets = []; SnippetLoadError = e.Message; }
        try
        {
            Preferences = Read<Preferences>("preferences.json") ?? new();
            if (Preferences.RecentIds is null || Preferences.EmojiCounts is null
                || Preferences.RecentIds.Any(string.IsNullOrEmpty)) throw new JsonException("Invalid emoji history.");
        }
        catch (Exception e) when (IsStorageError(e)) { Preferences = new(); PreferencesLoadError = e.Message; }
    }

    private T? Read<T>(string file) where T : class
    {
        var path = Path.Combine(directory, file);
        return File.Exists(path) ? JsonSerializer.Deserialize<T>(File.ReadAllText(path), JsonOptions)
            ?? throw new JsonException($"{file} contains no data.") : null;
    }

    public void SaveSnippet(Guid? id, string rawTrigger, string replacement, bool enabled)
    {
        RequireSnippets();
        var trigger = rawTrigger.Trim().ToLowerInvariant();
        if (trigger.Length is < 1 or > 32 || !trigger.All(TriggerEngine.IsAllowed))
            throw new ArgumentException("Use 1–32 letters, numbers, underscores, +, or - for a shortcut.");
        if (trigger == "date") throw new ArgumentException("/date is built in. Choose another shortcut name.");
        if (replacement.Length == 0) throw new ArgumentException("Enter replacement text.");
        if (Snippets.Any(s => s.Trigger == trigger && s.Id != id)) throw new ArgumentException("That shortcut already exists.");
        var updated = Snippets.Where(s => s.Id != id).Append(new TextSnippet(id ?? Guid.NewGuid(), trigger, replacement, enabled)).ToArray();
        Persist("snippets.json", updated);
        Snippets = updated;
    }

    public void DeleteSnippet(Guid id)
    {
        RequireSnippets();
        var updated = Snippets.Where(s => s.Id != id).ToArray();
        Persist("snippets.json", updated);
        Snippets = updated;
    }

    private void RequireSnippets()
    {
        if (SnippetLoadError != null) throw new IOException("Saved shortcuts could not be read. The file was left unchanged. " + SnippetLoadError);
    }

    public void SavePreferences()
    {
        if (PreferencesLoadError != null) throw new IOException("Saved preferences could not be read. The file was left unchanged. " + PreferencesLoadError);
        Persist("preferences.json", Preferences);
    }

    private void Persist<T>(string file, T value)
    {
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, file);
        var temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        try
        {
            File.WriteAllText(temporary, JsonSerializer.Serialize(value, JsonOptions));
            File.Move(temporary, path, overwrite: true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }

    public static bool IsStorageError(Exception e) => e is IOException or UnauthorizedAccessException or JsonException;
}

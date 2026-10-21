import Foundation

@main
struct CoreLogicTests {
    static func main() throws {
        let engine = TriggerEngine()
        assert(engine.handle(.character(":")) == .updated(.emoji, ""))
        assert(engine.handle(.character("s")) == .updated(.emoji, "s"))
        assert(engine.handle(.character("m")) == .updated(.emoji, "sm"))
        assert(engine.typedLength == 3)
        assert(engine.handle(.backspace) == .updated(.emoji, "s"))
        assert(engine.handle(.escape) == .cancelled(consume: true))
        assert(!engine.isActive)
        assert(engine.handle(.character(":")) == .updated(.emoji, ""))
        assert(engine.handle(.backspace) == .cancelled(consume: false))
        assert(engine.handle(.character(":")) == .updated(.emoji, ""))
        assert(engine.handle(.character("/")) == .cancelled(consume: false))
        assert(engine.handle(.character("/")) == .updated(.snippet, ""))
        assert(engine.handle(.character("E")) == .updated(.snippet, "e"))
        assert(engine.typedLength == 2)
        assert(engine.handle(.enter) == .accept)
        assert(engine.handle(.left) == .navigateHorizontal(-1))
        assert(engine.handle(.right) == .navigateHorizontal(1))
        engine.reset()
        assert(engine.typedLength == 0)

        let data = try Data(contentsOf: URL(fileURLWithPath: "Ogma/Resources/emoji.json"))
        let items = try JSONDecoder().decode([EmojiItem].self, from: data)
        let search = EmojiSearchService(items: items)
        assert(items.count >= 3900)
        assert(search.search("smile").first?.emoji == "😊")
        assert(search.search("coffee").first?.emoji == "☕")
        assert(search.search("cofee").first?.emoji == "☕")
        assert(search.search("dog").first?.emoji == "🐶")
        for query in ["hug", "hugs", "hugging", "hugging_face", " HUG "] {
            assert(search.search(query).first?.emoji == "🤗")
        }
        assert(search.search("party").count <= 8)
        assert(search.search("joy", limit: 40).map(\.emoji).contains("🤣"))
        assert(search.search("").count == 8)
        assert(search.search("", limit: items.count).count == items.count)
        assert(search.search("sad", limit: 0).isEmpty)
        assert(search.search("", limit: -1).isEmpty)
        assert(items.allSatisfy { !$0.keywords.isEmpty })
        let sad = search.search("sad", limit: items.count).map(\.emoji)
        // The complete set shown in the WhatsApp examples, including related
        // emotions whose Unicode names do not contain the word "sad".
        let sadExamples = ["😭", "😔", "😢", "😞", "🥺", "😟", "😕", "🙁", "☹️",
                           "😖", "😫", "😩", "😥", "😓", "😪", "😿", "💧", "💔"]
        assert(sadExamples.allSatisfy { sad.contains($0) }, "Missing sad emoji: \(sadExamples.filter { !sad.contains($0) })")
        assert(sad.count >= 18)
        assert(!sad.contains("😀"))
        assert(Set(sad).count == sad.count)
        assert(search.search("sad", limit: 5).map(\.emoji) == Array(sad.prefix(5)))
        let emotionExamples = [
            "happy": ["😀", "😃", "😄", "😁", "🤣", "😂", "🥳"],
            "angry": ["😠", "😡", "👿", "😤", "💢"],
            "love": ["🥰", "😍", "😘", "💘"],
            "tired": ["😫", "😪", "😴", "🥱"],
            "celebrate": ["🥳", "🎉", "🎊", "🥂"],
        ]
        for (query, expected) in emotionExamples {
            let results = search.search(query, limit: items.count).map(\.emoji)
            assert(expected.allSatisfy { results.contains($0) }, "Missing \(query) emoji")
        }
        assert(search.search("broken-heart").first?.emoji == "💔")
        assert(search.search("thumbs_up").first?.emoji == "👍")
        assert(search.search("café").contains { $0.emoji == "☕" })
        assert(search.search("-1").first?.emoji == "👎")
        assert(search.search("+1").first?.emoji == "👍")
        assert(!search.search("tired", limit: items.count).contains { $0.emoji == "🛞" })
        assert(search.search("smile", limit: items.count).allSatisfy { $0.emoji != "😢" })
        assert(search.search("zzzzzzzz", limit: items.count).isEmpty)
        let happy = search.search("happy", limit: items.count)
        let unhappyExamples = ["😐", "😑", "😒", "😧", "😢", "😭", "😞", "😩", "😤", "😡", "😠"]
        assert(!happy.contains { unhappyExamples.contains($0.emoji) })
        assert(!happy.contains { $0.name.contains("cartwheeling") })
        assert(search.search("unhappy", limit: items.count).contains { $0.emoji == "😢" })
        assert(search.search("cartwheel", limit: items.count).contains { $0.emoji == "🤸" })
        // Match words within phrases, but never fragments inside unrelated
        // words (happy/unhappy, red/tired, art/heart).
        let boundarySearch = EmojiSearchService(items: [
            EmojiItem(id: "happy", emoji: "😀", name: "happy face", keywords: [], aliases: []),
            EmojiItem(id: "unhappy", emoji: "😢", name: "unhappy face", keywords: [], aliases: []),
            EmojiItem(id: "red", emoji: "🔴", name: "red circle", keywords: [], aliases: []),
            EmojiItem(id: "tired", emoji: "😫", name: "tired face", keywords: [], aliases: []),
            EmojiItem(id: "art", emoji: "🎨", name: "artist palette", keywords: [], aliases: []),
            EmojiItem(id: "heart", emoji: "❤️", name: "red heart", keywords: [], aliases: []),
        ])
        assert(boundarySearch.search("happy").map(\.id) == ["happy"])
        assert(Set(boundarySearch.search("red").map(\.id)) == ["red", "heart"])
        assert(boundarySearch.search("art").map(\.id) == ["art"])
        assert(boundarySearch.search("face").count == 3)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("snippets.json")
        let store = SnippetStore(fileURL: fileURL)
        try store.save(trigger: "Email", replacement: "hello@example.com")
        try store.save(trigger: "signature", replacement: "Best,\nTeam")
        assert(store.snippets.count == 2)
        assert(SnippetStore(fileURL: fileURL).snippets.contains { $0.replacement == "Best,\nTeam" })
        assert((try? store.save(trigger: "EMAIL", replacement: "duplicate")) == nil)
        let snippetSearch = SnippetSearchService()
        assert(snippetSearch.search("em", in: store.snippets).first?.replacement == "hello@example.com")
        assert(store.validationError(trigger: "date", replacement: "fixed") == .reservedTrigger)
        assert(SuggestionItem.date.title == "/date")
        assert(SuggestionItem.date.insertionText.hasSuffix(" "))
        assert(SuggestionItem.emoji(items[0]).insertionText == items[0].emoji + " ")
        let spaced = TextSnippet(id: UUID(), trigger: "space", replacement: "Hello ", isEnabled: true)
        assert(SuggestionItem.snippet(spaced).insertionText == "Hello ")
        let multiline = TextSnippet(id: UUID(), trigger: "line", replacement: "Hello\n", isEnabled: true)
        assert(SuggestionItem.snippet(multiline).insertionText == "Hello\n")
        let testDate = Date(timeIntervalSince1970: 12 * 60 * 60)
        assert(DateDisplayFormat.iso8601.display(testDate) == "1970-01-01")
        let email = store.snippets.first { $0.trigger == "email" }!
        try store.setEnabled(false, for: email.id)
        assert(snippetSearch.search("em", in: store.snippets).isEmpty)
        try store.save(id: email.id, trigger: "contact", replacement: "new@example.com")
        assert(SnippetStore(fileURL: fileURL).snippets.contains { $0.trigger == "contact" && !$0.isEnabled })
        try store.delete(email.id)
        assert(SnippetStore(fileURL: fileURL).snippets.count == 1)
        print("Core logic tests passed")
    }
}

import Foundation

@main
struct EmojiUsageTests {
    static func main() throws {
        let items = try JSONDecoder().decode([EmojiItem].self,
            from: Data(contentsOf: URL(fileURLWithPath: "Ogma/Resources/emoji.json")))
        let suite = "OgmaEmojiUsageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiUsageStore(items: items, defaults: defaults)
        func emoji(_ value: String) -> EmojiItem { items.first { $0.emoji == value }! }
        func use(_ value: String, times: Int = 1) {
            for _ in 0..<times { store.record(emoji(value)) }
        }
        let initial = store.quickPicks()
        assert(initial.map { $0.item.emoji } == ["😊", "😂", "❤️", "👍", "🎉"])
        assert(initial.allSatisfy { !$0.isPersonalized && $0.label == "Suggested" })
        assert(initial.prefix(2).allSatisfy { $0.kind == .recent })
        assert(initial.suffix(3).allSatisfy { $0.kind == .frequent })

        use("😭", times: 8)
        let partial = store.quickPicks()
        assert(partial[0].item.emoji == "😭" && partial[0].isPersonalized)
        assert(partial.dropFirst().allSatisfy { !$0.isPersonalized })
        assert(Set(partial.map(\.id)).count == 5)
        use("😎", times: 5)
        use("🤗", times: 3)
        use("🥳", times: 2)
        use("🐶")
        let picks = store.quickPicks()
        assert(picks.map { $0.item.emoji } == ["🐶", "🥳", "😭", "😎", "🤗"])
        assert(picks.allSatisfy(\.isPersonalized))
        assert(Set(picks.map(\.id)).count == 5)
        assert(picks[0].label == "Recently used" && picks[2].label == "Most used")
        assert(store.quickPicks().map(\.id) == picks.map(\.id))
        let restored = EmojiUsageStore(items: items, defaults: defaults)
        assert(restored.quickPicks().map(\.id) == picks.map(\.id))

        use("😭")
        assert(store.quickPicks().map { $0.item.emoji } == ["😭", "🐶", "😎", "🤗", "🥳"])
        use("😭")
        assert(store.quickPicks().prefix(2).map { $0.item.emoji } == ["😭", "🐶"])
        use("❤️", times: 3)
        use("😊")
        assert(store.quickPicks().suffix(3).map { $0.item.emoji } == ["😭", "😎", "🤗"])
        use("🎉")
        // Equal frequency is resolved by most recent use.
        assert(store.quickPicks().suffix(3).map { $0.item.emoji } == ["😭", "😎", "❤️"])

        let tiny = EmojiUsageStore(items: Array(items.prefix(1)), defaults: defaults)
        assert(tiny.quickPicks().count == 1)
        let empty = EmojiUsageStore(items: [], defaults: defaults)
        assert(empty.quickPicks().isEmpty)
        defaults.set(Data("not JSON".utf8), forKey: "emojiUsageHistory")
        assert(EmojiUsageStore(items: items, defaults: defaults).quickPicks().allSatisfy { !$0.isPersonalized })
        print("Emoji recency, frequency, persistence, and fallback checks passed")
    }
}

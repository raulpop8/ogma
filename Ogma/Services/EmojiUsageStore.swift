import Foundation

final class EmojiUsageStore {
    private struct History: Codable {
        var recentIDs: [String] = []
        var counts: [String: Int] = [:]
    }

    private static let preferenceKey = "emojiUsageHistory"
    private let defaults: UserDefaults
    private let items: [EmojiItem]
    private let itemsByID: [String: EmojiItem]
    private var history: History

    init(items: [EmojiItem], defaults: UserDefaults = .standard) {
        self.items = items
        self.defaults = defaults
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        if let data = defaults.data(forKey: Self.preferenceKey),
           let saved = try? JSONDecoder().decode(History.self, from: data) {
            history = saved
        } else {
            history = History()
        }
        history.counts = history.counts.filter { itemsByID[$0.key] != nil && $0.value > 0 }
        var seen = Set<String>()
        history.recentIDs = history.recentIDs.filter { history.counts[$0] != nil && seen.insert($0).inserted }
    }

    // Called only after Ogma posts a replacement successfully. Browsing,
    // searching, hovering, and cancelling never change usage history.
    func record(_ item: EmojiItem) {
        guard itemsByID[item.id] != nil else { return }
        let count = history.counts[item.id, default: 0]
        history.counts[item.id] = count < Int.max ? count + 1 : count
        history.recentIDs.removeAll { $0 == item.id }
        history.recentIDs.insert(item.id, at: 0)
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: Self.preferenceKey)
        }
    }

    func quickPicks() -> [EmojiQuickPick] {
        var picks: [EmojiQuickPick] = []
        var included = Set<String>()
        let common = ["😊", "😂", "❤️", "👍", "🎉"].compactMap { emoji in items.first { $0.emoji == emoji } }
        let fallback = common + items

        func append(_ item: EmojiItem, kind: EmojiQuickPick.Kind, personalized: Bool) {
            guard included.insert(item.id).inserted else { return }
            picks.append(EmojiQuickPick(item: item, kind: kind, isPersonalized: personalized))
        }

        for id in history.recentIDs.prefix(2) {
            if let item = itemsByID[id] { append(item, kind: .recent, personalized: true) }
        }
        for item in fallback where picks.count < 2 {
            append(item, kind: .recent, personalized: false)
        }

        let recency = Dictionary(uniqueKeysWithValues: history.recentIDs.enumerated().map { ($0.element, $0.offset) })
        let frequent = history.counts.keys.sorted { left, right in
            let leftCount = history.counts[left, default: 0]
            let rightCount = history.counts[right, default: 0]
            if leftCount != rightCount { return leftCount > rightCount }
            let leftRecency = recency[left, default: Int.max]
            let rightRecency = recency[right, default: Int.max]
            if leftRecency != rightRecency { return leftRecency < rightRecency }
            return left < right
        }
        for id in frequent where picks.count < 5 {
            if let item = itemsByID[id] { append(item, kind: .frequent, personalized: true) }
        }
        for item in fallback where picks.count < 5 {
            append(item, kind: .frequent, personalized: false)
        }
        return picks
    }
}

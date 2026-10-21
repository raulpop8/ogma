import Foundation

struct EmojiQuickPick: Identifiable {
    enum Kind { case recent, frequent }

    let item: EmojiItem
    let kind: Kind
    let isPersonalized: Bool

    var id: String { item.id }

    var label: String {
        guard isPersonalized else { return "Suggested" }
        return kind == .recent ? "Recently used" : "Most used"
    }
}

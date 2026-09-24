import Foundation

enum SuggestionItem: Identifiable {
    case emoji(EmojiItem)
    case snippet(TextSnippet)

    var id: String {
        switch self {
        case .emoji(let item): return "emoji:\(item.id)"
        case .snippet(let item): return "snippet:\(item.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .emoji(let item): return item.name
        case .snippet(let item): return "/" + item.trigger
        }
    }

    var detail: String? {
        if case .snippet(let item) = self {
            return item.replacement.replacingOccurrences(of: "\n", with: " ↵ ")
        }
        return nil
    }

    var replacement: String {
        switch self {
        case .emoji(let item): return item.emoji
        case .snippet(let item): return item.replacement
        }
    }

    var rowHeight: CGFloat {
        if case .snippet = self { return 46 }
        return 34
    }
}

import Foundation

enum DateDisplayFormat: String, CaseIterable {
    case systemShort
    case systemLong
    case iso8601

    static let preferenceKey = "dateDisplayFormat"

    var title: String {
        switch self {
        case .systemShort: "System short"
        case .systemLong: "System long"
        case .iso8601: "YYYY-MM-DD"
        }
    }

    static var preferred: DateDisplayFormat {
        DateDisplayFormat(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "") ?? .systemShort
    }

    func display(_ date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        switch self {
        case .systemShort:
            formatter.locale = .autoupdatingCurrent
            formatter.dateStyle = .short
        case .systemLong:
            formatter.locale = .autoupdatingCurrent
            formatter.dateStyle = .long
        case .iso8601:
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return formatter.string(from: date)
    }
}

enum SuggestionItem: Identifiable {
    case emoji(EmojiItem)
    case snippet(TextSnippet)
    case date

    var id: String {
        switch self {
        case .emoji(let item): return "emoji:\(item.id)"
        case .snippet(let item): return "snippet:\(item.id.uuidString)"
        case .date: return "date"
        }
    }

    var title: String {
        switch self {
        case .emoji(let item): return item.name
        case .snippet(let item): return "/" + item.trigger
        case .date: return "/date"
        }
    }

    var detail: String? {
        if case .snippet(let item) = self {
            return item.replacement.replacingOccurrences(of: "\n", with: " ↵ ")
        }
        if case .date = self { return DateDisplayFormat.preferred.display() }
        return nil
    }

    var replacement: String {
        switch self {
        case .emoji(let item): return item.emoji
        case .snippet(let item): return item.replacement
        case .date: return DateDisplayFormat.preferred.display()
        }
    }

    var rowHeight: CGFloat {
        if case .emoji = self { return 34 }
        return 46
    }

    var insertionText: String {
        let text = replacement
        return text.last?.isWhitespace == true ? text : text + " "
    }
}

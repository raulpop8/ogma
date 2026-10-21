import Foundation

final class EmojiSearchService {
    let items: [EmojiItem]
    private let index: [Entry]

    private struct Entry {
        let item: EmojiItem
        let name: String
        let aliases: [String]
        let keywords: [String]
        let words: [String]

        init(_ item: EmojiItem) {
            self.item = item
            name = EmojiSearchService.normalize(item.name)
            aliases = item.aliases.map(EmojiSearchService.normalize)
            keywords = item.keywords.map(EmojiSearchService.normalize)
            words = Array(Set(([name] + aliases + keywords).flatMap { $0.split(separator: " ").map(String.init) }))
        }
    }

    convenience init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "emoji", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([EmojiItem].self, from: data) else {
            self.init(items: [])
            return
        }
        self.init(items: items)
    }

    init(items: [EmojiItem]) {
        self.items = items
        index = items.map(Entry.init)
    }

    func search(_ rawQuery: String, limit: Int = 8) -> [EmojiItem] {
        guard limit > 0 else { return [] }
        let query = Self.normalize(rawQuery)
        guard !query.isEmpty else { return Array(items.prefix(limit)) }

        let queryWords = query.split(separator: " ").map(String.init)
        var matches = index.enumerated().compactMap { offset, entry -> (item: EmojiItem, score: Int, offset: Int)? in
            let aliases = entry.aliases
            let keywords = entry.keywords
            let score: Int
            if aliases.contains(query) { score = 0 }
            else if entry.name == query { score = 1 }
            else if aliases.contains(where: { $0.hasPrefix(query) }) { score = 2 }
            else if entry.name.hasPrefix(query) { score = 3 }
            else if keywords.contains(query) { score = 4 }
            else if queryWords.allSatisfy({ word in entry.words.contains(where: { $0.hasPrefix(word) }) }) { score = 5 }
            else { return nil }
            return (entry.item, score, offset)
        }
        // Correct misspellings only when direct search found nothing. Mixing
        // near-spellings into real matches offered wheels for "tired" (tire).
        if matches.isEmpty, query.count >= 4, queryWords.count == 1 {
            matches = index.enumerated().compactMap { offset, entry in
                entry.words.contains(where: { Self.isNear(query, $0) }) ? (entry.item, 7, offset) : nil
            }
        }
        matches.sort { left, right in
            if left.score != right.score { return left.score < right.score }
            return left.offset < right.offset
        }

        return matches.prefix(limit).map(\.item)
    }

    private static func normalize(_ text: String) -> String {
        // Preserve the conventional thumbs-down alias while treating other
        // hyphens like spaces in names such as "broken-heart".
        if text.trimmingCharacters(in: .whitespacesAndNewlines) == "-1" { return "-1" }
        return text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func isNear(_ query: String, _ candidate: String) -> Bool {
        let a = Array(query)
        let b = Array(candidate)
        guard abs(a.count - b.count) <= 1 else { return false }
        if a.count == b.count {
            let mismatches = a.indices.filter { a[$0] != b[$0] }
            if mismatches.count <= 1 { return true }
            return mismatches.count == 2
                && mismatches[1] == mismatches[0] + 1
                && a[mismatches[0]] == b[mismatches[1]]
                && a[mismatches[1]] == b[mismatches[0]]
        }
        let short = a.count < b.count ? a : b
        let long = a.count < b.count ? b : a
        for omitted in long.indices {
            var copy = long
            copy.remove(at: omitted)
            if copy == short { return true }
        }
        return false
    }
}

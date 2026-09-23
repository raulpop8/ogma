import Foundation

final class EmojiSearchService {
    let items: [EmojiItem]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "emoji", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([EmojiItem].self, from: data) else {
            self.items = []
            return
        }
        self.items = items
    }

    init(items: [EmojiItem]) {
        self.items = items
    }

    func search(_ rawQuery: String, limit: Int = 8) -> [EmojiItem] {
        let query = rawQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return items.compactMap { item -> (EmojiItem, Int)? in
            let names = [item.name.lowercased()]
            let aliases = item.aliases.map { $0.lowercased() }
            let keywords = item.keywords.map { $0.lowercased() }
            let score: Int
            if aliases.contains(query) { score = 0 }
            else if names.contains(query) { score = 1 }
            else if aliases.contains(where: { $0.hasPrefix(query) }) { score = 2 }
            else if names.contains(where: { $0.hasPrefix(query) }) { score = 3 }
            else if keywords.contains(where: { $0.hasPrefix(query) }) { score = 4 }
            else if (aliases + names + keywords).contains(where: { $0.contains(query) }) { score = 5 }
            else if query.count >= 4,
                    (aliases + names.flatMap { $0.split(separator: " ").map(String.init) } + keywords)
                        .contains(where: { Self.isNear(query, $0) }) { score = 6 }
            else { return nil }
            return (item, score)
        }
        .sorted { left, right in
            if left.1 != right.1 { return left.1 < right.1 }
            return left.0.name < right.0.name
        }
        .prefix(limit)
        .map(\.0)
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

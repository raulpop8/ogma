import Foundation

struct SnippetSearchService {
    func search(_ query: String, in snippets: [TextSnippet], limit: Int = 8) -> [TextSnippet] {
        let query = query.lowercased()
        return snippets.filter(\.isEnabled)
            .compactMap { snippet -> (TextSnippet, Int)? in
                if query.isEmpty { return (snippet, 3) }
                if snippet.trigger == query { return (snippet, 0) }
                if snippet.trigger.hasPrefix(query) { return (snippet, 1) }
                if snippet.trigger.contains(query) { return (snippet, 2) }
                return nil
            }
            .sorted { left, right in
                if left.1 != right.1 { return left.1 < right.1 }
                return left.0.trigger < right.0.trigger
            }
            .prefix(limit)
            .map(\.0)
    }
}

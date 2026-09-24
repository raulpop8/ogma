import Foundation

struct TextSnippet: Identifiable, Codable, Hashable {
    var id: UUID
    var trigger: String
    var replacement: String
    var isEnabled: Bool
}

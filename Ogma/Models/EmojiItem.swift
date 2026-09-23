import Foundation

struct EmojiItem: Identifiable, Codable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let keywords: [String]
    let aliases: [String]
}

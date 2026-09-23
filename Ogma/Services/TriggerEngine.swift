import Foundation

final class TriggerEngine {
    enum Key {
        case character(String)
        case backspace
        case up
        case down
        case enter
        case escape
        case other
    }

    enum Outcome: Equatable {
        case none
        case updated(String)
        case navigate(Int)
        case accept
        case cancelled(consume: Bool)
    }

    private(set) var query: String?
    var isActive: Bool { query != nil }
    var typedLength: Int { (query?.utf16.count ?? -1) + 1 }

    func reset() { query = nil }

    func handle(_ key: Key) -> Outcome {
        guard let current = query else {
            if case .character(":") = key {
                query = ""
                return .updated("")
            }
            return .none
        }

        switch key {
        case .character(let value):
            guard value.count == 1,
                  value.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-").contains($0) }),
                  current.count < 32 else {
                reset()
                return .cancelled(consume: false)
            }
            query = current + value.lowercased()
            return .updated(query!)
        case .backspace:
            guard !current.isEmpty else {
                reset()
                return .cancelled(consume: false)
            }
            query = String(current.dropLast())
            return .updated(query!)
        case .up: return .navigate(-1)
        case .down: return .navigate(1)
        case .enter: return .accept
        case .escape:
            reset()
            return .cancelled(consume: true)
        case .other:
            reset()
            return .cancelled(consume: false)
        }
    }
}

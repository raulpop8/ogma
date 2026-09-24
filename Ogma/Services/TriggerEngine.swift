import Foundation

final class TriggerEngine {
    enum Mode: Equatable {
        case emoji
        case snippet

        var triggerCharacter: String { self == .emoji ? ":" : "/" }
    }

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
        case updated(Mode, String)
        case navigate(Int)
        case accept
        case cancelled(consume: Bool)
    }

    private(set) var mode: Mode?
    private(set) var query: String?
    var isActive: Bool { mode != nil }
    var typedLength: Int { isActive ? 1 + (query?.utf16.count ?? 0) : 0 }

    func reset() {
        mode = nil
        query = nil
    }

    func handle(_ key: Key) -> Outcome {
        guard let current = query, let mode else {
            if case .character(let value) = key, value == ":" || value == "/" {
                let newMode: Mode = value == ":" ? .emoji : .snippet
                mode = newMode
                query = ""
                return .updated(newMode, "")
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
            let next = current + value.lowercased()
            query = next
            return .updated(mode, next)
        case .backspace:
            guard !current.isEmpty else {
                reset()
                return .cancelled(consume: false)
            }
            let next = String(current.dropLast())
            query = next
            return .updated(mode, next)
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

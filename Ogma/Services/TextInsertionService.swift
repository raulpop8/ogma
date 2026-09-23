import CoreGraphics

final class TextInsertionService {
    // This marker prevents Ogma's event tap from processing its own replacement events.
    static let eventMarker: Int64 = 0x4F474D41

    func replaceTrigger(length: Int, with replacement: String) -> Bool {
        guard length > 0, !replacement.isEmpty,
              let source = CGEventSource(stateID: .hidSystemState) else { return false }

        for _ in 0..<length {
            guard postKey(51, source: source) else { return false }
        }
        let utf16 = Array(replacement.utf16)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return false }
        down.setIntegerValueField(.eventSourceUserData, value: Self.eventMarker)
        up.setIntegerValueField(.eventSourceUserData, value: Self.eventMarker)
        utf16.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
            up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    private func postKey(_ code: CGKeyCode, source: CGEventSource) -> Bool {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else { return false }
        down.setIntegerValueField(.eventSourceUserData, value: Self.eventMarker)
        up.setIntegerValueField(.eventSourceUserData, value: Self.eventMarker)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}

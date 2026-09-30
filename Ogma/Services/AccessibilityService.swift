import AppKit
import ApplicationServices

final class AccessibilityService {
    private var preparedPID: pid_t?

    func focusedApplicationPID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    func isSecureField() -> Bool {
        guard AXIsProcessTrusted(), var element = focusedElement() else { return false }
        for _ in 0..<5 {
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value)
            if value as? String == "AXSecureTextField" { return true }
            guard let parent = elementAttribute(element, kAXParentAttribute) else { break }
            element = parent
        }
        return false
    }

    func prepareForTyping(in pid: pid_t) {
        guard AXIsProcessTrusted(), preparedPID != pid else { return }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.05)
        // Electron documents this attribute for assistive clients. Unsupported
        // applications simply ignore it; it does not turn on VoiceOver.
        // https://www.electronjs.org/docs/latest/tutorial/accessibility#macos
        let result = AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        if result == .success || result == .attributeUnsupported { preparedPID = pid }
    }

    func typingAnchor() -> TypingAnchor? {
        guard AXIsProcessTrusted(), let element = focusedElement() else { return nil }
        var candidates = [element]
        var current = element
        // Web editors can expose selection geometry on an editable ancestor
        // rather than the focused inline child. Never search by mouse position.
        for _ in 0..<4 {
            guard let parent = elementAttribute(current, kAXParentAttribute) else { break }
            candidates.append(parent)
            current = parent
        }
        for candidate in candidates {
            var subrole: CFTypeRef?
            AXUIElementCopyAttributeValue(candidate, kAXSubroleAttribute as CFString, &subrole)
            if subrole as? String == "AXSecureTextField" { return nil }
        }
        for candidate in candidates {
            if let caret = caretAnchor(candidate) { return caret }
            if let rect = markerRect(candidate), rect.width <= rect.height {
                return TypingAnchor(rect: rect, source: .caret)
            }
        }
        for candidate in candidates {
            if let rect = fieldRect(candidate) {
                return TypingAnchor(rect: rect, source: .textField)
            }
        }
        return nil
    }

    private func caretAnchor(_ element: AXUIElement) -> TypingAnchor? {
        var selectedRange: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRange) == .success,
              let selectedRange,
              CFGetTypeID(selectedRange) == AXValueGetTypeID(),
              AXValueGetType(selectedRange as! AXValue) == .cfRange else { return nil }
        var range = CFRange()
        guard AXValueGetValue(selectedRange as! AXValue, .cfRange, &range),
              range.location >= 0, range.length >= 0,
              range.location <= Int.max - range.length else { return nil }
        // Ask for the insertion point instead of the width of any selected text.
        let index = range.location + range.length
        let previousCharacter = index > 0
            ? rangeRect(CFRange(location: index - 1, length: 1), in: element) : nil
        // Estimate an average glyph width from line height. Using the last
        // glyph's width would make the popup bounce between letters like i/m.
        let characterWidth = previousCharacter.map { min(14, max(6, $0.height * 0.4)) } ?? 8
        if let rect = rangeRect(CFRange(location: index, length: 0), in: element), rect.width <= rect.height {
            return TypingAnchor(rect: rect, source: .caret, characterWidth: characterWidth)
        }
        // Some editors don't support zero-length ranges. Shortcut characters
        // are ASCII, so the preceding glyph's trailing edge gives their caret.
        if let rect = previousCharacter, rect.width <= rect.height {
            return TypingAnchor(rect: CGRect(x: rect.maxX, y: rect.minY, width: 0, height: rect.height),
                                source: .caret, characterWidth: characterWidth)
        }
        return nil
    }

    private func rangeRect(_ range: CFRange, in element: AXUIElement) -> CGRect? {
        var range = range
        guard let value = AXValueCreate(.cfRange, &range) else { return nil }
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element,
            kAXBoundsForRangeParameterizedAttribute as CFString, value, &bounds) == .success else { return nil }
        return rectValue(bounds)
    }

    private func markerRect(_ element: AXUIElement) -> CGRect? {
        // WebKit contenteditable elements may use text markers instead of
        // integer character ranges. Pass the opaque marker back to its owner.
        var marker: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, "AXSelectedTextMarkerRange" as CFString, &marker) == .success,
              let marker else { return nil }
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element,
            "AXBoundsForTextMarkerRange" as CFString, marker, &bounds) == .success else { return nil }
        return rectValue(bounds)
    }

    private func rectValue(_ bounds: CFTypeRef?) -> CGRect? {
        guard let bounds,
              CFGetTypeID(bounds) == AXValueGetTypeID(),
              AXValueGetType(bounds as! AXValue) == .cgRect else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect),
              TypingAnchor(rect: rect, source: .caret).isValid else { return nil }
        return rect
    }

    private func fieldRect(_ element: AXUIElement) -> CGRect? {
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
              let role = role as? String,
              ["AXTextField", "AXTextArea", "AXComboBox"].contains(role) else { return nil }
        var position: CFTypeRef?
        var size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size) == .success,
              let position, let size,
              CFGetTypeID(position) == AXValueGetTypeID(),
              CFGetTypeID(size) == AXValueGetTypeID(),
              AXValueGetType(position as! AXValue) == .cgPoint,
              AXValueGetType(size as! AXValue) == .cgSize else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
              AXValueGetValue(size as! AXValue, .cgSize, &dimensions),
              point.x.isFinite, point.y.isFinite,
              dimensions.width.isFinite, dimensions.height.isFinite,
              dimensions.width > 0, dimensions.height > 0 else { return nil }
        return CGRect(origin: point, size: dimensions)
    }

    private func focusedElement() -> AXUIElement? {
        if let pid = focusedApplicationPID(),
           let focused = elementAttribute(AXUIElementCreateApplication(pid), kAXFocusedUIElementAttribute) {
            return focused
        }
        let system = AXUIElementCreateSystemWide()
        return elementAttribute(system, kAXFocusedUIElementAttribute)
    }

    private func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        // A busy editor must not stall the keyboard listener for the default
        // multi-second AX timeout. Temporary failures keep the existing anchor.
        AXUIElementSetMessagingTimeout(element, 0.03)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let result = value as! AXUIElement
        AXUIElementSetMessagingTimeout(result, 0.03)
        return result
    }
}

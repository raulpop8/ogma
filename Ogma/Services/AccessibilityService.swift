import AppKit
import ApplicationServices

final class AccessibilityService {
    func focusedApplicationPID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    func isSecureField() -> Bool {
        guard AXIsProcessTrusted(), let element = focusedElement() else { return false }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value) == .success else {
            return false
        }
        return (value as? String) == "AXSecureTextField"
    }

    func caretRect() -> CGRect? {
        guard AXIsProcessTrusted(), let element = focusedElement() else { return nil }
        var selectedRange: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRange) == .success,
              let selectedRange,
              CFGetTypeID(selectedRange) == AXValueGetTypeID(),
              AXValueGetType(selectedRange as! AXValue) == .cfRange else { return fieldRect(element) }
        var range = CFRange()
        guard AXValueGetValue(selectedRange as! AXValue, .cfRange, &range),
              range.location >= 0, range.length >= 0,
              range.location <= Int.max - range.length else { return fieldRect(element) }
        // Ask for the insertion point instead of the width of any selected text.
        var insertionRange = CFRange(location: range.location + range.length, length: 0)
        guard let insertionValue = AXValueCreate(.cfRange, &insertionRange) else { return fieldRect(element) }
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            insertionValue,
            &bounds) == .success,
              let bounds,
              CFGetTypeID(bounds) == AXValueGetTypeID(),
              AXValueGetType(bounds as! AXValue) == .cgRect else { return fieldRect(element) }
        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect),
              !rect.isNull, !rect.isInfinite, rect.height > 0 else { return fieldRect(element) }
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
              dimensions.width > 0, dimensions.height > 0 else { return nil }
        return CGRect(origin: point, size: dimensions)
    }

    private func focusedElement() -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}

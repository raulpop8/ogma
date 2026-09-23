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
              CFGetTypeID(selectedRange) == AXValueGetTypeID() else { return nil }
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            selectedRange,
            &bounds) == .success,
              let bounds,
              CFGetTypeID(bounds) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect) else { return nil }
        return rect
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

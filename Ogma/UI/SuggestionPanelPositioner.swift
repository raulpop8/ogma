import CoreGraphics

struct TypingAnchor {
    enum Source: Int { case window, textField, textClick, caret }
    let rect: CGRect
    let source: Source
    var characterWidth: CGFloat = 8

    var isValid: Bool {
        rect.origin.x.isFinite && rect.origin.y.isFinite
            && rect.width.isFinite && rect.height.isFinite
            && rect.width >= 0 && rect.height > 0
    }
}

struct SuggestionAnchorTracker {
    private(set) var anchor: TypingAnchor?

    mutating func update(_ candidate: TypingAnchor?) {
        guard let candidate, candidate.isValid else { return }
        if let anchor, candidate.source.rawValue < anchor.source.rawValue { return }
        anchor = candidate
    }

    mutating func reset() { anchor = nil }
}

enum SuggestionPanelPositioner {
    static func isUsableCaret(_ rect: CGRect, field: CGRect?, window: CGRect?) -> Bool {
        guard TypingAnchor(rect: rect, source: .caret).isValid,
              rect.width <= rect.height, rect.height <= 160 else { return false }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Editors sometimes return a non-empty placeholder rectangle at the
        // screen origin, or the bounds of an entire document, as a caret.
        for container in [field, window].compactMap({ $0 }) {
            guard container.insetBy(dx: -2, dy: -2).contains(center) else { return false }
        }
        return true
    }

    static func fieldAnchor(in field: CGRect, click: CGPoint?) -> TypingAnchor {
        if let click, field.contains(click) {
            return TypingAnchor(rect: CGRect(x: click.x, y: click.y - 10, width: 0, height: 20),
                                source: .textClick)
        }
        // Field bounds describe the whole editor, not its insertion point.
        // Use a line-sized anchor so a tall editor cannot push the panel into
        // a screen corner. A later real caret always takes precedence.
        let height = min(field.height, 24)
        return TypingAnchor(rect: CGRect(x: field.midX, y: field.midY - height / 2,
                                        width: 0, height: height), source: .textField)
    }

    // This approximate anchor is used only when the editor supplies no text
    // geometry. A click is recorded once, never sampled as the pointer moves.
    static func fallbackAnchor(in window: CGRect, click: CGPoint?) -> TypingAnchor {
        if let click, window.insetBy(dx: 8, dy: 8).contains(click) {
            return TypingAnchor(rect: CGRect(x: click.x, y: click.y - 10, width: 0, height: 20),
                                source: .textClick)
        }
        return TypingAnchor(rect: CGRect(x: window.midX,
                                        y: window.midY - 10,
                                        width: 0, height: 20), source: .window)
    }

    static func frame(for caret: CGRect, size: CGSize, in visibleFrame: CGRect,
                      characterWidth: CGFloat = 8) -> CGRect {
        let gap = clamp(characterWidth.isFinite ? characterWidth : 8, 6, 14) * 2.5
        let width = min(size.width, visibleFrame.width)
        let height = min(size.height, visibleFrame.height)
        // Align with the insertion point and keep the active line uncovered.
        let x = clamp(caret.minX, visibleFrame.minX, visibleFrame.maxX - width)
        let below = caret.minY - gap - height
        if below >= visibleFrame.minY {
            return CGRect(x: x, y: below, width: width, height: height)
        }

        let above = caret.maxY + gap
        if above + height <= visibleFrame.maxY {
            return CGRect(x: x, y: above, width: width, height: height)
        }

        let y = caret.minY - visibleFrame.minY > visibleFrame.maxY - caret.maxY
            ? visibleFrame.minY : visibleFrame.maxY - height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func clamp(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

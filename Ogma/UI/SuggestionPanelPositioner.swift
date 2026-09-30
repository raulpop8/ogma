import CoreGraphics

struct TypingAnchor {
    enum Source { case caret, textField }
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
        // A temporarily unavailable caret must not replace a precise location
        // with the bounds of the whole field during the same typing session.
        if candidate.source == .textField, let anchor, anchor.source == .caret,
           candidate.rect.insetBy(dx: -2, dy: -2).contains(CGPoint(x: anchor.rect.midX, y: anchor.rect.midY)) {
            return
        }
        anchor = candidate
    }

    mutating func reset() { anchor = nil }
}

enum SuggestionPanelPositioner {
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

import CoreGraphics

enum SuggestionPanelPositioner {
    private static let gap: CGFloat = 4

    static func frame(for caret: CGRect, size: CGSize, in visibleFrame: CGRect) -> CGRect {
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

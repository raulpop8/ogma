import CoreGraphics

enum SuggestionPanelPositioner {
    private static let gap: CGFloat = 12

    static func frame(for caret: CGRect, size: CGSize, in visibleFrame: CGRect) -> CGRect {
        let width = min(size.width, visibleFrame.width)
        let height = min(size.height, visibleFrame.height)
        let sideY = clamp(caret.maxY - height, visibleFrame.minY, visibleFrame.maxY - height)

        // Leave room for the text immediately around the caret on wider displays.
        let distantRight = caret.maxX + size.width + gap
        if distantRight + width <= visibleFrame.maxX {
            return CGRect(x: distantRight, y: sideY, width: width, height: height)
        }

        let nearRight = caret.maxX + gap
        if nearRight + width <= visibleFrame.maxX {
            return CGRect(x: nearRight, y: sideY, width: width, height: height)
        }

        let distantLeft = caret.minX - size.width - gap - width
        if distantLeft >= visibleFrame.minX {
            return CGRect(x: distantLeft, y: sideY, width: width, height: height)
        }

        let nearLeft = caret.minX - gap - width
        if nearLeft >= visibleFrame.minX {
            return CGRect(x: nearLeft, y: sideY, width: width, height: height)
        }

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

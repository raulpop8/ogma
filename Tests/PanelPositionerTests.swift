import CoreGraphics

@main
struct PanelPositionerTests {
    static func main() {
        let size = CGSize(width: 300, height: 120)
        let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let writingCaret = CGRect(x: 300, y: 400, width: 1, height: 20)
        let clearOfText = SuggestionPanelPositioner.frame(for: writingCaret, size: size, in: screen)
        precondition(clearOfText.minX == writingCaret.minX)
        precondition(clearOfText.maxY == writingCaret.minY - 20)
        precondition(!clearOfText.intersects(writingCaret))

        let rightCaret = CGRect(x: 1150, y: 400, width: 1, height: 20)
        let edgePlacement = SuggestionPanelPositioner.frame(for: rightCaret, size: size, in: screen)
        precondition(edgePlacement.maxX == screen.maxX)
        precondition(edgePlacement.maxY == rightCaret.minY - 20)

        let narrowScreen = CGRect(x: 0, y: 0, width: 300, height: 800)
        let middleCaret = CGRect(x: 150, y: 400, width: 1, height: 20)
        let belowPlacement = SuggestionPanelPositioner.frame(for: middleCaret, size: size, in: narrowScreen)
        precondition(belowPlacement.maxY < middleCaret.minY)

        let bottomCaret = CGRect(x: 150, y: 20, width: 1, height: 20)
        let abovePlacement = SuggestionPanelPositioner.frame(for: bottomCaret, size: size, in: narrowScreen)
        precondition(abovePlacement.minY > bottomCaret.maxY)

        let secondScreen = CGRect(x: -1440, y: 0, width: 1440, height: 900)
        let secondCaret = CGRect(x: -1100, y: 500, width: 1, height: 20)
        let secondPlacement = SuggestionPanelPositioner.frame(for: secondCaret, size: size, in: secondScreen)
        precondition(secondScreen.contains(secondPlacement))
        precondition(secondPlacement.minX == secondCaret.minX)

        let wideSelection = CGRect(x: 100, y: 400, width: 450, height: 20)
        let selectionPlacement = SuggestionPanelPositioner.frame(for: wideSelection, size: size, in: screen)
        precondition(selectionPlacement.minX == wideSelection.minX)
        precondition(!selectionPlacement.intersects(wideSelection))

        let largeText = SuggestionPanelPositioner.frame(for: writingCaret, size: size, in: screen, characterWidth: 12)
        precondition(largeText.maxY == writingCaret.minY - 30)

        var tracker = SuggestionAnchorTracker()
        tracker.update(nil)
        precondition(tracker.anchor == nil)
        let exact = TypingAnchor(rect: writingCaret, source: .caret, characterWidth: 7)
        tracker.update(exact)
        // Missing geometry while typing preserves the location, with no mouse input.
        for _ in 0..<10 { tracker.update(nil) }
        precondition(tracker.anchor?.rect == writingCaret)
        tracker.update(TypingAnchor(rect: CGRect(x: 200, y: 300, width: 500, height: 200), source: .textField))
        precondition(tracker.anchor?.rect == writingCaret)
        let advancedCaret = writingCaret.offsetBy(dx: 14, dy: 0)
        tracker.update(TypingAnchor(rect: advancedCaret, source: .caret))
        precondition(tracker.anchor?.rect == advancedCaret)
        tracker.update(TypingAnchor(rect: CGRect(x: CGFloat.nan, y: 0, width: 0, height: 20), source: .caret))
        precondition(tracker.anchor?.rect == advancedCaret)
        tracker.reset()
        tracker.update(nil)
        precondition(tracker.anchor == nil)
        tracker.update(TypingAnchor(rect: secondCaret, source: .textField))
        precondition(tracker.anchor?.rect == secondCaret)

        let fallbackWindow = CGRect(x: 100, y: 100, width: 800, height: 600)
        let clicked = CGPoint(x: 250, y: 620)
        let clickAnchor = SuggestionPanelPositioner.fallbackAnchor(in: fallbackWindow, click: clicked)
        precondition(clickAnchor.source == .textClick && clickAnchor.rect.midY == clicked.y)
        let windowAnchor = SuggestionPanelPositioner.fallbackAnchor(in: fallbackWindow, click: CGPoint(x: 0, y: 0))
        precondition(windowAnchor.source == .window && fallbackWindow.contains(windowAnchor.rect))
        precondition(windowAnchor.rect.midX == fallbackWindow.midX)
        precondition(windowAnchor.rect.midY == fallbackWindow.midY)
        let editor = CGRect(x: 200, y: 200, width: 600, height: 400)
        let fieldAnchor = SuggestionPanelPositioner.fieldAnchor(in: editor, click: nil)
        precondition(fieldAnchor.rect.height == 24 && fieldAnchor.rect.width == 0)
        precondition(fieldAnchor.rect.midY == editor.midY)
        let textClick = CGPoint(x: 350, y: 500)
        let clickedField = SuggestionPanelPositioner.fieldAnchor(in: editor, click: textClick)
        precondition(clickedField.source == .textClick)
        precondition(clickedField.rect.midX == textClick.x && clickedField.rect.midY == textClick.y)
        let toolbarClick = SuggestionPanelPositioner.fieldAnchor(in: editor, click: CGPoint(x: 150, y: 130))
        precondition(toolbarClick.source == .textField)
        let realCaret = CGRect(x: 350, y: 490, width: 0, height: 20)
        precondition(SuggestionPanelPositioner.isUsableCaret(realCaret, field: editor, window: fallbackWindow))
        precondition(!SuggestionPanelPositioner.isUsableCaret(CGRect(x: 0, y: 0, width: 1, height: 20),
                                                              field: editor, window: fallbackWindow))
        precondition(!SuggestionPanelPositioner.isUsableCaret(editor, field: editor, window: fallbackWindow))
        precondition(!SuggestionPanelPositioner.isUsableCaret(CGRect(x: 350, y: 200, width: 1, height: 400),
                                                              field: editor, window: fallbackWindow))
        precondition(SuggestionPanelPositioner.isUsableCaret(secondCaret, field: nil, window: secondScreen))
        tracker.reset()
        tracker.update(clickedField)
        tracker.update(fieldAnchor)
        precondition(tracker.anchor?.rect == clickedField.rect)
        tracker.reset()
        tracker.update(windowAnchor)
        tracker.update(clickAnchor)
        tracker.update(windowAnchor)
        precondition(tracker.anchor?.rect == clickAnchor.rect)
        tracker.update(exact)
        tracker.update(clickAnchor)
        precondition(tracker.anchor?.rect == exact.rect)
        print("Panel placement checks passed")
    }
}

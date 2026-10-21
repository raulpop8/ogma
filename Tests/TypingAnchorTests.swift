import AppKit

@main
struct TypingAnchorTests {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.prohibited)
        let controller = SuggestionPanelController()
        guard let primary = NSScreen.screens.first else { fatalError("A display is required") }
        let caret = CGRect(x: primary.visibleFrame.midX - 100,
                           y: primary.frame.maxY - primary.visibleFrame.midY,
                           width: 1, height: 20)
        controller.update([.date], anchor: TypingAnchor(rect: caret, source: .caret))
        RunLoop.main.run(until: Date.now.addingTimeInterval(0.2))
        guard let panel = application.windows.first(where: { $0 is NSPanel }) else { fatalError("Missing suggestion panel") }
        let originalFrame = panel.frame
        precondition(controller.hasResults)
        precondition(controller.selectedItem?.id == "date")

        // An editor temporarily failing to provide caret geometry keeps the
        // existing popup anchored to text through every subsequent query.
        for _ in 0..<20 {
            controller.update([.date], anchor: nil)
            precondition(panel.frame == originalFrame)
        }
        controller.update([], anchor: nil)
        precondition(!controller.hasResults)
        controller.update([.date], anchor: nil)
        RunLoop.main.run(until: Date.now.addingTimeInterval(0.2))
        precondition(panel.frame == originalFrame)

        controller.hide()
        let window = CGRect(x: caret.minX - 50, y: caret.minY - 100, width: 600, height: 400)
        let fallback = SuggestionPanelPositioner.fallbackAnchor(in: window, click: nil)
        controller.update([.date], anchor: fallback)
        RunLoop.main.run(until: Date.now.addingTimeInterval(0.2))
        precondition(controller.hasResults)
        precondition(controller.selectedItem?.id == "date")
        let fallbackFrame = panel.frame
        for _ in 0..<20 {
            controller.update([.date], anchor: fallback)
            precondition(panel.frame == fallbackFrame)
        }
        controller.update([.date], anchor: TypingAnchor(rect: caret, source: .caret))
        controller.update([.date], anchor: fallback)
        precondition(panel.frame == originalFrame)

        controller.hide()
        controller.update([.date], anchor: nil)
        precondition(!controller.hasResults)
        precondition(!panel.isVisible)

        // Large multiline editor bounds must not act like a giant caret and
        // clamp the picker into the lower-left corner.
        let editor = CGRect(x: caret.minX - 50, y: caret.minY - 100, width: 400, height: 300)
        let field = SuggestionPanelPositioner.fieldAnchor(in: editor, click: nil)
        controller.update([.date], anchor: field)
        RunLoop.main.run(until: Date.now.addingTimeInterval(0.2))
        precondition(panel.isVisible)
        let expectedCaret = CGRect(x: field.rect.minX, y: primary.frame.maxY - field.rect.maxY,
                                   width: field.rect.width, height: field.rect.height)
        let expectedFrame = SuggestionPanelPositioner.frame(for: expectedCaret,
                                                           size: panel.frame.size, in: primary.visibleFrame)
        precondition(panel.frame == expectedFrame)
        let typed = TypingAnchor(rect: caret, source: .caret)
        controller.update([.date], anchor: typed)
        controller.update([.date], anchor: field)
        precondition(panel.frame == originalFrame)
        controller.hide()
        print("Text anchor stability checks passed")
    }
}

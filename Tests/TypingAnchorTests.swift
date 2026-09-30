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
        controller.update([.date], anchor: nil)
        precondition(!controller.hasResults)
        precondition(controller.selectedItem == nil)
        precondition(!panel.isVisible)
        print("Text anchor stability checks passed")
    }
}

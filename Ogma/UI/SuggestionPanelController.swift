import AppKit
import SwiftUI

final class SuggestionPanelController {
    private let model = SuggestionPickerModel()
    private let panel: NSPanel

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 50),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: SuggestionPickerView(model: model))
    }

    var selectedItem: SuggestionItem? {
        guard model.results.indices.contains(model.selection) else { return nil }
        return model.results[model.selection]
    }

    var hasResults: Bool { !model.results.isEmpty }

    func update(_ results: [SuggestionItem], caretRect: CGRect?) {
        model.results = results
        model.selection = 0
        guard !results.isEmpty else { hide(); return }
        let height = results.reduce(CGFloat(12)) { $0 + $1.rowHeight }
        let caret = appKitCaretRect(caretRect)
        let anchor = caret.map { CGPoint(x: $0.midX, y: $0.midY) } ?? NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) })
            ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        let target = caret ?? CGRect(x: anchor.x, y: anchor.y, width: 1, height: 1)
        let frame = SuggestionPanelPositioner.frame(
            for: target,
            size: CGSize(width: 300, height: height),
            in: screen.visibleFrame
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func moveSelection(_ delta: Int) {
        guard !model.results.isEmpty else { return }
        model.selection = (model.selection + delta + model.results.count) % model.results.count
    }

    func hide() { panel.orderOut(nil) }

    private func appKitCaretRect(_ rect: CGRect?) -> CGRect? {
        guard let rect, !rect.isNull, !rect.isInfinite, rect.height > 0,
              let primary = NSScreen.screens.first else { return nil }
        // Accessibility coordinates use a top-left origin; AppKit uses bottom-left.
        return CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY,
                      width: rect.width, height: rect.height)
    }
}

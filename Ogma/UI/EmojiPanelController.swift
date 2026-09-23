import AppKit
import SwiftUI

final class EmojiPanelController {
    private let model = EmojiPickerModel()
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
        panel.contentView = NSHostingView(rootView: EmojiPickerView(model: model))
    }

    var selectedItem: EmojiItem? {
        guard model.results.indices.contains(model.selection) else { return nil }
        return model.results[model.selection]
    }

    var hasResults: Bool { !model.results.isEmpty }

    func update(_ results: [EmojiItem], caretRect: CGRect?) {
        model.results = results
        model.selection = 0
        guard !results.isEmpty else { hide(); return }
        let height = CGFloat(results.count * 34 + 12)
        let anchor = pointForCaret(caretRect) ?? NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) })
            ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        let visible = screen.visibleFrame
        let x = min(max(anchor.x, visible.minX), visible.maxX - 300)
        let below = anchor.y - height - 8
        let y = below >= visible.minY ? below : min(anchor.y + 18, visible.maxY - height)
        panel.setFrame(NSRect(x: x, y: y, width: 300, height: height), display: true)
        panel.orderFrontRegardless()
    }

    func moveSelection(_ delta: Int) {
        guard !model.results.isEmpty else { return }
        model.selection = (model.selection + delta + model.results.count) % model.results.count
    }

    func hide() { panel.orderOut(nil) }

    private func pointForCaret(_ rect: CGRect?) -> CGPoint? {
        guard let rect, !rect.isNull, !rect.isInfinite, rect.height > 0,
              let primary = NSScreen.screens.first else { return nil }
        // Accessibility coordinates use a top-left origin; AppKit uses bottom-left.
        return CGPoint(x: rect.minX, y: primary.frame.maxY - rect.maxY)
    }
}

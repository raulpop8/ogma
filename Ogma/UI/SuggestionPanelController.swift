import AppKit
import SwiftUI

final class SuggestionPanelController {
    private let model = SuggestionPickerModel()
    private let panel: NSPanel
    var onSelect: ((SuggestionItem) -> Void)?

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
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: SuggestionPickerView(model: model))
        model.onSelect = { [weak self] item in self?.onSelect?(item) }
    }

    var selectedItem: SuggestionItem? {
        guard model.results.indices.contains(model.selection) else { return nil }
        return model.results[model.selection]
    }

    var hasResults: Bool { !model.results.isEmpty }

    func update(_ results: [SuggestionItem], caretRect: CGRect?) {
        model.results = results
        model.selection = 0
        model.revision += 1
        guard !results.isEmpty else { hide(); return }
        let layout = EmojiPickerLayout(rawValue: UserDefaults.standard.string(forKey: "emojiPickerLayout") ?? "grid") ?? .grid
        let showsEmoji: Bool
        if case .emoji = results[0] { showsEmoji = true } else { showsEmoji = false }
        let height: CGFloat
        if showsEmoji && layout == .grid {
            height = CGFloat(min(5, (results.count + 4) / 5) * 48 + 36)
        } else {
            height = results.prefix(5).reduce(CGFloat(12)) { $0 + $1.rowHeight }
        }
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

    func moveSelection(_ delta: Int, horizontal: Bool = false) {
        guard !model.results.isEmpty else { return }
        let layout = EmojiPickerLayout(rawValue: UserDefaults.standard.string(forKey: "emojiPickerLayout") ?? "grid") ?? .grid
        let step = model.showsEmoji && layout == .grid && !horizontal ? delta * 5 : delta
        model.selection = (model.selection + step + model.results.count) % model.results.count
    }

    func hide() { panel.orderOut(nil) }

    func containsPointerEvent(_ event: CGEvent) -> Bool {
        guard panel.isVisible, let primary = NSScreen.screens.first else { return false }
        let point = CGPoint(x: event.location.x, y: primary.frame.maxY - event.location.y)
        return panel.frame.contains(point)
    }

    private func appKitCaretRect(_ rect: CGRect?) -> CGRect? {
        guard let rect, !rect.isNull, !rect.isInfinite, rect.height > 0,
              let primary = NSScreen.screens.first else { return nil }
        // Accessibility coordinates use a top-left origin; AppKit uses bottom-left.
        return CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY,
                      width: rect.width, height: rect.height)
    }
}

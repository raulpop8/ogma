import AppKit
import SwiftUI

final class SuggestionPanelController {
    private let model = SuggestionPickerModel()
    private let panel: NSPanel
    private var anchorTracker = SuggestionAnchorTracker()
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
        panel.isVisible ? model.selectedItem : nil
    }

    var hasResults: Bool { panel.isVisible && !model.results.isEmpty }

    func update(_ results: [SuggestionItem], anchor: TypingAnchor?) {
        anchorTracker.update(anchor)
        model.results = results
        model.selection = 0
        model.revision += 1
        guard !results.isEmpty else { hide(preserveAnchor: true); return }
        let layout = EmojiPickerLayout(rawValue: UserDefaults.standard.string(forKey: "emojiPickerLayout") ?? "grid") ?? .grid
        let showsEmoji: Bool
        if case .emoji = results[0] { showsEmoji = true } else { showsEmoji = false }
        let height: CGFloat
        if showsEmoji && layout == .grid {
            height = CGFloat(min(5, (results.count + 4) / 5) * 48 + 36)
        } else {
            height = results.prefix(5).reduce(CGFloat(12)) { $0 + $1.rowHeight }
        }
        guard let textAnchor = anchorTracker.anchor,
              let target = appKitCaretRect(textAnchor.rect),
              let screen = NSScreen.screens.first(where: {
                  $0.frame.contains(CGPoint(x: target.midX, y: target.midY))
              }) else { hide(preserveAnchor: true); return }
        let frame = SuggestionPanelPositioner.frame(
            for: target,
            size: CGSize(width: 300, height: height),
            in: screen.visibleFrame,
            characterWidth: textAnchor.characterWidth
        )
        if panel.isVisible {
            panel.setFrame(frame, display: true)
        } else if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.setFrame(frame, display: true)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        } else {
            let startFrame = frame.insetBy(dx: frame.width * 0.01, dy: frame.height * 0.01)
                .offsetBy(dx: 0, dy: -6)
            panel.setFrame(startFrame, display: true)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(frame, display: true)
                panel.animator().alphaValue = 1
            }
        }
    }

    func moveSelection(_ delta: Int, horizontal: Bool = false) {
        guard !model.results.isEmpty else { return }
        let layout = EmojiPickerLayout(rawValue: UserDefaults.standard.string(forKey: "emojiPickerLayout") ?? "grid") ?? .grid
        let count = model.results.count
        if model.showsEmoji && layout == .grid && !horizontal {
            let columns = 5
            let rows = (count + columns - 1) / columns
            let row = model.selection / columns
            let column = model.selection % columns
            let nextRow = (row + delta + rows) % rows
            model.selection = min(nextRow * columns + column, count - 1)
        } else {
            model.selection = (model.selection + delta + count) % count
        }
    }

    func hide(preserveAnchor: Bool = false) {
        panel.orderOut(nil)
        if !preserveAnchor { anchorTracker.reset() }
    }

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

import AppKit
import SwiftUI

@main
struct SuggestionPickerTests {
    static func main() throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.prohibited)
        let items = try JSONDecoder().decode([EmojiItem].self,
            from: Data(contentsOf: URL(fileURLWithPath: "Ogma/Resources/emoji.json")))
        let model = SuggestionPickerModel()
        let quickPicks = items.suffix(5).enumerated().map { index, item in
            EmojiQuickPick(item: item, kind: index < 2 ? .recent : .frequent, isPersonalized: true)
        }
        model.updateResults(items.map(SuggestionItem.emoji), quickPicks: quickPicks)
        assert(model.results.count == items.count)
        assert(Set(model.results.map(\.id)).count == items.count)
        assert(model.results.prefix(5).map(\.replacement) == quickPicks.map { $0.item.emoji })
        assert(model.quickPick(for: model.results[0])?.kind == .recent)
        assert(model.quickPick(for: model.results[4])?.kind == .frequent)
        model.hover(model.results[4])
        assert(model.selectedItem?.replacement == quickPicks[4].item.emoji)
        model.updateResults(Array(items.prefix(10)).map(SuggestionItem.emoji))
        assert(model.quickPicks.isEmpty && model.results.count == 10)
        assert(model.results.allSatisfy { model.quickPick(for: $0) == nil })
        model.results = Array(items.prefix(40)).map(SuggestionItem.emoji)
        var inserted = false
        model.onSelect = { _ in inserted = true }
        let hovered = model.results[12]
        model.hover(hovered)
        assert(model.selectedItem?.id == hovered.id)
        assert(model.selectionScrollRevision == 0)
        assert(!inserted)
        model.hover(.date)
        assert(model.selectedItem?.id == hovered.id)
        let host = NSHostingView(rootView: SuggestionPickerView(model: model))
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 276),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = host
        panel.orderFrontRegardless()
        defer { panel.orderOut(nil) }

        model.updateResults(Array(items.prefix(40)).map(SuggestionItem.emoji), quickPicks: quickPicks)
        host.layoutSubtreeIfNeeded()
        model.hover(model.results[4])
        host.layoutSubtreeIfNeeded()
        model.updateResults(Array(items.prefix(40)).map(SuggestionItem.emoji))

        let shortcut = SuggestionItem.snippet(TextSnippet(id: UUID(), trigger: "email",
            replacement: "hello@example.com", isEnabled: true))
        for layout in ["list", "grid"] {
            UserDefaults.standard.setVolatileDomain(["emojiPickerLayout": layout], forName: UserDefaults.argumentDomain)
            for _ in 0..<30 {
                for results in [items.map(SuggestionItem.emoji), [shortcut], [.date], [],
                                Array(items.prefix(40)).map(SuggestionItem.emoji)] {
                    model.results = results
                    model.selection = max(0, results.count - 1)
                    model.selectionScrollRevision += 1
                    host.layoutSubtreeIfNeeded()
                    model.selection = 0
                    model.revision += 1
                    panel.setContentSize(NSSize(width: 300, height: results.isEmpty ? 50 : 276))
                    RunLoop.main.run(until: Date.now.addingTimeInterval(0.005))
                    host.layoutSubtreeIfNeeded()
                }
            }
        }
        print("Suggestion picker transition checks passed")
    }
}

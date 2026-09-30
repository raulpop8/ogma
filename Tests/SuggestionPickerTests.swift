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
        let host = NSHostingView(rootView: SuggestionPickerView(model: model))
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 276),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = host
        panel.orderFrontRegardless()
        defer { panel.orderOut(nil) }

        let shortcut = SuggestionItem.snippet(TextSnippet(id: UUID(), trigger: "email",
            replacement: "hello@example.com", isEnabled: true))
        for layout in ["list", "grid"] {
            UserDefaults.standard.setVolatileDomain(["emojiPickerLayout": layout], forName: UserDefaults.argumentDomain)
            for _ in 0..<30 {
                for results in [items.map(SuggestionItem.emoji), [shortcut], [.date], [],
                                Array(items.prefix(40)).map(SuggestionItem.emoji)] {
                    model.results = results
                    model.selection = max(0, results.count - 1)
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

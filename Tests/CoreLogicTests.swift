import Foundation

@main
struct CoreLogicTests {
    static func main() throws {
        let engine = TriggerEngine()
        assert(engine.handle(.character(":")) == .updated(""))
        assert(engine.handle(.character("s")) == .updated("s"))
        assert(engine.handle(.character("m")) == .updated("sm"))
        assert(engine.typedLength == 3)
        assert(engine.handle(.backspace) == .updated("s"))
        assert(engine.handle(.escape) == .cancelled(consume: true))
        assert(!engine.isActive)
        assert(engine.handle(.character(":")) == .updated(""))
        assert(engine.handle(.backspace) == .cancelled(consume: false))
        assert(engine.handle(.character(":")) == .updated(""))
        assert(engine.handle(.character("/")) == .cancelled(consume: false))

        let data = try Data(contentsOf: URL(fileURLWithPath: "Ogma/Resources/emoji.json"))
        let items = try JSONDecoder().decode([EmojiItem].self, from: data)
        let search = EmojiSearchService(items: items)
        assert(items.count >= 100)
        assert(search.search("smile").first?.emoji == "😊")
        assert(search.search("coffee").first?.emoji == "☕")
        assert(search.search("cofee").first?.emoji == "☕")
        assert(search.search("dog").first?.emoji == "🐶")
        assert(search.search("party").count <= 8)
        assert(search.search("").isEmpty)
        print("Core logic tests passed")
    }
}

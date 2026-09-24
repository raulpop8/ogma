import CoreGraphics

@main
struct PanelPositionerTests {
    static func main() {
        let size = CGSize(width: 300, height: 120)
        let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)

        let writingCaret = CGRect(x: 300, y: 400, width: 1, height: 20)
        let clearOfText = SuggestionPanelPositioner.frame(for: writingCaret, size: size, in: screen)
        precondition(clearOfText.minX == 613)
        precondition(clearOfText.maxY == writingCaret.maxY)
        precondition(!clearOfText.intersects(writingCaret))

        let rightCaret = CGRect(x: 1150, y: 400, width: 1, height: 20)
        let leftPlacement = SuggestionPanelPositioner.frame(for: rightCaret, size: size, in: screen)
        precondition(leftPlacement.maxX < rightCaret.minX)

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

        print("Panel placement checks passed")
    }
}

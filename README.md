# Ogma

Ogma is a native macOS menu-bar utility for inserting emoji while typing. The product brief is in `Resources/Product Specification.md`, and the visual reference is `Resources/moodboard.png`.

## Build and run

Open `Ogma.xcodeproj` in Xcode and run the `Ogma` scheme. The project targets macOS 14 or newer and uses only Apple frameworks. It is a menu-bar app and does not show a Dock icon. The temporary menu-bar symbol is `text.cursor`.

Ogma needs Accessibility to observe the `:` trigger, avoid secure fields, position the popup, and insert emoji. Grant it in System Settings, then choose **Settings… → Check Permissions Again**. The **Keyboard listener** row should show **Ready**. In a standard text field, type `:smile`, use arrow keys to choose, and press Return. Escape cancels.

If the menu-bar item is missing after a code change, stop the running app in Xcode and run it again. A successful startup writes `Ogma menu bar ready` to Xcode's debug console. The item uses a text-cursor symbol, or an `O` if that symbol is unavailable.

The project uses automatic Apple Development signing. macOS may ask for Accessibility permission once after switching from an earlier ad-hoc build, but the development identity remains stable across normal rebuilds. Developers using a different Apple account should select their own Team in Xcode's Signing & Capabilities pane.

## Implementation plan

1. **Foundation — implemented:** Native Xcode app, menu-bar controls, Accessibility permission UI, bundled emoji data, trigger state, and ranked search.
2. **Emoji flow — verified on the development Mac:** Non-activating popup, keyboard selection, caret position with pointer fallback, and replacement through synthetic backspaces and Unicode keyboard events. This strategy leaves the clipboard untouched.
3. **Broader device verification — pending:** Check focus retention, deletion, Escape, secure fields, and multiple displays. Verify Safari, Chrome, Messages, Mail, and other apps.
4. **Compatibility fixes — pending:** Adjust insertion or caret positioning for any target apps that reject synthetic events or expose incomplete Accessibility geometry. Keep those changes inside their services.
5. **Next milestone — deferred:** User-defined `/` text snippets and local persistence after the emoji flow is reliable.

The bundled emoji list has 109 common entries. It can be expanded without changing the search code. Ogma stores no typing history, makes no network requests, and does not use the clipboard.

## Core logic check

Run from the repository root:

```sh
swiftc Ogma/Models/EmojiItem.swift Ogma/Services/EmojiSearchService.swift Ogma/Services/TriggerEngine.swift Tests/CoreLogicTests.swift -o /private/tmp/ogma-core-tests
/private/tmp/ogma-core-tests
```

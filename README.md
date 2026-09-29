# Ogma

Ogma is a native macOS menu-bar utility for inserting emoji and saved text shortcuts while typing. The product brief is in `Resources/Product Specification.md`, and the visual reference is `Resources/moodboard.png`.

## Install

Download the [latest Ogma DMG](https://github.com/raulpop8/ogma/releases/latest), open it, and drag **Ogma** into **Applications**. Launch it from Applications; its icon appears in the menu bar. Grant Accessibility permission when macOS asks. The installed release offers **Check for Updates…** from the Ogma menu and can notify you about later releases.

## Build and run

Open `Ogma.xcodeproj` in Xcode and run the `Ogma` scheme. The project targets macOS 14 or newer and uses Sparkle 2 for updates. It is a menu-bar app and does not show a Dock icon. The temporary menu-bar symbol is `text.cursor`.

Ogma needs Accessibility to observe shortcuts, avoid secure fields, position the popup, and insert text. Grant it in System Settings, then choose **Settings… → Check Permissions Again**. The **Keyboard listener** row should show **Ready**. In a standard text field, type `:smile`, use arrow keys to choose, and press Return. Escape cancels.

To make a text shortcut, open **Settings… → Shortcuts**, click **Add Shortcut**, enter a trigger such as `email` and the replacement text, then save. Type `/email` in another app and press Return to replace it. Shortcuts can contain multiple lines, and each shortcut can be edited, disabled, or deleted. They are saved locally in Application Support. When no shortcuts are enabled, typing `/` behaves normally.

If the menu-bar item is missing after a code change, stop the running app in Xcode and run it again. A successful startup writes `Ogma menu bar ready` to Xcode's debug console. The item uses a text-cursor symbol, or an `O` if that symbol is unavailable.

The project uses automatic Apple Development signing while running from Xcode. macOS may ask for Accessibility permission once after switching from an earlier ad-hoc build, but the development identity remains stable across normal rebuilds. Developers using a different Apple account should select their own Team in Xcode's Signing & Capabilities pane. See [RELEASING.md](RELEASING.md) for Developer ID signing, notarization, DMG packaging, GitHub publication, and Sparkle update testing.

## Implementation plan

1. **Foundation — implemented:** Native Xcode app, menu-bar controls, Accessibility permission UI, bundled emoji data, trigger state, and ranked search.
2. **Emoji flow — verified on the development Mac:** Non-activating popup, keyboard selection, caret position with pointer fallback, and replacement through synthetic backspaces and Unicode keyboard events. This strategy leaves the clipboard untouched.
3. **Text shortcuts — implemented in code:** Slash suggestions, create/edit/delete/disable controls, and local JSON persistence. Device testing is next, especially multiline insertion.
4. **Broader device verification — pending:** Check focus retention, deletion, Escape, secure fields, and multiple displays. Verify Safari, Chrome, Messages, Mail, and other apps.
5. **Compatibility fixes — pending:** Adjust insertion or caret positioning for any target apps that reject synthetic events or expose incomplete Accessibility geometry. Keep those changes inside their services.

The bundled emoji list has 109 common entries. It can be expanded without changing the search code. Ogma stores no typing history and does not use the clipboard. Sparkle contacts the configured update feed when automatic checks are enabled or the user checks manually.

## Core logic check

Run from the repository root:

```sh
swiftc Ogma/Models/EmojiItem.swift Ogma/Models/TextSnippet.swift Ogma/Services/EmojiSearchService.swift Ogma/Services/SnippetSearchService.swift Ogma/Services/SnippetStore.swift Ogma/Services/TriggerEngine.swift Tests/CoreLogicTests.swift -o /private/tmp/ogma-core-tests
/private/tmp/ogma-core-tests
swiftc Ogma/UI/SuggestionPanelPositioner.swift Tests/PanelPositionerTests.swift -o /private/tmp/ogma-panel-tests
/private/tmp/ogma-panel-tests
```

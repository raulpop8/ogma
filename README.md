# Ogma

Ogma is a macOS menu bar app for inserting emoji and saved text shortcuts while typing. It requires macOS 14 or later.

## Install

Download the [latest signed DMG](https://github.com/raulpop8/ogma/releases/latest), drag Ogma into Applications, and launch it. Grant Accessibility access in System Settings, then open **Ogma → Settings** and check that **Keyboard listener** says **Ready**. Ogma lives in the menu bar, not the Dock.

## Use

- Type `:` to browse emoji, or `:joy` to search. Scroll, use arrow keys, or click a result; Return inserts it and Escape closes the picker. Choose a five-column grid or named list in **Settings → Emoji picker**.
- Create a text shortcut in **Settings → Shortcuts**. For a shortcut named `email`, type `/email` in another app to insert its saved text.
- Type `/date` and press Return to insert today's date. Choose its display format in **Settings → General → Date shortcut**.
- The picker stays aligned with the cursor, just below or above the active line. Inserting an emoji or shortcut adds a trailing space unless the text already ends with whitespace.
- Choose **Check for Updates…** from the Ogma menu to install a new release.
- Settings shows the installed version and build number. If Ogma crashes, the next launch offers to review the macOS crash report. You can also use **Settings → General → Crash reports** to save or share the latest log as an attachment; Ogma does not upload reports automatically.

Ogma stores shortcuts locally in Application Support. It does not store typing history or use the clipboard. The bundled emoji catalog comes from [Unicode Emoji 17.0](https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt); its [license](Ogma/Resources/UNICODE_LICENSE.txt) is included with the app.

## Develop

Open [Ogma.xcodeproj](Ogma.xcodeproj) in Xcode and run the Ogma scheme. Choose your Apple development team under Signing & Capabilities if Xcode asks. See [RELEASING.md](RELEASING.md) for signing, notarization, and update-feed steps.

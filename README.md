# Ogma

Ogma is a macOS menu bar app for inserting emoji and saved text shortcuts while typing. It requires macOS 14 or later.

## Install

Download the [latest signed DMG](https://github.com/raulpop8/ogma/releases/latest), drag Ogma into Applications, and launch it. Grant Accessibility access in System Settings, then open **Ogma → Settings** and check that **Keyboard listener** says **Ready**. Ogma lives in the menu bar, not the Dock.

## Use

- Type `:` to browse emoji, or `:joy` to search. Scroll, use arrow keys, or click a result; Return inserts it and Escape closes the picker. Choose a five-column grid or named list in **Settings → Emoji picker**.
- Create a text shortcut in **Settings → Shortcuts**. For a shortcut named `email`, type `/email` in another app to insert its saved text.
- Choose **Check for Updates…** from the Ogma menu to install a new release.

Ogma stores shortcuts locally in Application Support. It does not store typing history or use the clipboard. The bundled emoji catalog comes from [Unicode Emoji 17.0](https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt); its [license](Ogma/Resources/UNICODE_LICENSE.txt) is included with the app.

## Develop

Open [Ogma.xcodeproj](Ogma.xcodeproj) in Xcode and run the Ogma scheme. Choose your Apple development team under Signing & Capabilities if Xcode asks. See [RELEASING.md](RELEASING.md) for signing, notarization, and update-feed steps.

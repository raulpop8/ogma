# Ogma

Ogma is a macOS menu bar app for inserting emoji and saved text shortcuts while typing. It requires macOS 14 or later.

## Install

Download the [latest signed DMG](https://github.com/raulpop8/ogma/releases/latest), drag Ogma into Applications, and launch it. Grant Accessibility access in System Settings, then open **Ogma → Settings** and check that **Keyboard listener** says **Ready**. Ogma lives in the menu bar, not the Dock.

## Use

- Type `:` to browse emoji, or `:joy` to search (`:hug` finds 🤗). Scroll or use arrow keys, or hover over an emoji to highlight it and see its name. Click a result or press Return to insert it; Escape closes the picker. Choose a five-column grid or named list in **Settings → Emoji picker**.
- With just `:`, the first five choices are your two most recently used emoji (soft yellow) and three most-used other emoji (soft blue). Common suggestions fill unused slots until you build up history. Each emoji appears once; typing a search switches to regular results.
- Create a text shortcut in **Settings → Shortcuts**. For a shortcut named `email`, type `/email` in another app to insert its saved text.
- Type `/date` and press Return to insert today's date. Choose its display format in **Settings → General → Date shortcut**.
- The picker stays beside the typing text with about two or three character widths of space. It validates the insertion point against the editor and window, retaining the last text position through temporary lookup failures. If the app exposes no caret, it uses a recent click or the center of the focused field/window while retrying. It never follows the mouse pointer. Inserting an emoji or shortcut adds a trailing space unless the text already ends with whitespace.
- Choose **Check for Updates…** from the Ogma menu to install a new release.
- Settings shows the installed version and build number. If Ogma crashes, the next launch offers to review the macOS crash report. You can also use **Settings → General → Crash reports** to save or share the latest log as an attachment; Ogma does not upload reports automatically.

Ogma stores shortcuts locally in Application Support. Emoji usage counts and recency are saved locally when you insert an emoji through Ogma. It does not store typing history or use the clipboard. The bundled emoji catalog comes from [Unicode Emoji 17.0](https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt), with English search keywords from [Unicode CLDR 48](https://github.com/unicode-org/cldr/tree/release-48/common/annotations). Search works offline, including related emotions such as `:sad`, short names, and misspellings. Its [license](Ogma/Resources/UNICODE_LICENSE.txt) is included with the app.

## Develop

Open [Ogma.xcodeproj](Ogma.xcodeproj) in Xcode and run the Ogma scheme. Choose your Apple development team under Signing & Capabilities if Xcode asks. See [RELEASING.md](RELEASING.md) for signing, notarization, and update-feed steps.

To refresh search keywords, download `common/annotations/en.xml` and `common/annotationsDerived/en.xml` from the pinned CLDR `release-48` branch, then run `python3 scripts/update-emoji-keywords.py /path/to/en.xml /path/to/derived/en.xml`.

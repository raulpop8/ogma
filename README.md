# Ogma

Emoji and saved text, right where you type. Ogma is a native desktop app for **macOS and Windows**: type `:` to find emoji, `/` for a saved text shortcut, or `/date` for today's date.

[Website](https://ogma.raulpop.ro/) · [Download for macOS](https://github.com/raulpop8/ogma/releases/latest) · [Get Ogma Typing for Windows](https://apps.microsoft.com/detail/9N271VJTZDCH)

## Install

| Platform | Download | Requirements | Updates |
| --- | --- | --- | --- |
| macOS | [Signed, notarized DMG](https://github.com/raulpop8/ogma/releases/latest) | macOS 14 or later; Accessibility permission | In-app updates through Sparkle |
| Windows | [Ogma Typing on Microsoft Store](https://apps.microsoft.com/detail/9N271VJTZDCH) | Windows 11; x64 or ARM64 | Microsoft Store |

### macOS

1. Download the DMG and drag Ogma into Applications.
2. Launch Ogma and allow it in **System Settings → Privacy & Security → Accessibility**.
3. Open **Ogma → Settings** from the menu bar. Check that **Keyboard listener** says **Ready**. If needed, choose **Check Again**.

Ogma lives in the menu bar. Closing Settings keeps it running.

### Windows

1. Install **Ogma Typing**, published by **Raul Pop**, from Microsoft Store.
2. Launch it from Start. Open Settings by double-clicking the Ogma icon in the notification area; it may be behind the hidden-icons arrow.
3. Keep Ogma enabled and try a shortcut in an ordinary, non-administrator text editor.

The Store name **Ogma Typing** identifies the Windows edition of Ogma. Closing Settings keeps it running. Use the Store installation for Windows. Unsigned development builds and MSIX submission files in build artifacts are not public installers.

## Use Ogma

| Type | What happens |
| --- | --- |
| `:` | Browse emoji, with recent and frequently used choices first |
| `:joy` | Search for an emoji by name or keyword |
| `/email` | Find a saved shortcut named `email` |
| `/date` | Insert today's date in your chosen format |

Use the arrow keys to choose a suggestion and **Return/Enter** to insert it, or click the result. **Escape** closes the picker.

Create and edit saved text in **Settings → Shortcuts**. Choose an emoji grid or named list in Settings, and a short, long, or ISO (`YYYY-MM-DD`) date format under General. Search works offline and supports related words and common misspellings.

The picker stays near the insertion point when the editor exposes one. Placement and text insertion depend on the editor's accessibility support. The Mac and Windows editions use native interfaces; their settings and platform integrations are not yet identical.

## Updates and compatibility

- **Mac:** choose **Check for Updates…** from the Ogma menu. Sparkle installs signed updates hosted on GitHub Releases. macOS crash-report review and export are available in Settings; reports are not uploaded automatically.
- **Windows:** Microsoft Store delivers published updates according to the PC's update settings. You can also check for updates in the Store. The current **View releases** command opens the project's GitHub release history; it does not update the Windows app.

A GitHub push does **not** publish an app update. Mac releases need a signed, notarized download and a signed update-feed entry. Windows releases need higher-versioned packages submitted to Microsoft Store, certified, and published. The platforms currently have independent version numbers; see [release instructions](RELEASING.md).

Compatibility varies between editors. Password fields are excluded when identified. Windows cannot insert into applications running as administrator. Custom editors, terminals, games, remote desktops, or unavailable accessibility providers may limit insertion. If a replacement is incomplete, check the text before retrying.

## Privacy

Emoji search runs locally using a bundled catalog. Saved shortcuts, preferences, and emoji usage stay on your device. Each installation keeps its own data; Ogma does not sync it between platforms.

Ogma does not save typing history, read document contents, use the clipboard for insertion, or upload your text. It keeps a bounded active shortcut query in memory while you type. The Windows app uses accessibility information and, where supported, selection positions to target insertion. [Windows privacy policy](https://github.com/raulpop8/ogma/blob/codex/windows-store/Windows/Store/PRIVACY.md).

## Build and contribute

Ogma has two native implementations sharing the bundled emoji catalog:

- **macOS:** Swift, SwiftUI and AppKit. Open [Ogma.xcodeproj](Ogma.xcodeproj) in Xcode, choose your development team if asked, and run the Ogma scheme.
- **Windows:** C#/.NET 10 and Windows Forms, with Win32 input handling and UI Automation. Windows code currently lives on the [`codex/windows-store` branch](https://github.com/raulpop8/ogma/tree/codex/windows-store/Windows). On Windows with the .NET 10 SDK, run `dotnet run --project Windows/Ogma.Windows`. See the [Windows developer guide](https://github.com/raulpop8/ogma/blob/codex/windows-store/Windows/README.md) for tests and packaging.

Report bugs through [GitHub Issues](https://github.com/raulpop8/ogma/issues). Include your operating system, Ogma version, affected app, and steps to reproduce with sample text. Keep passwords and private shortcut contents out of reports.

The website is maintained in this repository too: see [WEBSITE.md](WEBSITE.md) for its source, hosting, and publishing steps.

## Emoji data

The bundled catalog uses [Unicode Emoji 17.0](https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt) and English keywords from [Unicode CLDR 48](https://github.com/unicode-org/cldr/tree/release-48/common/annotations). The [Unicode license](Ogma/Resources/UNICODE_LICENSE.txt) is included with the app.

To refresh search keywords, download `common/annotations/en.xml` and `common/annotationsDerived/en.xml` from CLDR's pinned `release-48` branch, then run:

```sh
python3 scripts/update-emoji-keywords.py /path/to/en.xml /path/to/derived/en.xml
```

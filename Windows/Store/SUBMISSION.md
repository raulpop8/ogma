# Ogma Typing: first Microsoft Store submission

The reserved product is **Ogma Typing**, published by **Raul Pop**. Its exact Partner Center identity is in [identity.json](identity.json). These are public package identifiers, not signing credentials.

The Windows code is a preview. Passing compilation or package validation does not establish that keyboard insertion works correctly on a Windows desktop. Microsoft Store approval and end-to-end Windows testing are still required.

## Build Store packages

On Windows, install the .NET 10 SDK and Windows SDK MSIX Packaging Tools, then run from the repository root:

```powershell
./Windows/package-store.ps1 -Runtime win-x64
./Windows/package-store.ps1 -Runtime win-arm64
```

The script finds MakeAppx in the Windows SDK or accepts `-MakeAppxPath`. It builds a self-contained folder deployment, inserts the reserved product identity, includes the app's existing logo and Unicode license, and runs MakeAppx with schema/semantic validation enabled. The current update candidate is **1.0.1.0**. Outputs go to `Windows/artifacts/store/`:

- `RaulPop.OgmaTyping_1.0.1.0_x64.msix`
- `RaulPop.OgmaTyping_1.0.1.0_arm64.msix`

The [Windows workflow](../../.github/workflows/windows.yml) also builds both Store packages and uploads them as `OgmaTyping-MicrosoftStore-*` artifacts. The artifacts are ZIP containers: extract each one and upload the **MSIX inside** to Partner Center.

These packages are unsigned Store submissions, not sideload installers. No private certificate is needed for Store submission; Microsoft signs the Store-distributed packages after certification. They do not fix the Smart App Control block until installed through the Store. See [Microsoft's signing FAQ](https://learn.microsoft.com/windows/apps/publish/faq/get-started-with-the-microsoft-store).

The first Store release used **1.0.0.0**; this update uses **1.0.1.0**, with app assembly version 1.0.1. The Store requires a nonzero first component and reserves the fourth component, which must be zero. Increase `-PackageVersion` for later uploads. See [version requirements](https://learn.microsoft.com/windows/apps/publish/publish-your-app/package-version-numbering).

For an update, create a new submission for the existing Ogma Typing product and upload both higher-versioned MSIX files. Keep the identity and publisher unchanged so existing installations can update. GitHub builds do not publish Store updates automatically. Certification and Store publication are separate steps. Test on the affected Windows PC before public rollout where possible; native-control CI tests are not equivalent to testing every editor.

## What's new in 1.0.1

- Emoji in Ogma's picker use Windows' native color-font renderer.
- Picker colors follow Windows light/dark preference and support high contrast.
- Compatible RichEdit controls replace trigger text directly to preserve Unicode and multiline snippets.
- Other editors receive paced typing, with insertion stopped if focus or the active operation changes.

The clipboard is not used. This is a compatibility fix; modern Notepad and the user's other affected editors still require live validation.

## Fill out the first submission

Open **Ogma Typing** in Partner Center and start a submission. Complete its pricing/availability, properties/category, age-rating questionnaire, and English Store listing. Use the exact reserved display name **Ogma Typing**.

Upload both MSIX files under **Packages**. The Windows Store should associate each architecture with its supported PCs. Resolve any ingestion errors before submitting. A developer account approval is separate from app certification.

The package declares `runFullTrust` because this is a native desktop tray app. If Partner Center asks for its purpose, explain the actual keyboard-hook and text-insertion behavior using the reviewer notes below. This is subject to Microsoft's review; approval is not guaranteed.

Use real screenshots from the Windows app, not Mac screenshots. Make the [privacy policy](PRIVACY.md) available at a stable public HTTPS URL and put that URL in the listing's privacy-policy field. Complete every requested field truthfully. Decide availability/visibility before submitting; use a limited test audience if the account offers it while the Windows port is being tested.

## Description draft

Ogma Typing puts emoji and saved text shortcuts beside your cursor while you type.

Type : to browse emoji, or add a name such as :joy to search offline. Save frequently used text as shortcuts and insert it with /email or another name you choose. Type /date for today's date.

Choose an emoji grid or named list, navigate with arrow keys, and insert with Enter or a click. Recent and frequently used emoji appear first when you open the picker.

Ogma runs in the Windows notification area. Double-click its icon to open Settings, manage shortcuts, or pause the keyboard listener. Your saved shortcuts and emoji usage stay on your PC. Ogma does not save typing history, use the clipboard, or upload your text.

This desktop app works with supported text editors. It cannot insert into apps running as administrator, and compatibility with custom editors and input methods varies.

## Reviewer notes / runFullTrust justification draft

Ogma Typing is a Windows desktop notification-area utility. It requires runFullTrust to use Win32 low-level keyboard and pointer hooks, UI Automation to identify the focused field/caret and exclude protected fields, and SendInput to replace a user-selected trigger with emoji or saved text in the active editor. It runs at normal user integrity and does not request administrator access or uiAccess. It does not use an input-injection broker or install a driver/service.

No sign-in, paid subscription, or external service is required. Search uses a bundled offline emoji catalog. The app keeps only a bounded active shortcut query in memory, stores saved snippets/preferences/emoji usage locally, and does not record typing history, access the clipboard, or upload user text.

To test: launch from Start. Settings opens on first launch; later, double-click the notification-area icon (it may be behind the ^ arrow). Keep Ogma enabled. In ordinary, non-administrator Notepad, type :joy, wait for suggestions, and press Enter. Confirm the emoji replaces the trigger. In Settings > Shortcuts, create email with a sample address; in Notepad, type /email and accept the result. Test /date, arrows, Escape, picker grid/list, pause/resume, and Quit Ogma from the tray menu. Insertion into administrator apps and custom editors may be unavailable. No text is sent to a server.

Store MSIX updates are delivered by Microsoft Store. The app's View releases link opens the GitHub release page; the Store package does not run a custom updater or download executable code.

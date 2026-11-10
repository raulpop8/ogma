# Ogma for Windows

A native notification area app targeting Windows 11, on x64 and ARM64. This is a development preview, not a published or signed Windows release. The existing macOS app and release feed are independent.

The reserved Microsoft Store product is **Ogma Typing**, published by **Raul Pop**. See [Store submission steps](Store/SUBMISSION.md) for its MSIX build commands, exact package identity, listing draft, privacy policy, and reviewer notes. Store packages use Microsoft's signing after certification, rather than the certificate-store signing path below.

The next Store update is **1.0.1.0**. It adds native color-font rendering for emoji in the picker, light/dark/high-contrast palettes, direct range replacement in compatible RichEdit controls, and paced Unicode typing elsewhere. The clipboard is not used. Actual rendering inside a destination editor remains that editor's responsibility.

**Smart App Control can hard-block the unsigned preview.** It has no per-app allow exception. A [publicly trusted Windows signature](https://learn.microsoft.com/windows/apps/develop/smart-app-control/code-signing-for-smart-app-control) is the distribution fix; a self-signed certificate or a ZIP rebuild does not provide that trust. See [Microsoft's FAQ](https://support.microsoft.com/en-us/windows/security/threat-malware-protection/smart-app-control-frequently-asked-questions). The current download cannot be made into a trusted release until a signing identity is available.

## Run from source

Install Microsoft's [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) on Windows. In the repository root:

```powershell
dotnet run --project Windows/Ogma.Windows
```

Settings opens on the first launch. Later, double-click the Ogma icon in the notification area, or right-click it and choose **Settings**. It may appear behind the **^** arrow. Close Settings to keep Ogma running; use **Quit Ogma** to exit. Only one copy runs per Windows session. Ogma does not need administrator access or a separate Accessibility permission.

Type `:` for emoji, `:joy` to search, `/` for saved shortcuts, or `/date` for today's date. Use arrow keys, Enter, Escape, a mouse click, or scroll to browse. Settings offers a five-column emoji grid or named list, date formatting, and shortcut creation, editing, disabling, and deletion. Bare `:` begins with two recent and three frequent emoji, filling unused positions with common choices.

The Unicode 17 / CLDR 48 catalog is embedded directly from `Ogma/Resources/emoji.json`. Search uses the same ranking, word boundaries, alias normalization, and typo fallback as the Mac implementation. The Unicode license ships beside the executable. Windows' installed fonts determine which emoji glyphs can be rendered.

## Build a portable app

```powershell
./Windows/publish.ps1 -Runtime win-x64 -AllowUnsigned
./Windows/publish.ps1 -Runtime win-arm64 -AllowUnsigned
```

These commands explicitly create development ZIPs named `Ogma-X.Y.Z-win-ARCH-unsigned-preview.zip` under `Windows/artifacts/`. Smart App Control may prevent them from running. The .NET runtime is included. Use `-Version X.Y.Z` when preparing a release. The [Windows workflow](../.github/workflows/windows.yml) tests the core and builds both architectures as clearly labeled unsigned workflow artifacts; it does not publish a release. Running the packaging script without a certificate or `-AllowUnsigned` stops before building.

For a signed preview, use Windows with the .NET 10 SDK, Windows SDK SignTool on `PATH`, and an accessible, publicly trusted code-signing certificate in the Windows **Personal / My** certificate store:

```powershell
./Windows/publish.ps1 -Runtime win-x64 -CertificateThumbprint 'YOUR_CERTIFICATE_THUMBPRINT'
./Windows/publish.ps1 -Runtime win-arm64 -CertificateThumbprint 'YOUR_CERTIFICATE_THUMBPRINT'
```

The thumbprint identifies the certificate; it is not a password. The script uses the current user's store by default; choose `-CertificateStore LocalMachine` if needed, or `-SignToolPath` if SignTool is not on `PATH`. It signs and timestamps Ogma's executable and both application DLLs with SHA-256, then verifies every EXE/DLL's Authenticode signature before creating a `-signed.zip`. Signed builds use a normal self-contained folder instead of a single-file bundle so every Ogma binary is individually signed. Extract the entire ZIP and keep all files together. Publishing/signing happens in a temporary output folder, leaving the SDK/NuGet caches unchanged. Signing or verification failure prevents a new ZIP from being produced.

This prepares certificate-store signing; no signing identity is configured in this repository, and it has not produced a trusted build yet. Local verification also cannot establish that a manually trusted certificate is publicly trusted: obtain the certificate from a trusted provider and test the package on a separate Windows PC with Smart App Control on. Microsoft's [signing options](https://learn.microsoft.com/windows/apps/package-and-deploy/code-signing-options) include a certificate from a trusted provider, eligible Azure Artifact Signing accounts, and Microsoft Store MSIX distribution. Artifact Signing needs its own service integration and identity validation; it does not use the certificate-store command above. An Apple signing certificate cannot sign a trusted Windows release.

On a Mac or Linux machine with the .NET 10 SDK, compilation can be checked with:

```sh
dotnet build Windows/Ogma.Windows -c Release
```

The app can only run on Windows. Cross-compilation does not verify hooks, caret placement, rendering, or insertion in actual Windows editors.

## Local storage and input

Shortcuts live in `%LOCALAPPDATA%\Ogma\snippets.json`; preferences and emoji counts live in `preferences.json` beside it. Writes use a temporary file and replace the destination only after serialization succeeds. Unreadable or invalid files are left unchanged and reported in Settings. Snippet JSON uses the same property names as macOS, so a copy of a Mac `snippets.json` can be placed here while Ogma is closed. Data does not sync between devices.

Ogma keeps only the active, bounded trigger query in memory. It does not store typing history, read document text, use the clipboard, or upload data. Keyboard events injected by other software are ignored. UI Automation is used to identify protected fields and the caret; those calls run outside keyboard callbacks with a bounded wait. The picker does not activate its window, so the editor retains keyboard focus. The target window and focused element are checked again before insertion.

Windows restricts simulated input into elevated apps. Run Ogma normally and test in ordinary, non-administrator editors. Password fields are excluded when the native control or UI Automation identifies them; unavailable providers suppress suggestions. Compatible RichEdit controls use selection indices and Unicode range replacement; Ogma does not read the document text. Other editors receive paced Unicode key pairs, with focus/cancellation checked between each pair. When a caret is unavailable, the picker uses the focused field or window center, never the pointer. Some games, terminals, IMEs, remote desktops, or custom editors may not accept Unicode input or expose suitable accessibility information. A failed insertion can be partial; Ogma reports it and does not retry into a potentially changed document.

## Update a Store-installed copy

A GitHub push runs the build and produces artifacts; it does not update installed Store apps. Build higher-versioned MSIX files with the same identity, upload x64 and ARM64 packages to a new Partner Center submission, complete certification, and publish it. Microsoft Store then delivers the update according to each PC's update settings. The current update packages use version `1.0.1.0`, above the first release's `1.0.0.0`. Do not try to install unsigned submission packages directly to work around Store signing.

This preview has manual updates through **View releases**. Sparkle updates, macOS crash report handling, start-at-login, and an installer are not implemented for Windows. Smart App Control may hard-block unsigned previews, and it has no per-app allow exception. SmartScreen is a separate reputation check and can still warn for a newly signed publisher. Public distribution needs trusted Authenticode signatures and a verified Windows test pass.

## Verification

Run the core checks on any platform with .NET 10:

```sh
dotnet run --project Windows/Ogma.Core.Tests -c Release
```

These cover trigger transitions, the shared catalog, search parity, saved shortcuts, malformed file protection, date formats, usage ranking, and persistence. Build checks treat warnings as errors.

Run `pwsh -NoProfile -File Windows/Tests/PackagingTests.ps1` to check the packaging script's syntax, explicit unsigned-build requirement, ZIP labeling, documentation, and failure cleanup using a mocked publisher. It does not create or test a signed executable. Real certificate signing and Smart App Control acceptance require separate validation on Windows.

On Windows, also run `dotnet run --project Windows/Ogma.Windows.Tests -c Release`. This checks native structure alignment, Unicode input payloads (without sending them), embedded resources, and the picker's non-activating window style. CI runs this on its x64 Windows host for both packaging jobs; ARM64 packaging is cross-compiled and still needs native ARM64 testing.

The isolated Windows CI desktop also runs `--desktop-tests Windows/artifacts/picker-tests` through `Ogma.Windows.Tests`. It checks actual colored pixels in the DirectWrite-rendered picker, contrast in both themes, and actual Unicode insertion into its own native TextBox/RichTextBox windows, including Romanian dates, diacritics, emoji/ZWJ sequences, CJK, multiline text, preservation of surrounding text, and cancellation. It saves light/dark grid/list images. These tests do not establish compatibility with the modern Notepad release or other applications on a user's PC; those still need live testing.

Before distributing a Windows build, test the following on **both Windows 11 x64 and ARM64**. These checks require a real Windows session and have not been performed by compiling on a Mac:

- Extract the portable ZIP on a PC without .NET installed; launch, open Settings from the tray, pause/resume, quit, and launch a second copy.
- In Notepad, a browser text field, Office, VS Code, and Windows Terminal: search `:joy`, `:hug`, `:sad`, `:cofee`, `:+1`, and `:-1`; insert by Enter and by click. Check joined emoji, skin tones, flags, and recent/frequent ordering after relaunch.
- Create, edit, disable, and delete `/email`; insert multiline text and non-Latin text. Verify only the trigger is removed and a single trailing space is added unless text already ends in whitespace. Check all `/date` formats against the Windows locale.
- Test grid and list navigation, scrolling, hover labels, Escape, backspacing through a trigger, Ctrl/Alt/Windows shortcuts, held keys, rapid typing followed by Enter, and switching apps or fields while results are showing. No stale results should replace text in a new destination.
- Test password fields, an app running as administrator, and an editor with unavailable accessibility. The picker must not take focus or consume ordinary typing when it has no results.
- Test US and non-US keyboard layouts, dead keys, AltGr, an IME, mixed-DPI monitors, negative screen coordinates, and each screen edge. Document any unsupported editor/layout combinations.
- Check Windows high contrast, display scaling, and Narrator with both picker layouts and the shortcut editor. The custom suggestion surface exposes the selected title, but needs assistive-technology testing before claiming full accessibility.
- Check unreadable/corrupt settings files, an unwritable data folder, and release ZIP contents. Keep original data intact when saving fails.

## Layout

- `Ogma.Core`: platform-independent trigger, search, suggestions, and storage logic, implemented in C# to match macOS behavior.
- `Ogma.Windows`: Windows Forms tray/settings/picker, DirectWrite/Direct2D color-font rendering, Win32 keyboard and pointer hooks, UI Automation focus/caret inspection, RichEdit range replacement, and paced Unicode `SendInput` fallback. WPF framework references provide the managed UI Automation APIs; no third-party packages are used.
- `Ogma.Core.Tests`: a dependency-free executable test harness. Run with `dotnet run`, not `dotnet test`.
- `Ogma.Windows.Tests`: default interop/resource/window checks do not inject input. Optional, CI-only capture and desktop-regression modes exercise the actual app and send input only to their own test editors on an isolated runner.

Platform behavior follows Microsoft's documentation for [keyboard hooks](https://learn.microsoft.com/windows/win32/winmsg/lowlevelkeyboardproc), [keyboard layout translation](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-tounicodeex), [UI Automation text ranges](https://learn.microsoft.com/windows/win32/winauto/uiauto-usingtextrangeobjects), and [Unicode input and privilege restrictions](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendinput).

Ogma for Windows — signed preview

Extract the entire ZIP to a folder, keep all files together, and launch Ogma.exe.
The .NET runtime is included. Ogma.exe, Ogma.dll, and Ogma.Core.dll have been
signed and timestamped with the publisher's code-signing certificate. Release
packaging checks the Authenticode signatures of all included EXE and DLL files.

Ogma runs in the notification area (possibly behind the ^ arrow). Double-click
its icon for Settings. Close Settings to keep Ogma running; use Quit Ogma to exit.

Type : for emoji, / for saved shortcuts, or /date for today's date. Use arrows,
Enter, Escape, or click a suggestion. Create shortcuts in Settings > Shortcuts.
Preferences and shortcuts are saved locally in %LOCALAPPDATA%\Ogma. Ogma does
not save typing history, use the clipboard, or upload data.

A publicly trusted signing certificate is required for distribution to PCs
protected by Smart App Control. A self-signed certificate is not a substitute.
SmartScreen may still show a reputation warning for a newly signed publisher.
Report any security block to the publisher, including the exact blocked file.

Ogma cannot insert into apps running as administrator or the Windows secure
desktop. Custom editors, IMEs, and missing emoji fonts may limit functionality.
This is a preview and still needs testing on Windows before a public release.
Releases: https://github.com/raulpop8/ogma/releases

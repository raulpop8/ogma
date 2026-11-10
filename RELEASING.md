# Releasing Ogma

Ogma uses a Developer ID signed, notarized DMG on GitHub Releases and a [Sparkle update feed](https://raulpop8.github.io/ogma/appcast.xml) on GitHub Pages. Keep the bundle ID and Sparkle public key unchanged so installed copies can update.

## Setup

- Select a Developer ID Application certificate for the Ogma target in Xcode. Store notarization credentials in the Keychain as `ogma-notary` using [Apple's notarytool setup](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).
- Keep the Sparkle signing key in the Keychain under account `ogma`; back it up securely. Never commit signing keys or credentials.
- Publish GitHub Pages from `main` → `/docs`.

## Each release

1. Increase both **Version** and **Build** in Xcode. Build and test the installed app, including the menu bar item, Accessibility access, and emoji insertion.
2. **Product → Archive → Distribute App → Developer ID**. Export the signed `Ogma.app`.
3. Notarize the DMG. The script checks the app signature and embedded Sparkle framework before submitting it:

   ```sh
   scripts/create-release-dmg.sh /path/to/exported/Ogma.app ogma-notary
   ```

4. Create a GitHub release tagged `vX.Y.Z` and attach the resulting `Build/Releases/Ogma-X.Y.Z.dmg`.
5. After the download is available, sign and publish the update entry:

   ```sh
   scripts/update-appcast.sh Build/Releases/Ogma-X.Y.Z.dmg vX.Y.Z
   git add docs/appcast.xml
   git commit -m "release: publish Ogma X.Y.Z update feed"
   git push origin main
   ```

6. Confirm the [public feed](https://raulpop8.github.io/ogma/appcast.xml) shows the new build. In the previous installed release, choose **Check for Updates…** and test download, installation, relaunch, and permissions.

## Windows: Microsoft Store

The public Windows edition is **Ogma Typing** on [Microsoft Store](https://apps.microsoft.com/detail/9N271VJTZDCH). Its code and packaging guide currently live on the [`codex/windows-store` branch](https://github.com/raulpop8/ogma/tree/codex/windows-store/Windows).

1. Increase the Windows app version and MSIX package version. Keep the reserved identity and publisher unchanged. The fourth Store package version component must remain zero.
2. Run the Windows checks and build x64 and ARM64 MSIX packages with `Windows/package-store.ps1`, or use the verified Windows workflow artifacts.
3. Test the candidate on Windows, including the affected editors. CI tests cover native edit controls; they do not prove compatibility with every Notepad release or third-party app.
4. Create an update submission for the existing product in Partner Center and upload both packages. Complete the submission, certification, and publication process.
5. Verify the published version installs through Microsoft Store and updates an older installed copy.

The MSIX artifacts are unsigned **Store submission packages**. Microsoft signs the Store-distributed app after certification. They are not direct-download installers. Store updates follow the user's Microsoft Store settings; a GitHub push or website update does not publish them.

See the [Windows submission guide](https://github.com/raulpop8/ogma/blob/codex/windows-store/Windows/Store/SUBMISSION.md) for identity details and commands.

### Development builds and other distribution

The Windows workflow also produces explicitly unsigned development previews. Smart App Control may block these; do not advertise them as the public Windows download. A future direct-download release needs trusted Windows signing, its own distribution/update process, and live validation. It must never be added to the Mac Sparkle feed.

### Versions across platforms

The existing Mac and Windows releases have independent version numbers. For future coordinated product releases, align the user-visible version when their scope matches, while retaining platform-specific build/package numbers. A platform-only fix may ship separately. Do not renumber a published release or announce a version before its distribution channel is ready.

## Website-only updates

The presentation site is published by GitHub Pages from `main` → `/docs`. See [WEBSITE.md](WEBSITE.md). Keep `docs/appcast.xml` unchanged when editing the website; publishing a page does not publish an app update.

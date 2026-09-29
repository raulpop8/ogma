# Releasing Ogma for macOS

Ogma is distributed directly as a notarized DMG. Sparkle checks the update feed
at `https://raulpop8.github.io/ogma/appcast.xml`; the DMG downloads come from
GitHub Releases. Keep the bundle identifier `com.raulpop.Ogma` and the Sparkle
public key unchanged for subsequent updates.

## One-time setup

1. In Xcode's account settings, create or install a **Developer ID Application**
   certificate for team `M7XKT47DLY`. The Release configuration already enables
   Hardened Runtime. Do not use the Apple Development certificate for a release.
2. Store notarization credentials in your login Keychain under a profile such as
   `ogma-notary`. Follow [Apple's notarytool instructions](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).
   Never put the password, API key, or Sparkle private key in this repository.
3. In GitHub repository Settings → Pages, select **Deploy from a branch**, `main`,
   `/docs`. The initial feed contains no update; the first DMG release replaces it
   with a signed update entry.
4. Keep a secure backup of the Sparkle private key stored in the login Keychain
   under account `ogma`. The matching public key is in `Ogma/Info.plist`.

## Each release

1. In Xcode, increase **Version** and **Build** for the Ogma target. The build
   number must increase every time. Build and test on a Mac, including the
   menu-bar flow and Accessibility permission after installation.
2. Select **Product → Archive**. In Organizer, choose **Distribute App → Developer ID**
   and export the signed `Ogma.app`. Check that it is signed by Developer ID.
3. Create and notarize the installer image:

   ```sh
   scripts/create-release-dmg.sh /path/to/exported/Ogma.app ogma-notary
   ```

   The result is `Build/Releases/Ogma-X.Y.Z.dmg`. Open it and drag Ogma into
   Applications. Quit any Xcode-run copy first so only the installed app runs.
4. Create GitHub release `vX.Y.Z` and attach that exact DMG. The release asset
   must be reachable before publishing the update feed.
5. Generate the signed Sparkle entry, then commit and push the feed:

   ```sh
   scripts/update-appcast.sh Build/Releases/Ogma-X.Y.Z.dmg vX.Y.Z
   git add docs/appcast.xml
   git commit -m "release: publish Ogma X.Y.Z update feed"
   git push origin main
   ```

6. Check that the [public appcast](https://raulpop8.github.io/ogma/appcast.xml)
   loads. From an older installed Ogma, choose **Check for Updates…** in the menu
   bar and verify the full download, installation, relaunch, and permissions.

The first release establishes the updater. To test an actual update, publish a
second release with a higher build number; Sparkle cannot update a running
Xcode development build reliably. Sparkle asks about automatic checks after
the second launch and checks periodically thereafter. The update menu is shown
in Release builds, including the installed app, and is hidden in Xcode's Debug
builds.

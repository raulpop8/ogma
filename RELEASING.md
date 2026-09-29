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

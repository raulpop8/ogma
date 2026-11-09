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

## Windows preview

The Windows app uses its own version in `Windows/Ogma.Windows/Ogma.Windows.csproj` and has no Sparkle integration. See [Windows/README.md](Windows/README.md) for build commands and the required Windows test pass. The Windows workflow produces portable, self-contained ZIPs for x64 and ARM64 without publishing them.

Smart App Control can hard-block the unsigned preview with no per-app allow exception. Public distribution requires a publicly trusted Windows code-signing identity. A self-signed or Apple certificate does not provide it. No such identity is currently configured for Ogma.

Once a trusted certificate is available in the Windows certificate store, build with `./Windows/publish.ps1 -Runtime win-x64 -Version X.Y.Z -CertificateThumbprint YOUR_THUMBPRINT` and repeat for `win-arm64`. The script signs and timestamps `Ogma.exe`, `Ogma.dll`, and `Ogma.Core.dll`, verifies every shipped EXE/DLL, and only then creates a `-signed.zip`. Signed releases use a folder deployment; keep the entire ZIP contents together. Test both packages on independent Windows PCs with Smart App Control enabled. Signing/Windows acceptance still needs live validation; this workflow has not produced a signed release yet.

Unsigned development builds require the explicit `-AllowUnsigned` switch and are named `-unsigned-preview.zip`; they are not suitable for testing on PCs where Smart App Control blocks them. CI uses this development mode until a signing identity is configured. Keep signing credentials outside the repository. Use a separate `windows-vX.Y.Z` release tag while Windows versions are independent; attach the verified signed ZIPs manually and identify preview limitations in the release notes. Do not add Windows builds to the macOS update feed or advertise a Windows download before a verified artifact is published.

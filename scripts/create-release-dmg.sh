#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 /path/to/exported/Ogma.app notary-keychain-profile [output-directory]" >&2
    exit 2
fi

app_path="$1"
notary_profile="$2"
script_dir="$(cd "$(dirname "$0")" && pwd)"
output_dir="${3:-$script_dir/../Build/Releases}"

if [[ ! -d "$app_path" || ! -f "$app_path/Contents/Info.plist" ]]; then
    echo "Expected an exported Ogma.app bundle." >&2
    exit 1
fi

plist="$app_path/Contents/Info.plist"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"

if [[ "$bundle_id" != "com.raulpop.Ogma" || ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ! "$build" =~ ^[0-9]+$ ]]; then
    echo "Unexpected bundle identifier or version in Ogma.app." >&2
    exit 1
fi

codesign --verify --deep --strict "$app_path"
signature="$(codesign -dv --verbose=4 "$app_path" 2>&1)"
if ! grep -q 'Authority=Developer ID Application:' <<< "$signature"; then
    echo "Ogma.app must be exported with Developer ID Application signing." >&2
    exit 1
fi
if ! grep -q 'flags=.*runtime' <<< "$signature"; then
    echo "Ogma.app must have Hardened Runtime enabled." >&2
    exit 1
fi

mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
final_dmg_path="$output_dir/Ogma-$version.dmg"
if [[ -e "$final_dmg_path" ]]; then
    echo "Refusing to replace existing release: $final_dmg_path" >&2
    exit 1
fi

staging_dir="$(mktemp -d "${TMPDIR:-/private/tmp}/ogma-dmg.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
mkdir "$staging_dir/contents"
ditto "$app_path" "$staging_dir/contents/Ogma.app"
ln -s /Applications "$staging_dir/contents/Applications"
dmg_path="$staging_dir/Ogma-$version.dmg"

hdiutil create -quiet -volname "Ogma $version" -srcfolder "$staging_dir/contents" -format UDZO "$dmg_path"
xcrun notarytool submit "$dmg_path" --keychain-profile "$notary_profile" --wait
xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
hdiutil verify -quiet "$dmg_path"
mv "$dmg_path" "$final_dmg_path"

echo "Ready to publish: $final_dmg_path (version $version, build $build)"

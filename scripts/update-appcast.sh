#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 /path/to/Ogma-X.Y.Z.dmg vX.Y.Z" >&2
    exit 2
fi

dmg_path="$1"
tag="$2"
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"

if [[ ! -f "$dmg_path" || ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected a notarized DMG and a vX.Y.Z release tag." >&2
    exit 1
fi
version="${tag#v}"
if [[ "$(basename "$dmg_path")" != "Ogma-$version.dmg" ]]; then
    echo "The DMG filename must match the release tag." >&2
    exit 1
fi
xcrun stapler validate "$dmg_path"

packages_dir="$repo_dir/Build/SourcePackages"
generator="$packages_dir/artifacts/sparkle/Sparkle/bin/generate_appcast"
if [[ ! -x "$generator" ]]; then
    xcodebuild -resolvePackageDependencies -project "$repo_dir/Ogma.xcodeproj" \
        -scheme Ogma -clonedSourcePackagesDirPath "$packages_dir"
fi
if [[ ! -x "$generator" ]]; then
    echo "Sparkle's generate_appcast tool was not found." >&2
    exit 1
fi

staging_dir="$(mktemp -d "${TMPDIR:-/private/tmp}/ogma-appcast.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
cp "$dmg_path" "$staging_dir/"
"$generator" --account ogma --maximum-versions 1 --maximum-deltas 0 \
    --download-url-prefix "https://github.com/raulpop8/ogma/releases/download/$tag/" \
    "$staging_dir"

appcast="$staging_dir/appcast.xml"
if [[ ! -s "$appcast" ]] || ! grep -q 'sparkle:edSignature=' "$appcast"; then
    echo "Sparkle did not generate a signed update entry." >&2
    exit 1
fi
mkdir -p "$repo_dir/docs"
cp "$appcast" "$repo_dir/docs/appcast.xml"
echo "Updated $repo_dir/docs/appcast.xml for $tag"

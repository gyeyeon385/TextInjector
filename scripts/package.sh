#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${1:-$ROOT/dist}"
DERIVED="${2:-$ROOT/build/release}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/Resources/Info.plist")
mkdir -p "$DIST"
DIST="$(cd "$DIST" && pwd)"
PACKAGE_WORK="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_WORK"' EXIT
bash "$ROOT/scripts/build-icon.sh"
xcodebuild -project "$ROOT/TextInjector.xcodeproj" -scheme TextInjector \
  -configuration Release -derivedDataPath "$DERIVED" \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
APP="$DERIVED/Build/Products/Release/TextInjector.app"
codesign --verify --deep --strict "$APP"
BUILT_ARCHS="$(lipo -archs "$APP/Contents/MacOS/TextInjector")"
[[ " $BUILT_ARCHS " == *" arm64 "* && " $BUILT_ARCHS " == *" x86_64 "* ]]
ditto "$APP" "$PACKAGE_WORK/TextInjector.app"
ln -s /Applications "$PACKAGE_WORK/Applications"
cp "$ROOT/docs/INSTALL.md" "$PACKAGE_WORK/INSTALL.txt"
DMG="$DIST/TextInjector-$VERSION-universal.dmg"
ZIP="$DIST/TextInjector-$VERSION-universal.zip"
# Deliberately refuse to overwrite existing release assets.
test ! -e "$DMG"
test ! -e "$ZIP"
hdiutil create -volname "TextInjector $VERSION" -srcfolder "$PACKAGE_WORK" \
  -format UDZO -ov "$DMG"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
(cd "$DIST" && shasum -a 256 "$(basename "$DMG")" "$(basename "$ZIP")" > SHA256SUMS.txt)
printf '\nRelease files: %s\n' "$DIST"

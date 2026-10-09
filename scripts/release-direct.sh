#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
ARCHIVE_PATH="$PROJECT_DIR/build/Borda-Direct.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/direct-export"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")
DMG_PATH="$PROJECT_DIR/dist/Borda-$VERSION.dmg"

: "${BORDA_DEVELOPMENT_TEAM:?Defina BORDA_DEVELOPMENT_TEAM com o Team ID da Apple}"
: "${BORDA_NOTARY_PROFILE:?Defina BORDA_NOTARY_PROFILE com o perfil do notarytool}"

cd "$PROJECT_DIR"
"$PROJECT_DIR/scripts/generate-xcode-project.sh" >/dev/null
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

xcodebuild archive \
    -project Borda.xcodeproj \
    -scheme Borda-Direct \
    -configuration Release-Direct \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$BORDA_DEVELOPMENT_TEAM"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist Config/ExportOptions-Direct.plist

BORDA_APP_PATH="$EXPORT_PATH/Borda.app" "$PROJECT_DIR/scripts/build-dmg.sh" >/dev/null
codesign --force --timestamp --sign "Developer ID Application" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$BORDA_NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
hdiutil verify "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "$DMG_PATH"

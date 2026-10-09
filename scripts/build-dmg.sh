#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")
DIST_DIR="$PROJECT_DIR/dist"
DMG_PATH="$DIST_DIR/Borda-$VERSION.dmg"
STAGING_DIR=$(mktemp -d /tmp/BordaDMG.XXXXXX)
MOUNT_DIR="/Volumes/Borda"
RW_DMG="$STAGING_DIR/Borda-rw.dmg"
BACKGROUND_DIR="$STAGING_DIR/payload/.background"
VOLUME_NAME="Borda"

cleanup() {
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if test -d "$MOUNT_DIR"; then
    echo "Ejete o volume Borda antes de gerar um novo DMG." >&2
    exit 1
fi

"$PROJECT_DIR/scripts/make-icon.sh" >/dev/null
if [[ -n "${BORDA_APP_PATH:-}" ]]; then
    APP_SOURCE="$BORDA_APP_PATH"
else
    "$PROJECT_DIR/scripts/build-app.sh" >/dev/null
    APP_SOURCE="$PROJECT_DIR/.build/Borda.app"
fi
if [[ ! -d "$APP_SOURCE" ]]; then
    echo "Borda.app não encontrado em $APP_SOURCE" >&2
    exit 1
fi
mkdir -p "$DIST_DIR"
mkdir -p "$STAGING_DIR/payload" "$BACKGROUND_DIR"
ditto "$APP_SOURCE" "$STAGING_DIR/payload/Borda.app"
ln -s /Applications "$STAGING_DIR/payload/Applications"
/opt/homebrew/bin/rsvg-convert \
    --width 660 \
    --height 400 \
    "$PROJECT_DIR/Resources/DMGBackground.svg" \
    --output "$BACKGROUND_DIR/background.png"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$STAGING_DIR/payload/.VolumeIcon.icns"

/usr/bin/hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR/payload" \
    -ov \
    -format UDRW \
    "$RW_DMG" >/dev/null

/usr/bin/hdiutil attach "$RW_DMG" \
    -readwrite \
    -noverify \
    -noautoopen >/dev/null

/usr/bin/SetFile -a V "$MOUNT_DIR/.background" "$MOUNT_DIR/.VolumeIcon.icns"
/usr/bin/SetFile -a C "$MOUNT_DIR"
/usr/bin/osascript "$PROJECT_DIR/scripts/configure-dmg.applescript" "$VOLUME_NAME"
/bin/sync
/usr/bin/hdiutil detach "$MOUNT_DIR" -quiet

/usr/bin/hdiutil convert "$RW_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$DMG_PATH" >/dev/null

/usr/bin/codesign --verify --deep --strict "$APP_SOURCE"
echo "$DMG_PATH"

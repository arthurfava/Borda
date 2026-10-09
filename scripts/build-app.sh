#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
cd "$PROJECT_DIR"

swift build -c release --product Borda
BIN_DIR=$(swift build -c release --show-bin-path)
APP_DIR="$PROJECT_DIR/.build/Borda.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/Borda" "$APP_DIR/Contents/MacOS/Borda"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/Resources/PrivacyInfo.xcprivacy" "$APP_DIR/Contents/Resources/PrivacyInfo.xcprivacy"
ditto "$PROJECT_DIR/Resources/Localization" "$APP_DIR/Contents/Resources"

SIGN_IDENTITY=${BORDA_SIGN_IDENTITY:--}
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    /usr/bin/codesign --force --sign - "$APP_DIR"
else
    /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi
echo "$APP_DIR"

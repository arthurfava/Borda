#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
SOURCE="$PROJECT_DIR/Resources/AppIcon-Source.png"
ICONSET="$PROJECT_DIR/.build/AppIcon.iconset"
OUTPUT="$PROJECT_DIR/Resources/AppIcon.icns"

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

make_size() {
    local pixels=$1
    local name=$2
    /usr/bin/sips -z "$pixels" "$pixels" "$SOURCE" --out "$ICONSET/$name" >/dev/null
}

make_size 16 icon_16x16.png
make_size 32 icon_16x16@2x.png
make_size 32 icon_32x32.png
make_size 64 icon_32x32@2x.png
make_size 128 icon_128x128.png
make_size 256 icon_128x128@2x.png
make_size 256 icon_256x256.png
make_size 512 icon_256x256@2x.png
make_size 512 icon_512x512.png
make_size 1024 icon_512x512@2x.png

/usr/bin/iconutil -c icns "$ICONSET" -o "$OUTPUT"
echo "$OUTPUT"

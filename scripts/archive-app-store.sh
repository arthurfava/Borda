#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
ARCHIVE_PATH="$PROJECT_DIR/build/Borda-AppStore.xcarchive"
: "${BORDA_DEVELOPMENT_TEAM:?Defina BORDA_DEVELOPMENT_TEAM com o Team ID da Apple}"

cd "$PROJECT_DIR"
"$PROJECT_DIR/scripts/generate-xcode-project.sh" >/dev/null
rm -rf "$ARCHIVE_PATH"
xcodebuild archive \
    -project Borda.xcodeproj \
    -scheme Borda-AppStore \
    -configuration Release-AppStore \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$BORDA_DEVELOPMENT_TEAM"

echo "$ARCHIVE_PATH"

#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
cd "$PROJECT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Instale o XcodeGen com: brew install xcodegen" >&2
    exit 1
fi

xcodegen generate --spec project.yml
echo "$PROJECT_DIR/Borda.xcodeproj"

#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

xcodegen generate
xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -configuration Release -destination 'platform=macOS' -derivedDataPath build/DerivedData build

#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo "Full Xcode.app is required for release builds. Install Xcode and switch with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

sudo_xcode_path="/Applications/Xcode.app/Contents/Developer"
if [[ "$(xcode-select -p 2>/dev/null || true)" != "$sudo_xcode_path" ]]; then
  echo "Active developer directory is not full Xcode. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

xcodegen generate
mkdir -p build/DerivedData build/Products
/usr/bin/xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -configuration Release -destination 'platform=macOS' -derivedDataPath build/DerivedData CONFIGURATION_BUILD_DIR="$ROOT_DIR/build/Products" build

if [[ ! -d "$ROOT_DIR/build/Products/Rhythm Replica.app" ]]; then
  echo "Release build did not produce build/Products/Rhythm Replica.app" >&2
  exit 1
fi

#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="build/Products/Rhythm Replica.app"
DMG_PATH="build/RhythmReplica.dmg"
STAGING_DIR="build/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle not found at $APP_PATH. Run ./scripts/build-release.sh first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "Rhythm Replica" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

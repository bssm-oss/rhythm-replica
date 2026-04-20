#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="build/DerivedData/Build/Products/Release/Rhythm Replica.app"
DMG_PATH="build/RhythmReplica.dmg"
STAGING_DIR="build/dmg-staging"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

hdiutil create -volname "Rhythm Replica" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

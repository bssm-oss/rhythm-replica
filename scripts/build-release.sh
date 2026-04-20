#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_BUNDLE_PATH="$ROOT_DIR/build/Products/Rhythm Replica.app"
APP_CONTENTS_PATH="$APP_BUNDLE_PATH/Contents"
APP_MACOS_PATH="$APP_CONTENTS_PATH/MacOS"
APP_RESOURCES_PATH="$APP_CONTENTS_PATH/Resources"
VERSION="$(python3 - <<'PY'
from pathlib import Path
import re
text = Path('project.yml').read_text()
match = re.search(r'MARKETING_VERSION:\s*([0-9.]+)', text)
print(match.group(1) if match else '0.1.3')
PY
)"

mkdir -p build/DerivedData build/Products

if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo "Full Xcode.app not found. Falling back to SwiftPM release packaging." >&2
  rm -rf "$APP_BUNDLE_PATH"
  swift build -c release
  mkdir -p "$APP_MACOS_PATH" "$APP_RESOURCES_PATH"
  cp ".build/release/RhythmReplica" "$APP_MACOS_PATH/Rhythm Replica"
  chmod +x "$APP_MACOS_PATH/Rhythm Replica"
  if [[ -d ".build/release/RhythmReplica_RhythmReplicaKit.bundle" ]]; then
    cp -R ".build/release/RhythmReplica_RhythmReplicaKit.bundle" "$APP_RESOURCES_PATH/"
  fi
  cat > "$APP_CONTENTS_PATH/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Rhythm Replica</string>
  <key>CFBundleIdentifier</key>
  <string>com.bssm.rhythmreplica</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Rhythm Replica</string>
  <key>CFBundleDisplayName</key>
  <string>Rhythm Replica</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF
  codesign --force --deep --sign - "$APP_BUNDLE_PATH"
  echo "Created fallback app bundle at $APP_BUNDLE_PATH"
  exit 0
fi

sudo_xcode_path="/Applications/Xcode.app/Contents/Developer"
if [[ "$(xcode-select -p 2>/dev/null || true)" != "$sudo_xcode_path" ]]; then
  echo "Active developer directory is not full Xcode. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

xcodegen generate
/usr/bin/xcodebuild -project RhythmReplica.xcodeproj -scheme RhythmReplica -configuration Release -destination 'platform=macOS' -derivedDataPath build/DerivedData CONFIGURATION_BUILD_DIR="$ROOT_DIR/build/Products" build

if [[ ! -d "$APP_BUNDLE_PATH" ]]; then
  echo "Release build did not produce build/Products/Rhythm Replica.app" >&2
  exit 1
fi

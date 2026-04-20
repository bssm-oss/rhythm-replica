#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <version> <sha256>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CASK_FILE="$ROOT_DIR/homebrew/rhythm-replica.rb"
VERSION="$1"
SHA="$2"

python3 - "$CASK_FILE" "$VERSION" "$SHA" <<'PY'
from pathlib import Path
import sys
import re

path = Path(sys.argv[1])
version = sys.argv[2]
sha = sys.argv[3]
text = path.read_text()
text = re.sub(r'version ".*"', f'version "{version}"', text, count=1)
text = re.sub(r'sha256 ".*"', f'sha256 "{sha}"', text)
path.write_text(text)
PY

echo "Updated $CASK_FILE to version $VERSION with sha256 $SHA"

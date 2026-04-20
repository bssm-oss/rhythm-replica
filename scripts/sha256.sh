#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <file>" >&2
  exit 1
fi

shasum -a 256 "$1"

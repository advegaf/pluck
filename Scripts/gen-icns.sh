#!/bin/bash
# Build an Apple .icns file from a single 1024x1024 PNG master.
# Usage: gen-icns.sh <source.png> <output.icns>
#
# macOS expects the iconset to contain the canonical size/@2x pairs:
# 16, 32, 128, 256, 512 pt at 1x AND 2x. We resample from the master
# via `sips` and pack with `iconutil`.

set -euo pipefail

SRC="${1:?source PNG path required}"
OUT="${2:?output .icns path required}"

ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

declare -a sizes=(
  "16   icon_16x16"
  "32   icon_16x16@2x"
  "32   icon_32x32"
  "64   icon_32x32@2x"
  "128  icon_128x128"
  "256  icon_128x128@2x"
  "256  icon_256x256"
  "512  icon_256x256@2x"
  "512  icon_512x512"
  "1024 icon_512x512@2x"
)

for entry in "${sizes[@]}"; do
  read -r px name <<< "$entry"
  sips -z "$px" "$px" "$SRC" --out "$ICONSET_DIR/${name}.png" > /dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$OUT"
echo "wrote $OUT"

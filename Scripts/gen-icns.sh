#!/bin/bash
# Build an Apple .icns from the pre-exported iconset the user shipped
# (sourced once from ~/Desktop/Icon Exports, now living at
# Sources/Pluck/Resources/iconset/). Each size is a native export rather
# than a sips-resampled version of a single master, so the output is
# pixel-perfect at every scale.
#
# Usage: gen-icns.sh [output.icns]

set -euo pipefail

ICONSET_SRC="${ICONSET_SRC:-Sources/Pluck/Resources/iconset}"
OUT="${1:?output .icns path required}"

if [[ ! -d "$ICONSET_SRC" ]]; then
  echo "error: missing iconset dir $ICONSET_SRC" >&2
  exit 1
fi

STAGE="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$STAGE"

for file in \
  icon_16x16.png \
  icon_16x16@2x.png \
  icon_32x32.png \
  icon_32x32@2x.png \
  icon_128x128.png \
  icon_128x128@2x.png \
  icon_256x256.png \
  icon_256x256@2x.png \
  icon_512x512.png \
  icon_512x512@2x.png; do
  if [[ ! -f "$ICONSET_SRC/$file" ]]; then
    echo "error: missing $ICONSET_SRC/$file" >&2
    exit 1
  fi
  cp "$ICONSET_SRC/$file" "$STAGE/$file"
done

iconutil -c icns "$STAGE" -o "$OUT"
echo "wrote $OUT"

#!/bin/bash
#
# release.sh — signed + notarized DMG release pipeline for Pluck.
# Modeled on advegaf/selfcontrol-mastered's release.sh, adapted for our
# SwiftPM + Makefile-bundled .app (no helpers, no Sparkle, no workspace).
#
# Environment (set by the Makefile `dmg` target):
#   CODESIGN_IDENTITY   — Developer ID Application: …
#   NOTARY_PROFILE      — notarytool keychain profile (e.g. selfcontrol-notary)
#   VERSION             — semver from Info.plist (e.g. 0.1.0)
#   APP_NAME            — Pluck
#
# Optional:
#   SKIP_NOTARIZATION=1 — build a signed-but-unnotarized DMG. Useful when the
#                         Apple Developer agreement has lapsed and `notarytool`
#                         returns 403. Result still drag-installs locally but
#                         shows a Gatekeeper warning on other Macs.
#
# Requires:
#   * Xcode CLT (codesign, stapler, notarytool, iconutil, sips)
#   * `npx` (brew install node)
#   * Python + `ds_store` + `mac_alias` (pip3 install --user ds-store mac-alias)
#   * CODESIGN_IDENTITY cert + NOTARY_PROFILE in keychain

set -euo pipefail

: "${CODESIGN_IDENTITY:?set by Makefile}"
: "${NOTARY_PROFILE:?set by Makefile}"
: "${VERSION:?set by Makefile}"
: "${APP_NAME:?set by Makefile}"

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
readonly BACKGROUND_PNG="${BUILD_DIR}/dmg-background.png"
readonly BACKGROUND_TIFF="${BUILD_DIR}/dmg-background.tiff"
readonly VOLNAME="${APP_NAME}"
readonly SINDRE_DMG="${BUILD_DIR}/${APP_NAME} ${VERSION}.dmg"
readonly RW_DMG="${BUILD_DIR}/${APP_NAME}-${VERSION}-rw.dmg"
readonly FINAL_DMG="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"
readonly NOTARY_ZIP="${BUILD_DIR}/${APP_NAME}-${VERSION}-notarize.zip"
readonly MOUNT_DIR="/Volumes/${APP_NAME}"

readonly DSSTORE_PY="python3"
readonly DSSTORE_SITE="${HOME}/Library/Python/3.9/lib/python/site-packages"

# ─── Pretty logging ────────────────────────────────────────────────────────────
c_dim="\033[2m"; c_bold="\033[1m"
c_green="\033[32m"; c_yellow="\033[33m"; c_red="\033[31m"; c_blue="\033[34m"; c_off="\033[0m"
step() { echo -e "\n${c_bold}${c_blue}==>${c_off} ${c_bold}$1${c_off}"; }
info() { echo -e "    ${c_dim}$1${c_off}"; }
ok()   { echo -e "    ${c_green}✓${c_off} $1"; }
warn() { echo -e "    ${c_yellow}⚠${c_off} $1"; }
die()  { echo -e "\n${c_red}error:${c_off} $1\n" >&2; exit 1; }

cd "${PROJECT_ROOT}"

# ─── Pre-flight ────────────────────────────────────────────────────────────────
step "PRE-FLIGHT"
security find-identity -v -p codesigning 2>/dev/null \
    | grep -q "${CODESIGN_IDENTITY}" \
    || die "signing identity missing: ${CODESIGN_IDENTITY}"
ok "codesign identity present"

if [[ "${SKIP_NOTARIZATION:-0}" != "1" ]]; then
    if ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
        warn "notarytool profile '${NOTARY_PROFILE}' cannot reach Apple (403 or missing)"
        warn "accept the Apple Developer Program agreement at developer.apple.com/account/"
        warn "or re-run with SKIP_NOTARIZATION=1 to skip the notarize step"
        die  "notarization pre-check failed"
    fi
    ok "notarytool profile reachable"
else
    warn "SKIP_NOTARIZATION=1 — building signed-but-unnotarized DMG"
fi

command -v npx >/dev/null 2>&1 || die "npx missing (brew install node)"
PYTHONPATH="${DSSTORE_SITE}" "${DSSTORE_PY}" -c "import ds_store, mac_alias" >/dev/null 2>&1 \
    || die "python ds_store/mac_alias missing (pip3 install --user ds-store mac-alias)"
[[ -f "${PROJECT_ROOT}/Scripts/generate-dmg-background.swift" ]] \
    || die "missing Scripts/generate-dmg-background.swift"
ok "all assets present"

# ─── Build + sign with Developer ID ────────────────────────────────────────────
step "BUILD + SIGN"
pkill -x "${APP_NAME}" 2>/dev/null || true
# Our Makefile's bundle target signs with $CODESIGN_IDENTITY. We pass the
# Developer ID through the environment so the same target produces a
# release-grade signed bundle.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY}" make bundle 2>&1 | tail -15
[[ -d "${APP_BUNDLE}" ]] || die "bundle missing: ${APP_BUNDLE}"
ok "built ${APP_BUNDLE}"

# ─── Verify ────────────────────────────────────────────────────────────────────
step "VERIFY CODESIGN"
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}" 2>&1 | tail -5
codesign -dvv "${APP_BUNDLE}" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier=" | sed 's/^/    /'
if codesign -d --entitlements - "${APP_BUNDLE}" 2>/dev/null | grep -q "get-task-allow"; then
    die "get-task-allow entitlement present — notarization would fail"
fi
ok "hardened runtime, no debug entitlements"

# ─── Notarize + staple .app ────────────────────────────────────────────────────
if [[ "${SKIP_NOTARIZATION:-0}" != "1" ]]; then
    step "NOTARIZE APP"
    rm -f "${NOTARY_ZIP}"
    ditto -c -k --keepParent "${APP_BUNDLE}" "${NOTARY_ZIP}"
    info "submitting ${NOTARY_ZIP} (~3–10 min)..."
    notary_out=$(xcrun notarytool submit "${NOTARY_ZIP}" \
        --keychain-profile "${NOTARY_PROFILE}" --wait 2>&1)
    echo "${notary_out}" | sed 's/^/    /'
    if ! echo "${notary_out}" | grep -q "status: Accepted"; then
        sub_id=$(echo "${notary_out}" | awk '/id:/ {print $2; exit}')
        if [[ -n "${sub_id}" ]]; then
            xcrun notarytool log "${sub_id}" --keychain-profile "${NOTARY_PROFILE}" 2>&1 | sed 's/^/    /'
        fi
        die "app notarization rejected"
    fi
    ok "app notarized"
    rm -f "${NOTARY_ZIP}"

    step "STAPLE APP"
    xcrun stapler staple "${APP_BUNDLE}"
    xcrun stapler validate "${APP_BUNDLE}"
    ok "app stapled"
fi

# ─── Background ────────────────────────────────────────────────────────────────
step "GENERATE DMG BACKGROUND"
swift "${PROJECT_ROOT}/Scripts/generate-dmg-background.swift" "${BACKGROUND_PNG}"
sips -s dpiHeight 144 -s dpiWidth 144 "${BACKGROUND_PNG}" >/dev/null
sips -s format tiff "${BACKGROUND_PNG}" --out "${BACKGROUND_TIFF}" >/dev/null
sips -s dpiHeight 144 -s dpiWidth 144 "${BACKGROUND_TIFF}" >/dev/null
ok "background rendered at 144 DPI"

# ─── Build DMG (phase 1 + phase 2 post-process) ────────────────────────────────
step "BUILD DMG"
for vol in "/Volumes/${APP_NAME}" "/Volumes/${APP_NAME} "?*; do
    [[ -d "$vol" ]] && hdiutil detach "$vol" -force >/dev/null 2>&1 || true
done
rm -f "${SINDRE_DMG}" "${RW_DMG}" "${FINAL_DMG}"

info "phase 1: npx create-dmg (base DMG with working background alias)..."
npx --yes create-dmg@latest --no-code-sign --overwrite \
    "${APP_BUNDLE}" "${BUILD_DIR}/" 2>&1 | sed 's/^/    /'
[[ -f "${SINDRE_DMG}" ]] || die "create-dmg did not produce ${SINDRE_DMG}"

info "phase 2: post-process (swap background + rewrite .DS_Store)..."
hdiutil convert "${SINDRE_DMG}" -format UDRW -o "${RW_DMG}" >/dev/null
rm -f "${SINDRE_DMG}"
hdiutil attach -readwrite -noverify "${RW_DMG}" >/dev/null
[[ -d "${MOUNT_DIR}" ]] || die "expected mount at ${MOUNT_DIR}"

cp "${BACKGROUND_TIFF}" "${MOUNT_DIR}/.background/dmg-background.tiff"

PYTHONPATH="${DSSTORE_SITE}" "${DSSTORE_PY}" - "${MOUNT_DIR}" "${APP_NAME}" <<'PY'
import sys, os, shutil
from ds_store import DSStore
from mac_alias import Alias

mount = sys.argv[1]
app_name = sys.argv[2]
ds_path = os.path.join(mount, '.DS_Store')
old_bg  = os.path.join(mount, '.background', 'dmg-background.tiff')
new_bg  = os.path.join(mount, '.bg.tiff')

shutil.move(old_bg, new_bg)
try:
    os.rmdir(os.path.join(mount, '.background'))
except OSError as e:
    print(f"warn: could not rmdir .background: {e}", file=sys.stderr)

new_alias = Alias.for_file(new_bg).to_bytes()

os.remove(ds_path)
with DSStore.open(ds_path, 'w+') as ds:
    ds['.']['icvp'] = {
        'arrangeBy':           'none',
        'backgroundColorBlue':  0.0,
        'backgroundColorGreen': 0.0,
        'backgroundColorRed':   0.0,
        'backgroundImageAlias': new_alias,
        'backgroundType':       2,
        'gridOffsetX':          0.0,
        'gridOffsetY':          0.0,
        'gridSpacing':          100.0,
        'iconSize':             96.0,
        'labelOnBottom':        True,
        'scrollPositionX':      0.0,
        'scrollPositionY':      0.0,
        'showIconPreview':      False,
        'showItemInfo':         False,
        'textSize':             11.0,
        'viewOptionsVersion':   1,
    }
    ds['.']['bwsp'] = {
        'ContainerShowSidebar':  False,
        'PreviewPaneVisibility': False,
        'ShowPathbar':           False,
        'ShowSidebar':           False,
        'ShowStatusBar':         False,
        'ShowTabView':           False,
        'ShowToolbar':           False,
        'SidebarWidth':          0,
        'WindowBounds':          '{{200, 200}, {660, 422}}',
    }
    ds['.']['icvl'] = (b'type', b'icnv')
    ds[app_name + '.app']['Iloc'] = (220, 270)
    ds['Applications']['Iloc']    = (440, 270)
print('rewrote .DS_Store')
PY

rm -f "${MOUNT_DIR}/.VolumeIcon.icns"
for f in "${MOUNT_DIR}/.bg.tiff" "${MOUNT_DIR}/.DS_Store"; do
    [[ -e "$f" ]] && chflags hidden "$f" 2>/dev/null || true
done
rm -rf "${MOUNT_DIR}/.fseventsd"
sync; sync
hdiutil detach "${MOUNT_DIR}" >/dev/null \
    || hdiutil detach "${MOUNT_DIR}" -force >/dev/null

hdiutil convert "${RW_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}" >/dev/null
rm -f "${RW_DMG}"
[[ -f "${FINAL_DMG}" ]] || die "hdiutil convert did not produce ${FINAL_DMG}"
ok "built ${FINAL_DMG}"

# ─── Sign the DMG ──────────────────────────────────────────────────────────────
step "SIGN DMG"
codesign --force --sign "${CODESIGN_IDENTITY}" --options runtime --timestamp "${FINAL_DMG}"
codesign --verify --verbose=2 "${FINAL_DMG}" 2>&1 | tail -3
ok "DMG signed"

# ─── Notarize + staple DMG ─────────────────────────────────────────────────────
if [[ "${SKIP_NOTARIZATION:-0}" != "1" ]]; then
    step "NOTARIZE DMG"
    info "submitting ${FINAL_DMG} (~3–10 min)..."
    dmg_out=$(xcrun notarytool submit "${FINAL_DMG}" \
        --keychain-profile "${NOTARY_PROFILE}" --wait 2>&1)
    echo "${dmg_out}" | sed 's/^/    /'
    if ! echo "${dmg_out}" | grep -q "status: Accepted"; then
        sub_id=$(echo "${dmg_out}" | awk '/id:/ {print $2; exit}')
        if [[ -n "${sub_id}" ]]; then
            xcrun notarytool log "${sub_id}" --keychain-profile "${NOTARY_PROFILE}" 2>&1 | sed 's/^/    /'
        fi
        die "DMG notarization rejected"
    fi
    ok "DMG notarized"

    step "STAPLE DMG"
    xcrun stapler staple "${FINAL_DMG}"
    xcrun stapler validate "${FINAL_DMG}"
    ok "DMG stapled"

    step "GATEKEEPER"
    spctl -a -vv -t install "${FINAL_DMG}" 2>&1 | sed 's/^/    /'
fi

# ─── Summary ───────────────────────────────────────────────────────────────────
step "SUMMARY"
readonly FINAL_SIZE=$(ls -lh "${FINAL_DMG}" | awk '{print $5}')
readonly FINAL_SHA=$(shasum -a 256 "${FINAL_DMG}" | awk '{print $1}')
echo
echo -e "    ${c_bold}artifact${c_off}   ${FINAL_DMG}"
echo -e "    ${c_bold}size${c_off}       ${FINAL_SIZE}"
echo -e "    ${c_bold}sha-256${c_off}    ${FINAL_SHA}"
echo
if [[ "${SKIP_NOTARIZATION:-0}" == "1" ]]; then
    echo -e "${c_yellow}${c_bold}    ⚠ signed but NOT notarized${c_off}"
    echo -e "    ${c_dim}rerun without SKIP_NOTARIZATION=1 after the Apple agreement is active${c_off}"
else
    echo -e "${c_green}${c_bold}    ✓ READY FOR DISTRIBUTION${c_off}"
fi
echo

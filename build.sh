#!/usr/bin/env bash
# Build TomoTexture.app and a distributable DMG.
#
# Usage:
#   ./build.sh                # build for current arch
#   ARCH=x86_64 ./build.sh    # build x86_64 (runs on Intel + Apple Silicon via Rosetta)
#   ARCH=arm64  ./build.sh    # build arm64 (Apple Silicon native, smaller)
#   ARCH=universal2 ./build.sh # fat binary (requires universal2 Python + wheels)
#
# Output:
#   dist/TomoTexture.app
#   dist/TomoTexture-<arch>.dmg

set -euo pipefail

APP_NAME="TomoTexture"
ENTRY="app.py"
ICON_PNG="safezone.png"
PY="${PYTHON:-python3}"
ARCH="${ARCH:-$(uname -m)}"
BUILD_DIR="build"
DIST_DIR="dist"
VENV_DIR="venv-build"
DMG_STAGING="${BUILD_DIR}/dmg-staging"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this build script only runs on macOS" >&2
  exit 1
fi

if [[ ! -f "$ENTRY" ]]; then
  echo "error: $ENTRY not found in $(pwd)" >&2
  exit 1
fi

echo "==> Building $APP_NAME for arch=$ARCH"

# 1. Build virtualenv
if [[ ! -d "$VENV_DIR" ]]; then
  echo "==> Creating build venv at $VENV_DIR"
  if [[ "$ARCH" == "x86_64" && "$(uname -m)" == "arm64" ]]; then
    arch -x86_64 "$PY" -m venv "$VENV_DIR"
  else
    "$PY" -m venv "$VENV_DIR"
  fi
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "==> Installing dependencies"
if [[ "$ARCH" == "x86_64" && "$(uname -m)" == "arm64" ]]; then
  arch -x86_64 python -m pip install --upgrade pip wheel >/dev/null
  arch -x86_64 python -m pip install -r requirements.txt pyinstaller >/dev/null
else
  python -m pip install --upgrade pip wheel >/dev/null
  python -m pip install -r requirements.txt pyinstaller >/dev/null
fi

# 2. Generate .icns from .png
ICONSET_DIR="${BUILD_DIR}/${APP_NAME}.iconset"
ICNS_PATH="${BUILD_DIR}/${APP_NAME}.icns"
echo "==> Generating ${ICNS_PATH}"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
for spec in "16:icon_16x16" "32:icon_16x16@2x" "32:icon_32x32" \
            "64:icon_32x32@2x" "128:icon_128x128" "256:icon_128x128@2x" \
            "256:icon_256x256" "512:icon_256x256@2x" "512:icon_512x512" \
            "1024:icon_512x512@2x"; do
  size="${spec%%:*}"
  name="${spec##*:}"
  sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/${name}.png" >/dev/null
done
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

# 3. Run PyInstaller
echo "==> Running PyInstaller"
PYI_CMD=(pyinstaller
  --windowed
  --noconfirm
  --clean
  --name "$APP_NAME"
  --icon "$ICNS_PATH"
  --osx-bundle-identifier "com.tomotexture.app"
  --add-data "${ICON_PNG}:."
  --hidden-import "PIL._tkinter_finder"
)

case "$ARCH" in
  arm64|x86_64|universal2)
    PYI_CMD+=(--target-architecture "$ARCH")
    ;;
esac

PYI_CMD+=("$ENTRY")

if [[ "$ARCH" == "x86_64" && "$(uname -m)" == "arm64" ]]; then
  arch -x86_64 "${PYI_CMD[@]}"
else
  "${PYI_CMD[@]}"
fi

APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: PyInstaller did not produce $APP_BUNDLE" >&2
  exit 1
fi

# 4. Strip extended attributes that break Gatekeeper on transfer
echo "==> Cleaning extended attributes"
xattr -cr "$APP_BUNDLE" || true

# 5. Ad-hoc codesign so the app launches without "is damaged" errors
echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - "$APP_BUNDLE" || true

# 6. Build the DMG
DMG_NAME="${APP_NAME}-${ARCH}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
echo "==> Creating ${DMG_PATH}"

rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo
echo "==> Done"
echo "    App:  $APP_BUNDLE"
echo "    DMG:  $DMG_PATH"
echo
echo "Distribute the DMG. Users drag the app icon onto Applications to install."
echo "Note: since the app is not notarized by Apple, first-time users may need to"
echo "right-click -> Open, or run 'xattr -dr com.apple.quarantine /Applications/${APP_NAME}.app'."

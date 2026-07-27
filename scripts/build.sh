#!/usr/bin/env bash
# Build a release FlyMinder.app and optional .dmg for distribution.
#
# Requirements:
#   - Full Xcode installed
#   - For public distribution: Apple Developer account + notarization (see below)
#
# Usage:
#   ./scripts/build.sh              # builds FlyMinder.app
#   ./scripts/build.sh --dmg        # also creates FlyMinder.dmg
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP_NAME="FlyMinder"
PRODUCT_NAME="MeetingReminder"
SCHEME="MeetingReminder"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

MAKE_DMG=false
if [[ "${1:-}" == "--dmg" ]]; then
  MAKE_DMG=true
fi

echo "→ Building ${APP_NAME} (Release)…"
DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild \
  -project "$ROOT/MeetingReminder.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
  build

BUILT_APP="$BUILD_DIR/Build/Products/Release/${PRODUCT_NAME}.app"
OUT_APP="$ROOT/${APP_NAME}.app"

rm -rf "$OUT_APP"
cp -R "$BUILT_APP" "$OUT_APP"
echo "✓ App bundle: $OUT_APP"

if $MAKE_DMG; then
  DMG_PATH="$ROOT/${APP_NAME}.dmg"
  STAGING="$BUILD_DIR/dmg-staging"
  rm -rf "$STAGING" "$DMG_PATH"
  mkdir -p "$STAGING"
  cp -R "$OUT_APP" "$STAGING/"
  ln -s /Applications "$STAGING/Applications"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

  rm -rf "$STAGING"
  echo "✓ Disk image: $DMG_PATH"
fi

cat <<'EOF'

Next steps for public distribution
──────────────────────────────────
1. Enroll in the Apple Developer Program ($99/yr).
2. Set your Team ID when building:
     DEVELOPMENT_TEAM=YOUR_TEAM_ID ./scripts/build.sh --dmg
3. Notarize the .dmg (requires app-specific password / keychain profile):
     xcrun notarytool submit FlyMinder.dmg --keychain-profile "AC_PASSWORD" --wait
     xcrun stapler staple FlyMinder.dmg
4. Host FlyMinder.dmg on your website (see website/index.html).
5. Update support email and URLs in MeetingReminder/AppInfo.swift.

EOF

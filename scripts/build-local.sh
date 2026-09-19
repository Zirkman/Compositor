#!/bin/zsh
# Builds Compositor for this Mac and installs it into /Applications.
#
# This is the counterpart to release.sh, which needs the upstream author's Developer ID and
# notarization credentials. This one signs ad hoc, so the app runs only on the Mac that built it —
# which is all a personal build needs.
#
# Run it after changing the code. No arguments.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP=Compositor
WORK="$HOME/Library/Caches/CompositorLocalBuild"
DEST="/Applications/$APP.app"

echo "==> Building Release for macOS $(sw_vers -productVersion)"
# CODE_SIGN_STYLE/DEVELOPMENT_TEAM: the project carries the upstream author's team, which no other
# Mac can sign with. "-" is an ad-hoc signature, the same one Xcode uses for a local Debug run.
# ENABLE_HARDENED_RUNTIME=NO is not optional: the hardened runtime turns on library validation,
# which accepts a bundled framework only from the same team — and an ad-hoc signature has no team.
# With it left on, the app builds and signs cleanly and then dies at launch on the bundled Sparkle
# framework with "different Team IDs".
xcodebuild -quiet \
  -project "$PROJECT_DIR/$APP.xcodeproj" -scheme "$APP" -configuration Release \
  -derivedDataPath "$WORK" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO

BUILT="$WORK/Build/Products/Release/$APP.app"
codesign --verify --deep --strict "$BUILT"

echo "==> Installing to $DEST"
# Ask it to quit rather than killing it, then give up instead of waiting forever: an unsaved
# document puts a save dialog on screen, and that is the user's to answer, not this script's.
if pgrep -qf "$DEST/Contents/MacOS/$APP"; then
  osascript -e "tell application \"$APP\" to quit" 2>/dev/null || true
  for _ in {1..10}; do
    pgrep -qf "$DEST/Contents/MacOS/$APP" || break
    sleep 1
  done
  if pgrep -qf "$DEST/Contents/MacOS/$APP"; then
    echo "$APP is still running - answer its save dialog, or quit it, then run this again." >&2
    exit 1
  fi
fi
rm -rf "$DEST"
cp -R "$BUILT" "$DEST"
xattr -cr "$DEST"

echo "==> Installed: $(defaults read "$DEST/Contents/Info" CFBundleShortVersionString) \
(build $(defaults read "$DEST/Contents/Info" CFBundleVersion)), minimum macOS \
$(defaults read "$DEST/Contents/Info" LSMinimumSystemVersion)"

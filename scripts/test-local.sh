#!/bin/zsh
# Runs the unit tests on this Mac. Same signing story as build-local.sh - read its header for why those flags
# are there. Pass a target to narrow the run, e.g.:
#
#   ./scripts/test-local.sh CompositorTests/SelectionEditTests
#
# Narrowing matters for anything that measures time: the full suite runs ~290 tests in parallel, and the
# biggest images in it take tens of times longer under that load than they do on their own.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-CompositorTests}"
WORK="$HOME/Library/Caches/CompositorLocalBuild"

# xcodebuild refuses to start at all if the bundle is already there, and its error looks like a test failure
# rather than a run that never happened - which is worse, because the stale bundle still reads as passing.
rm -rf "$WORK/TestResults.xcresult"

xcodebuild test -quiet \
  -project "$PROJECT_DIR/Compositor.xcodeproj" -scheme Compositor -configuration Debug \
  -derivedDataPath "$WORK" -destination 'platform=macOS' \
  -only-testing:"$TARGET" -resultBundlePath "$WORK/TestResults.xcresult" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO

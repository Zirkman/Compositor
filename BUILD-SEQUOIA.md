# This fork: Compositor on macOS 15 (Sequoia)

A fork of [robbietilton/Compositor](https://github.com/robbietilton/Compositor) that builds and runs
on macOS 15. Upstream ships for macOS 26 only (`MACOSX_DEPLOYMENT_TARGET = 26.5`, README:
"Requirements: macOS 26"), so a downloaded release refuses to open on Sequoia — Launch Services
rejects it on `LSMinimumSystemVersion`, and the loader would reject the binary's own `minos 26.5`.

Everything else is upstream. Add features here as normal commits; keep this file and
`scripts/build-local.sh` when merging upstream changes in.

## Build and install

    ./scripts/build-local.sh

Builds Release, signs it ad hoc and replaces `/Applications/Compositor.app`. Read the script's
header before changing its signing flags — two of them are load-bearing and the failure they
prevent looks like a build that succeeded.

Opening `Compositor.xcodeproj` in Xcode and pressing Run also works: the deployment target is set in
the project, and Xcode's Debug configuration already signs ad hoc without the hardened runtime.

## What this fork changes

| File | Change | Effect on macOS 15 |
|---|---|---|
| `Compositor.xcodeproj/project.pbxproj` | `MACOSX_DEPLOYMENT_TARGET` 26.5 → 15.0, in all four configurations | — |
| `Compositor/UI/BlendModePicker.swift` | `NSPopUpButton.borderShape` is macOS 26+, wrapped in `if #available` | the blend-mode pop-up is rectangular instead of a capsule |
| `Compositor/ContentView.swift` | `ToolbarSpacer` (macOS 26+) behind `if #available`; `.sharedBackgroundVisibility(.hidden)` removed; `body` split into `toolHeaders` + `editorToolbar` | toolbar spacing between the tab strip and the zoom controls is less precise |
| `Compositor/Document/ImageAdjustments.swift` | the gradient-map lookup table written out in explicit steps, same arithmetic | none — the two versions were compared byte for byte over five colour pairs, including out-of-range clamping |

The `body` split is not cosmetic. At deployment target 15.0 the SwiftUI overload set the type-checker
has to search grows, and it gives up on the original single-expression `body` with "unable to
type-check this expression in reasonable time". The same happened to the gradient-map table.

## Keeping up with upstream

    git fetch upstream
    git merge upstream/main

Merge rather than rebase: this fork's `main` is the branch the app is built from, so its history
should not be rewritten. Expect a conflict in `project.pbxproj` whenever upstream raises its
deployment target — keep 15.0.

Sparkle will not offer updates. The upstream appcast declares `minimumSystemVersion 26.5`, so a
macOS 15 install silently stays on whatever was built here. Watch the
[releases page](https://github.com/robbietilton/Compositor/releases) instead.

## Known upstream breakage

`xcodebuild test` does not compile, on `main` as well as here: `CompositorTests/LayerTests.swift`
calls `NativeLayerList.Coordinator.moveLayer`, which does not exist in the source. So the test suite
could not be used to verify this port, and cannot be used to verify changes made here until that is
fixed.

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

## Tests

    ./scripts/test-local.sh                                  # all 288
    ./scripts/test-local.sh CompositorTests/SelectionEditTests   # one suite

The suite did not compile on upstream `main` - three test files called API that no longer exists
(`NativeLayerList.Coordinator.moveLayer`, `SubjectRemoval.run` without its `settings:`,
`CanvasView.lassoCursors`), so nothing in it had been run for some time. It compiles and passes here.

Twelve tests failed once it ran. Two were real defects and are fixed in this fork:

- **Color Dodge and Color Burn rendered wrong.** Those two modes go through Core Image, which works in a
  linear space unless told otherwise, so over 40% grey an 80% grey layer dodged to 62% instead of
  Photoshop's 100% and burned to 0% instead of 25%. `SeparableBlend` now pins the working space to sRGB.
- **Levels corrupted semi-transparent pixels.** `LevelsFilter.run` divided each channel by its alpha and
  multiplied it back, and `levels_apply` in `LevelsPixels.c` already does exactly that - so a soft edge went
  through the conversion twice. The Swift loops are gone.

Both fixes were mutation-checked: putting either defect back turns its test red again.

The other ten were the tests themselves being out of date - the key that switches Lasso/Marquee kind was
removed from the product, blur stopped clamping at a layer's edge, moving a layer started snapping to the
canvas, Option over a thumbnail now offers to duplicate. One was not about the code at all: it built key
events from virtual key codes, so it measured whichever keyboard layout the machine had active and failed on
a Slovak one. Each is rewritten to the rule the source states, with a comment saying what it used to assert.

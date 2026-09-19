# This fork: Compositor on macOS 15 (Sequoia)

A fork of [robbietilton/Compositor](https://github.com/robbietilton/Compositor) that builds and runs
on macOS 15. Upstream ships for macOS 26 only (`MACOSX_DEPLOYMENT_TARGET = 26.5`, its README:
"Requirements: macOS 26"), so a downloaded release refuses to open on Sequoia: Launch Services
rejects it on `LSMinimumSystemVersion`, and the loader would reject the binary's own `minos 26.5`.

Beyond that it carries two rendering fixes and a test suite that runs again — see **What this fork
changes**. Add features here as normal commits; keep this file and `scripts/` when merging upstream
changes in.

## Build and install

    ./scripts/build-local.sh

Builds Release, signs it ad hoc and replaces `/Applications/Compositor.app`. Read the script's
header before changing its signing flags: two of them are load-bearing, and the failure they
prevent looks like a build that succeeded.

Opening `Compositor.xcodeproj` in Xcode and pressing Run also works. The deployment target is set in
the project, and Xcode's Debug configuration already signs ad hoc without the hardened runtime.

## Tests

    ./scripts/test-local.sh                                      # all 288
    ./scripts/test-local.sh CompositorTests/SelectionEditTests   # one suite

All 288 pass. Narrowing the run matters for anything that measures time: the full suite runs in
parallel, and its biggest images take tens of times longer under that load than on their own.

## What this fork changes

### Making it build and run on macOS 15

| File | Change | Effect on macOS 15 |
|---|---|---|
| `Compositor.xcodeproj/project.pbxproj` | `MACOSX_DEPLOYMENT_TARGET` 26.5 → 15.0, in all four configurations | — |
| `Compositor/UI/BlendModePicker.swift` | `NSPopUpButton.borderShape` is macOS 26+, wrapped in `if #available` | the blend-mode pop-up is rectangular instead of a capsule |
| `Compositor/ContentView.swift` | `ToolbarSpacer` (macOS 26+) behind `if #available`; `.sharedBackgroundVisibility(.hidden)` removed; `body` split into `toolHeaders` + `editorToolbar` | toolbar spacing between the tab strip and the zoom controls is less precise |
| `Compositor/Document/ImageAdjustments.swift` | the gradient-map lookup table written out in explicit steps, same arithmetic | none — the two versions were compared byte for byte over five colour pairs, including out-of-range clamping |

The `body` split is not cosmetic. At deployment target 15.0 the SwiftUI overload set the type-checker
has to search grows, and it gives up on the original single-expression `body` with "unable to
type-check this expression in reasonable time". The same happened to the gradient-map table.

### Two defects the tests found

Both are visible in the product, and both are mutation-checked: putting either one back turns its
test red again.

- **Color Dodge and Color Burn rendered wrong** (`Compositor/Rendering/SeparableBlend.swift`). Those
  two modes go through Core Image, which works in a linear space unless told otherwise. Over 40%
  grey, an 80% grey layer dodged to 62% instead of Photoshop's 100%, and burned to 0% instead of
  25%. The blend now happens in the sRGB the canvas is in.
- **Levels corrupted semi-transparent pixels** (`Compositor/Document/Levels.swift`). `LevelsFilter.run`
  divided each channel by its alpha and multiplied it back, and `levels_apply` in `LevelsPixels.c`
  already does exactly that, so every soft edge went through the conversion twice. The Swift loops
  are gone.

### The test suite

It did not compile on upstream `main`: three test files called API that no longer exists
(`NativeLayerList.Coordinator.moveLayer`, `SubjectRemoval.run` without its `settings:`,
`CanvasView.lassoCursors`), so nothing in it had been run for some time.

`NativeLayerList` gained `moveLayer(_:to:)` and `place(_:at:intoFolder:copying:)`. Reordering a
layer was only reachable through an `NSDraggingInfo`, which is what made its test uncompilable; the
drop handler now calls the same two methods.

Twelve tests failed once the suite ran. Two were the defects above. The other ten were the tests
themselves being out of date, and each is rewritten to the rule the source states, with a comment
recording what it used to assert:

- The `L` and `M` keys no longer switch Lasso mode and Marquee shape. The kind is set in the tool
  bar and the key only picks the tool (`Selection.swift`, `pressLassoKey` / `pressMarqueeKey`).
- A blur is no longer clamped at the layer's edge: the layer is given room, the blur spreads into
  it, and whatever stays empty is cut away (`Filters.swift`, `growForBlur`). The old assertions read
  fixed columns of an image whose size and origin both change.
- Moving a layer snaps to the canvas and to other layers within 10 points (`TransformSnap.distance`).
  A 20 × 10 drag from the middle of a 400 × 300 canvas lands inside that and springs back, so the
  drags now hold Control, which is what drags freely.
- Option over a layer's thumbnail offers to duplicate, like the rest of the row: the thumbnail hands
  Option straight back to the list (`NativeLayerList`, `LayerThumbnailButton.updateCursor`).
- The blend-mode list grew, so stepping back past Normal wraps to Luminosity, not Color Burn. The
  test names the claim now (`LayerBlendMode.allCases.last`) instead of spelling out a case.
- One failure was not about the code at all: the brush-hardness test built key events from virtual
  key codes, so it measured whichever keyboard layout the machine had active — on a Slovak layout,
  key 30 with Shift is `(`, not `}`. It spells the characters out now.
- One measured the machine rather than the code: a 1.5 s budget for inverting a 4000 × 3000 layer,
  which takes 0.5 s on its own and 60 s with ~290 other tests competing for the machine. The timing
  is gone and the correctness assertions stay; measure it with `-only-testing` when it matters.

## Keeping up with upstream

    git fetch upstream
    git merge upstream/main

Merge rather than rebase: this fork's `main` is the branch the app is built from, so its history
should not be rewritten. Expect a conflict in `project.pbxproj` whenever upstream raises its
deployment target — keep 15.0.

Sparkle will not offer updates. The upstream appcast declares `minimumSystemVersion 26.5`, so a
macOS 15 install silently stays on whatever was built here. Watch the
[releases page](https://github.com/robbietilton/Compositor/releases) instead.

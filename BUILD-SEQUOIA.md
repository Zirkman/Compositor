# This fork: Compositor on macOS 15 (Sequoia)

A fork of [robbietilton/Compositor](https://github.com/robbietilton/Compositor) that builds and runs
on macOS 15. It tracks upstream's **1.1.8**.

Upstream ships for macOS 26 only (`MACOSX_DEPLOYMENT_TARGET = 26.5`, its README: "Requirements:
macOS 26"), so a downloaded release refuses to open on Sequoia: Launch Services rejects it on
`LSMinimumSystemVersion`, and the loader would reject the binary's own `minos 26.5`.

That is the whole reason this fork exists. Four files differ from upstream, all of them saying "do
the macOS 26 thing when you can". Add features here as normal commits; keep this file, `README.md`
and `scripts/` when merging upstream changes in.

## Build and install

    ./scripts/build-local.sh

Builds Release, signs it ad hoc and replaces `/Applications/Compositor.app`. Read the script's
header before changing its signing flags: two of them are load-bearing, and the failure they
prevent looks like a build that succeeded.

Opening `Compositor.xcodeproj` in Xcode and pressing Run also works. The deployment target is set in
the project, and Xcode's Debug configuration already signs ad hoc without the hardened runtime.

## Tests

    ./scripts/test-local.sh                                      # all 329
    ./scripts/test-local.sh CompositorTests/SelectionEditTests   # one suite

327 of 329 pass. The two that fail are `DistortTests` and have nothing to do with macOS 15 — they
fail on upstream too, and the maintainer has them open: `DistortWarp.isUsable` accepts a bowtie
quadrilateral the test expects it to refuse, and a distort corner lands at (30, 30) where the test
wants (30, 10).

Narrowing the run matters for anything that measures time: the full suite runs in parallel, and its
biggest images take tens of times longer under that load than on their own.

## What this fork changes

| File | Change | Effect on macOS 15 |
|---|---|---|
| `Compositor.xcodeproj/project.pbxproj` | `MACOSX_DEPLOYMENT_TARGET` 26.5 → 15.0, in all four configurations | — |
| `Compositor/UI/BlendModePicker.swift` | `NSPopUpButton.borderShape` is macOS 26+, behind `if #available` | the blend-mode pop-up is rectangular instead of a capsule |
| `Compositor/UI/TypeControls.swift` | the same, for the Type tool's font pop-up | the font pop-up is rectangular instead of a capsule |
| `Compositor/ContentView.swift` | `ToolbarSpacer` and `.sharedBackgroundVisibility(.hidden)` (both macOS 26+) behind `if #available`, with the tab-strip item built by one `tabStrip(_:)` helper both branches call | toolbar spacing between the tab strip and the zoom controls is less precise |

On macOS 26 none of this changes anything: every 26-only call is still made there, on the same
items, in the same order.

## What used to be here and is upstream now

This fork carried more than the deployment target. All of it was merged upstream in
[#34](https://github.com/robbietilton/Compositor/pull/34) and is no longer a difference:

- **Color Dodge and Color Burn rendered wrong.** Both go through Core Image, which works in a linear
  space unless told otherwise. Over 40% grey, an 80% grey layer dodged to 62% instead of Photoshop's
  100%, and burned to 0% instead of 25%.
- **Levels corrupted semi-transparent pixels.** `LevelsFilter.run` divided each channel by its alpha
  and multiplied it back, which `levels_apply` in `LevelsPixels.c` already does, so every soft edge
  went through the conversion twice.
- **The test suite did not compile**, so nothing in it had been run for some time, and ten of its
  tests were asserting rules the app had already moved on from.

Upstream also fixed the two Swift type-checker timeouts that used to be carried here
([#24](https://github.com/robbietilton/Compositor/pull/24)), so `ContentView.body` and the
gradient-map table are upstream's versions now, not this fork's.

## Keeping up with upstream

    git fetch upstream
    git merge upstream/main

Merge rather than rebase: this fork's `main` is the branch the app is built from, so its history
should not be rewritten.

Two things to expect every time:

- **A conflict in `project.pbxproj` on the deployment target.** Keep 15.0.
- **A new macOS 26 API somewhere.** A new feature upstream can bring one in, and nothing warns you
  — the build simply fails with *"is only available in macOS 26.0 or newer"*. That is how
  `TypeControls` arrived with the Type tool. Build, read the error, guard it, build again. Resolve
  every other conflict in upstream's favour: this fork should differ only where macOS 15 forces it,
  and anything else is a cost paid again at every merge.

[#8](https://github.com/robbietilton/Compositor/pull/8) proposes the same macOS 15 support upstream.
If it is merged, this fork's reason to exist mostly goes away and merging becomes routine.

Sparkle will not offer updates. The upstream appcast declares a `minimumSystemVersion` taken from
upstream's own deployment target, so a macOS 15 install silently stays on whatever was built here.
Watch the [releases page](https://github.com/robbietilton/Compositor/releases) instead.

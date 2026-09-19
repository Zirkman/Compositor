# Building Compositor on macOS 15 (Sequoia)

Upstream ships for macOS 26 (`MACOSX_DEPLOYMENT_TARGET = 26.5`, README: "Requirements: macOS 26").
Branch `sequoia-15` lowers that to 15.0. Three source changes were needed; everything else compiles
unchanged.

| File | Change | Effect on macOS 15 |
|---|---|---|
| `Compositor/UI/BlendModePicker.swift` | `NSPopUpButton.borderShape` is macOS 26+, wrapped in `if #available` | blend-mode pop-up is rectangular instead of a capsule |
| `Compositor/ContentView.swift` | `ToolbarSpacer` (macOS 26+) behind `if #available`; `.sharedBackgroundVisibility(.hidden)` removed; body split into `toolHeaders` + `editorToolbar` so the type-checker finishes | toolbar spacing between the tab strip and the zoom controls is less precise |
| `Compositor/Document/ImageAdjustments.swift` | gradient-map lookup table written out in explicit steps (same arithmetic) | none — verified byte-identical against the original expression |

The body split is not cosmetic: at deployment target 15.0 the SwiftUI overload set grows and the
solver gives up on the original single-expression `body`.

## Build

    xcodebuild -project Compositor.xcodeproj -scheme Compositor -configuration Release \
      -derivedDataPath build MACOSX_DEPLOYMENT_TARGET=15.0 \
      CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build

    sed 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.wonderassembly.compositor/g' \
      Config/Compositor.entitlements > /tmp/compositor-ent.plist
    codesign --force --deep --sign - --entitlements /tmp/compositor-ent.plist \
      build/Build/Products/Release/Compositor.app

Sign **without** `--options runtime`. The hardened runtime turns on library validation, which an
ad-hoc signature cannot satisfy for the bundled Sparkle framework — the app then dies at launch with
"different Team IDs".

## Updating to a new upstream release

    git fetch origin && git rebase origin/main

Sparkle will not offer updates by itself: the appcast declares `minimumSystemVersion 26.5`, so a
macOS 15 install silently stays on this build. Check the releases page manually.

## Known upstream breakage (not caused by this branch)

`xcodebuild test` does not compile: `CompositorTests/LayerTests.swift` calls
`NativeLayerList.Coordinator.moveLayer`, which does not exist in the source. The test target is
broken on `main` too, so the suite could not be used to verify this port.

# Compositor

> ### This is a fork
>
> Forked from [robbietilton/Compositor](https://github.com/robbietilton/Compositor) at **1.0.4**.
> The app described below is his. Here is what is different.
>
> **It runs on macOS 15 (Sequoia).** Upstream builds for macOS 26 only, so a downloaded release
> will not open on anything older — the system refuses it before it starts.
>
> **Color Dodge and Color Burn render correctly.** Both go through Core Image, which works in a
> linear color space unless told otherwise, so they came out nowhere near what Photoshop does:
> over 40% grey, an 80% grey layer dodged to 62% instead of 100%, and burned to 0% instead of 25%.
>
> **Levels no longer corrupts semi-transparent pixels.** It divided each channel by its alpha and
> multiplied it back, which the C routine underneath already does, so every soft edge went through
> the conversion twice and came out too dark.
>
> Both fixes came out of the test suite, which did not compile upstream and so had not been run for
> some time. It compiles here: 288 tests, all passing, `./scripts/test-local.sh`. Ten of them were
> asserting rules the app had already moved on from and are rewritten to what the source says today.
>
> No feature is added or removed. The only other change to the app itself is a refactor that made
> reordering a layer reachable from a test. What each change is and why:
> **[BUILD-SEQUOIA.md](BUILD-SEQUOIA.md)**.

Adobe Photoshop costs too much and tools like GIMP don’t feel familiar enough for me to stay in flow. That’s why I built Compositor.

The goal was to create a full-featured image editor that is completely free and open source. I use Photoshop for compositing and post-processing, so Compositor is built around that workflow - with the tools needed to create a pixel-perfect final image.

Because it’s open source, you can download the Xcode project and add, remove, or modify any feature to fit your workflow.

## Features

### Layers
- Layers and folders, with blend modes and opacity
- Layer masks: paint, fill, invert, blur and feather them; link or unlink them to transform a mask on its own
- Clipping masks and folder masks
- Adjustment layers: Hue/Saturation, Levels, Curves, Exposure, Gradient Map and Grain
- Merge Down, Merge Layers and Merge Group (⌘E)
- Duplicate, rename inline, reorder and nest by drag and drop; Option-drag to duplicate
- Drag layers between open projects

### Transform
- Non-destructive move, scale, rotate and flip — images keep their full resolution however small you make them
- Free distort (⌘-drag a handle), with Shift to lock to an axis
- Transform several layers, or a whole folder, together
- Snapping to canvas and layer edges and centers, with guides
- Exact values for position, size, scale and angle, stepped with the arrow keys
- Flip Layer and Flip Canvas, horizontal and vertical

### Selections
- Rectangle and Ellipse Marquee, Freehand and Polygonal Lasso, and Magic Wand
- Add to and subtract from selections, move the outline, or move and duplicate the pixels inside
- Load a layer's pixels or a mask as a selection
- Content-Aware Fill, which can also extend an image past its edges

### Painting and retouching
- Brush with size, hardness and opacity, and Shift for straight lines
- Spot Healing Brush (content-aware)
- Clone Stamp, aligned or not, sampling one layer or all of them
- Blur tool, on pixels or masks
- Gradient tool and Shape tool (rectangles, rounded rectangles and ellipses)
- Type tool (T): inline multiline editing in draggable, resizable paragraph boxes; font, size, color, alignment and spacing in the tool header; transform text and use it as a clipping mask
- Eyedropper and a full color picker

### Adjustments and filters
- Levels (with Auto), Curves, Hue/Saturation, Exposure, Gradient Map, Grain and Invert
- Gaussian Blur and Motion Blur that spread past a layer's edges
- Add Noise, Lens Correction and Remove Background
- Live previews, limited to the selection when there is one

### Canvas and files
- Multiple projects in tabs
- Crop with snapping, and Option for symmetric cropping
- Canvas Size and Image Size
- Sharp high-quality downsampling when zoomed out, and a pixel grid when zoomed in
- Import JPEG, PNG, HEIC, TIFF and Photoshop PSD (8-bit RGB only; not PSB or CMYK). PSD folders, masks, a subset of blend modes, and fill rectangles/ellipses stay editable; text and other vectors become pixels. A conversion report is shown before anything is applied.
- Export JPEG with a live preview (⇧⌥⌘S); Copy Merged
- Photoshop-style keyboard shortcuts throughout

## Requirements

- macOS 15 or later
- Xcode 26 (to build from source)

## Building

Open `Compositor.xcodeproj` and run the **Compositor** scheme, or `./scripts/build-local.sh` to
build and install into `/Applications`. `./scripts/test-local.sh` runs the tests.

## Releasing

This is upstream's path to a DMG other people can open, and it is signed with upstream's developer
account. A build for your own Mac needs none of it — use `./scripts/build-local.sh`.

`scripts/release.sh` builds a Release version, signs it with Developer ID, notarizes and staples it, and packages it into `dist/Compositor-<version>.dmg`.

It needs, all kept outside this repository:

- a **Developer ID Application** certificate in the login keychain
- notarization credentials saved with `xcrun notarytool store-credentials "compositor-notary" …`
- [`create-dmg`](https://github.com/create-dmg/create-dmg) (`brew install create-dmg`)

## License

MIT — see [LICENSE](LICENSE).

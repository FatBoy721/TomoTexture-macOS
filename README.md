# TomoTexture for macOS (Unofficial Community Port)

> ## ⚠️ Read this first
>
> This is an **unofficial community port** of [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture).
>
> [@AlfonsoMallozzi](https://github.com/AlfonsoMallozzi) is releasing an **official macOS build** of his own — see [issue #31 on the upstream repo](https://github.com/AlfonsoMallozzi/TomoTexture/issues/31). **If you can wait, use his official release** when it drops. It will be the canonical Mac build going forward.
>
> This repo exists for folks who want a working Mac DMG right now. Built using the public permission Alfonso granted in v1.0 to decompile the Windows .exe.

A native macOS port of [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture), the save-canvas editor for **Tomodachi Life**. Edit the textures players paint inside the game — food, goods, face paint, signs, and more — by replacing the canvas images in your Ryujinx save folder.

---

## Install

1. Download the latest [`TomoTexture-<arch>.dmg`](https://github.com/FatBoy721/TomoTexture-macOS/releases/latest).
2. Open the DMG.
3. Drag **TomoTexture** onto **Applications**.
4. Eject the DMG.

### First launch

The app isn't notarized by Apple (that requires a paid developer account), so macOS will warn you on first open. To get past it:

- **Right-click** `TomoTexture.app` in Applications → **Open** → **Open** in the dialog.

If macOS still refuses with "is damaged", run this once in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/TomoTexture.app
```

After that it launches normally.

---

## Usage

1. Launch TomoTexture.
2. Click **Browse** and pick your Ryujinx save folder. The app auto-detects the default Ryujinx path on macOS.
3. Pick a canvas from the list — its current texture shows up on the right.
4. Click **Replace** and choose a new image (PNG, JPG, WebP, GIF, BMP, or TIFF).
5. The original is backed up as `.bak` next to the canvas. Hit **Revert** to restore it.

> **Tip for stickers/decals:** use a transparent-background PNG so the canvas blends correctly. [remove.bg](https://www.remove.bg) is a fast way to strip backgrounds.

---

## Run from source

Works on both Apple Silicon and Intel Macs. Requires Python 3.10+ with Tkinter (`brew install python-tk@3.12` on Homebrew, or use python.org's installer).

```bash
git clone https://github.com/FatBoy721/TomoTexture-macOS.git
cd TomoTexture-macOS

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

---

## Build the DMG yourself

```bash
./build.sh                   # build for the host arch
ARCH=x86_64 ./build.sh       # Intel build (also runs on Apple Silicon via Rosetta)
ARCH=arm64 ./build.sh        # Apple Silicon native
ARCH=universal2 ./build.sh   # fat binary (requires universal2 Python + wheels)
```

Outputs land in `dist/`:
- `TomoTexture.app` — the bundled application
- `TomoTexture-<arch>.dmg` — the drag-to-Applications installer

The script handles everything: build venv, dependencies, `.icns` icon generation, PyInstaller bundling, ad-hoc codesigning, and DMG packaging.

### Which arch should I build?

| Goal | Arch |
| --- | --- |
| One DMG that works for everyone | `x86_64` (native on Intel, runs via Rosetta on Apple Silicon) |
| Smallest, fastest on Apple Silicon | `arm64` |
| Native on both, single download | `universal2` (needs python.org universal2 Python) |

---

## How it works

1. Reads `Ugc*.canvas.zs` files from the Ryujinx save folder.
2. Decompresses (zstd), deswizzles, and decodes the texture into an editable image.
3. Replaces it with your image — non-RGBA images are converted to RGBA in memory.
4. Re-encodes, re-swizzles, recompresses, and writes the canvas plus its companion files (`.ugctex.zs`, `_Thumb.ugctex.zs`).

Supported canvas types: `Food`, `Goods`, `FacePaint`, `Sign`, `Exterior`, `Interior`, `MapObject`, `MapFloor`, plus a generic catch-all for unknown `Ugc*` types.

---

## Credits

- **[@AlfonsoMallozzi](https://github.com/AlfonsoMallozzi)** — original [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture) tool and the public permission that made this community port possible.

---

## Disclaimer

**Always back up your save folder before editing.** TomoTexture creates `.bak` files automatically when you replace a canvas, but a clean external backup costs nothing.

This is an **unofficial community macOS port**. The official Windows build (and the upcoming official macOS build) live on the [upstream repo](https://github.com/AlfonsoMallozzi/TomoTexture).

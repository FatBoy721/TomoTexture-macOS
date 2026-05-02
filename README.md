# TomoTexture for macOS

macOS build of [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture), made with permission from the original project.

## Download

Get the latest DMG from [Releases](https://github.com/FatBoy721/TomoTexture-macOS/releases/latest).

Open the DMG, then drag **TomoTexture** into **Applications**.

## First Launch

Because this app is not Apple-notarized, right-click **TomoTexture.app** and choose **Open** the first time.

If macOS says the app is damaged, run:

```bash
xattr -dr com.apple.quarantine /Applications/TomoTexture.app
```

## Run From Source

```bash
git clone https://github.com/FatBoy721/TomoTexture-macOS.git
cd TomoTexture-macOS
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

## Notes

- Always back up your save before editing.
- v1.0.1 improves game texture color handling and preview color matching.

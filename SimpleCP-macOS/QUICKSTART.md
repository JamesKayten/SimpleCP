# SimpleCP macOS - Quick Start Guide

Get SimpleCP up and running in under 5 minutes!

## Quick Build & Run

### Option 1: Command Line (Fastest)

```bash
# Navigate to the project
cd SimpleCP-macOS

# Run the app
swift run
```

That's it! The app will build and launch automatically.

### Option 2: Xcode

```bash
# Open in Xcode
cd SimpleCP-macOS
open Package.swift
```

Then press `⌘R` to build and run.

## First Launch

When you first launch SimpleCP:

1. **Menu Bar Icon**: Look for the 📋 icon in your macOS menu bar (top-right)
2. **Click the Icon**: A 600x400 window will appear
3. **Grant Permissions**: If prompted, grant accessibility permissions in System Settings

## Basic Usage

### Copy Some Text
1. Copy text from any app (⌘C)
2. It automatically appears in the "Recent Clips" column

### Save a Snippet
1. Copy text you want to save
2. Click "Save as Snippet" button
3. Enter a name and select a folder
4. Click "Save Snippet"

### Reuse Clipboard History
1. Click any item in "Recent Clips"
2. It's copied to your clipboard
3. Paste anywhere (⌘V)

### Create Folders
1. Click "Manage Folders" dropdown
2. Select "Create Folder..."
3. Enter a folder name
4. Organize your snippets!

### Search Everything
1. Type in the search bar at the top
2. Both clips and snippets filter in real-time
3. Find what you need instantly

## Tips & Tricks

- **Quick Copy**: Just click any clip or snippet to copy it
- **Right-Click Menus**: Right-click for more options
- **Expand/Collapse**: Click folders to show/hide contents
- **Settings**: Click the gear icon (⚙️) to customize
- **Quit**: Click the X button or quit from menu bar

## What to Test First

1. ✅ Copy 3-5 different pieces of text
2. ✅ Click them to copy back to clipboard
3. ✅ Save one as a snippet
4. ✅ Create a new folder
5. ✅ Search for something
6. ✅ Open settings and look around

## Common Issues

**Can't find the menu bar icon?**
- Look in the top-right of your screen
- It's a clipboard icon: 📋

**Clipboard not updating?**
- Grant accessibility permissions:
- System Settings → Privacy & Security → Accessibility
- Add SimpleCP and toggle on

**App won't build?**
- Ensure you have Xcode 15.0+
- Ensure macOS 13.0+
- Run: `swift --version` to check Swift version

## Next Steps

Once comfortable with basics:

1. Read the full [README.md](README.md)
2. Review [UI Specification](../docs/UI_UX_SPECIFICATION_v3.md)
3. Customize settings to your preference
4. Set up folders for your workflow
5. Export/import snippets to backup

## Support

Need help?
- Check [README.md](README.md) for detailed documentation
- Review the troubleshooting section
- Create an issue on GitHub

Enjoy SimpleCP! 🎉

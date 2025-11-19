# SimpleCP macOS MenuBar App

A modern, elegant clipboard manager for macOS with snippet management capabilities.

## Features

- **MenuBar Integration**: Lives in your macOS menu bar for quick access
- **Two-Column Interface**: Recent clips on the left, saved snippets on the right
- **Smart Search**: Real-time filtering across both clips and snippets
- **Snippet Management**: Save frequently-used content with folders and tags
- **Customizable**: Settings for appearance, behavior, and shortcuts
- **Lightweight**: 600x400 window, minimal resource usage

## Architecture

### Project Structure

```
SimpleCP-macOS/
├── Sources/
│   └── SimpleCP/
│       ├── SimpleCPApp.swift           # Main app with MenuBarExtra
│       ├── Models/
│       │   ├── ClipItem.swift          # Clipboard item model
│       │   ├── Snippet.swift           # Snippet model
│       │   └── SnippetFolder.swift     # Folder model
│       ├── Managers/
│       │   └── ClipboardManager.swift  # Core clipboard & snippet logic
│       ├── Views/
│       │   ├── ContentView.swift       # Main two-column view
│       │   └── SettingsWindow.swift    # Settings with tabs
│       └── Components/
│           ├── RecentClipsColumn.swift        # Left column
│           ├── SavedSnippetsColumn.swift      # Right column
│           └── SaveSnippetDialog.swift        # Save workflow dialog
├── Resources/
│   └── Info.plist
├── Package.swift
└── README.md
```

### Key Components

#### SimpleCPApp.swift
- Main app entry point using `@main`
- MenuBarExtra with 600x400 window
- Settings window management

#### ClipboardManager
- ObservableObject for reactive UI updates
- Monitors clipboard every 0.5 seconds
- Manages history (default: 50 items)
- Handles snippet CRUD operations
- Folder management
- Search functionality
- UserDefaults persistence

#### ContentView
- Header bar with title and settings
- Always-visible search bar
- Control bar with snippet actions
- HSplitView for two columns
- Export/import functionality

#### RecentClipsColumn
- Displays 10 most recent clips
- Grouped history (11-20, 21-30, etc.)
- Hover actions (save, delete)
- Context menu
- Quick copy on tap

#### SavedSnippetsColumn
- Expandable/collapsible folders
- Snippet items with tags
- Hover actions (edit, delete)
- Context menu with operations
- Quick add to folder

## Build Instructions

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Option 1: Build with Swift Package Manager (Command Line)

```bash
cd SimpleCP-macOS

# Build the app
swift build -c release

# Run the app
swift run
```

### Option 2: Build with Xcode

1. **Open in Xcode**:
   ```bash
   cd SimpleCP-macOS
   open Package.swift
   ```

2. **Set Signing & Capabilities**:
   - Select the "SimpleCP" target
   - Go to "Signing & Capabilities"
   - Select your development team
   - Ensure "Automatically manage signing" is checked

3. **Build**:
   - Select "My Mac" as the destination
   - Press ⌘B to build
   - Press ⌘R to run

### Option 3: Create Xcode Project

If you prefer a full Xcode project instead of SPM:

1. **Create new Xcode project**:
   - Open Xcode
   - File → New → Project
   - Choose "macOS" → "App"
   - Product Name: "SimpleCP"
   - Interface: SwiftUI
   - Life Cycle: SwiftUI App

2. **Copy source files**:
   - Copy all files from `Sources/SimpleCP/` to the new project
   - Maintain the folder structure

3. **Update Info.plist**:
   - Add `LSUIElement` = `true` (makes it menu bar only app)

4. **Build and run**

## Testing Instructions

### Manual Testing Checklist

#### 1. Clipboard Monitoring
- [ ] Copy text from any app
- [ ] Verify it appears in Recent Clips within 1 second
- [ ] Copy multiple items
- [ ] Verify they appear in order (newest first)

#### 2. Recent Clips Functionality
- [ ] Click a clip item
- [ ] Verify it copies to clipboard
- [ ] Hover over clip
- [ ] Verify save and delete buttons appear
- [ ] Right-click clip
- [ ] Verify context menu appears
- [ ] Test "Remove from History"

#### 3. Save as Snippet
- [ ] Click "Save as Snippet" button
- [ ] Verify dialog opens with current clipboard
- [ ] Verify suggested name is auto-filled
- [ ] Change snippet name
- [ ] Select a folder
- [ ] Add tags (e.g., "test, demo")
- [ ] Click "Save Snippet"
- [ ] Verify snippet appears in selected folder

#### 4. Create New Folder
- [ ] Click "Manage Folders" → "Create Folder"
- [ ] Enter folder name
- [ ] Click "Create"
- [ ] Verify folder appears in right column

#### 5. Folder Operations
- [ ] Click folder to expand/collapse
- [ ] Right-click folder
- [ ] Test "Rename Folder"
- [ ] Test "Change Icon"
- [ ] Test "Delete Folder"

#### 6. Snippet Operations
- [ ] Click snippet to copy
- [ ] Paste in another app to verify
- [ ] Hover over snippet
- [ ] Click edit button
- [ ] Modify content and save
- [ ] Right-click snippet
- [ ] Test "Duplicate"
- [ ] Test "Delete"

#### 7. Search Functionality
- [ ] Type in search bar
- [ ] Verify both columns filter in real-time
- [ ] Verify matching items are shown
- [ ] Clear search
- [ ] Verify all items return

#### 8. Settings Window
- [ ] Click gear icon
- [ ] Switch between tabs
- [ ] Modify settings
- [ ] Close and reopen
- [ ] Verify settings persist

#### 9. Clear History
- [ ] Click "Clear History"
- [ ] Confirm dialog
- [ ] Verify all clips removed
- [ ] Verify snippets remain

#### 10. Export/Import
- [ ] Click export button
- [ ] Save snippets to file
- [ ] Click import button
- [ ] Load snippets from file
- [ ] Verify snippets imported correctly

### Performance Testing

- [ ] Add 50+ clips to history
- [ ] Verify scroll performance
- [ ] Verify search is responsive
- [ ] Check memory usage (Activity Monitor)
- [ ] Verify no memory leaks after extended use

### Edge Cases

- [ ] Empty clipboard
- [ ] Very long text (1000+ chars)
- [ ] Special characters (emoji, unicode)
- [ ] Code with indentation
- [ ] Multiline content
- [ ] Duplicate content
- [ ] Empty folder
- [ ] Folder with many snippets (20+)
- [ ] Search with no results
- [ ] Invalid import file

## Known Limitations

1. **Clipboard Format**: Currently only supports plain text (no images or rich text)
2. **Global Shortcuts**: Keyboard shortcut customization UI is placeholder (needs implementation)
3. **Launch at Login**: Toggle exists but requires LaunchAgent configuration
4. **Drag & Drop**: Not yet implemented (planned feature)

## Troubleshooting

### App doesn't appear in menu bar
- Check that `LSUIElement` is set to `true` in Info.plist
- Verify the app is running (check Activity Monitor)
- Try restarting the app

### Clipboard not monitoring
- Grant accessibility permissions in System Settings
- System Settings → Privacy & Security → Accessibility
- Add SimpleCP and toggle on

### Settings not persisting
- Check UserDefaults are not being cleared
- Verify app bundle identifier is correct
- Check Console.app for errors

### Build errors
- Ensure macOS 13.0+ SDK
- Clean build folder (⌘⇧K)
- Update Xcode to latest version
- Verify Swift version: `swift --version`

## Development

### Adding New Features

1. **Models**: Add to `Sources/SimpleCP/Models/`
2. **Views**: Add to `Sources/SimpleCP/Views/`
3. **Components**: Add to `Sources/SimpleCP/Components/`
4. **Managers**: Add to `Sources/SimpleCP/Managers/`

### Code Style

- SwiftUI for all UI components
- Combine for reactive programming
- @Published for state management
- UserDefaults for persistence
- Codable for data serialization

### Future Enhancements

- [ ] Drag & drop from Recent to Folders
- [ ] Rich text and image support
- [ ] iCloud sync
- [ ] Global keyboard shortcuts
- [ ] Quick paste menu (⌘⌥V)
- [ ] Snippet templates with variables
- [ ] Smart name suggestions with ML
- [ ] Folder organization (drag to reorder)
- [ ] Tags autocomplete
- [ ] Search with regex
- [ ] Export to various formats (JSON, CSV, Markdown)

## References

- UI Specification: `docs/UI_UX_SPECIFICATION_v3.md`
- SwiftUI Documentation: https://developer.apple.com/documentation/swiftui
- MenuBarExtra: https://developer.apple.com/documentation/swiftui/menubarextra

## License

MIT License - See LICENSE file for details

## Support

For issues, feature requests, or questions:
- Create an issue in the GitHub repository
- Email: support@simplecp.app

---

**Version**: 1.0.0
**Last Updated**: 2025-01-19
**Platform**: macOS 13.0+
>>>>>>> origin/claude/rebuild-simplecp-menubar-01X3Nab4kGXoNuEXbi8LuRu5

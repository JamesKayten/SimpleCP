# SimpleCP - Swift Frontend

Complete macOS Swift frontend for the SimpleCP clipboard manager, built to integrate with the Python backend.

## Project Overview

This is a fully functional SwiftUI application that provides a two-column interface for managing clipboard history and snippets. The frontend communicates with the Python backend via REST API.

## Architecture

### Directory Structure

```
SimpleCP.xcodeproj/          # Xcode project configuration
SimpleCP/
├── App/                      # Application entry points
│   ├── SimpleCPApp.swift    # Main app structure
│   ├── ContentView.swift    # Root view with two-column layout
│   └── AppDelegate.swift    # App lifecycle management
├── Models/                   # Data models matching Python backend
│   ├── ClipboardItem.swift  # Clipboard item model
│   ├── APIModels.swift      # Request/response models
│   ├── SnippetFolder.swift  # Folder organization
│   └── AppState.swift       # Observable app state
├── Services/                 # Backend integration layer
│   ├── APIClient.swift      # HTTP client for all API calls
│   ├── ClipboardService.swift   # Clipboard operations
│   ├── SnippetService.swift     # Snippet CRUD operations
│   └── SearchService.swift      # Search functionality
├── Views/
│   ├── Components/          # Reusable UI components
│   │   ├── HeaderView.swift
│   │   ├── SearchBar.swift
│   │   ├── ControlBar.swift
│   │   └── SettingsWindow.swift
│   ├── History/             # Left column - clipboard history
│   │   ├── HistoryColumnView.swift
│   │   ├── HistoryItemView.swift
│   │   └── HistoryFolderView.swift
│   ├── Snippets/            # Right column - saved snippets
│   │   ├── SnippetsColumnView.swift
│   │   ├── SnippetFolderView.swift
│   │   ├── SnippetItemView.swift
│   │   └── SaveSnippetDialog.swift
│   └── Shared/              # Shared views
│       ├── LoadingView.swift
│       └── ErrorView.swift
├── Utils/                   # Utility functions
│   ├── DateUtils.swift
│   ├── StringUtils.swift
│   └── Constants.swift
└── Resources/               # Assets and configuration
    ├── Assets.xcassets
    └── Info.plist
SimpleCP.entitlements        # macOS app permissions
```

## Features Implemented

### Core Functionality
- ✅ Complete API client for all backend endpoints
- ✅ Two-column layout (History | Snippets)
- ✅ Real-time data synchronization with backend
- ✅ Search across history and snippets
- ✅ Error handling and loading states

### History Column (Left Side)
- ✅ Display recent clipboard items (top 10)
- ✅ Auto-generated history folders (11-20, 21-30, etc.)
- ✅ Click to copy functionality
- ✅ Delete individual items
- ✅ Clear all history
- ✅ Hover actions (copy, save, delete)

### Snippets Column (Right Side)
- ✅ Expandable folder structure
- ✅ Create, rename, delete folders
- ✅ Save clipboard items as snippets
- ✅ Complete snippet save workflow with:
  - Smart name suggestions
  - Folder selection or creation
  - Tag support
  - Content preview
- ✅ Delete snippets
- ✅ Copy snippets to clipboard

### Additional Features
- ✅ Always-visible search bar
- ✅ Settings window with backend health check
- ✅ Keyboard shortcuts
- ✅ macOS native UI patterns

## API Integration

The Swift frontend connects to the Python backend at `http://127.0.0.1:8000` and implements all REST endpoints:

### History Endpoints
- `GET /api/history` - Get recent clipboard items
- `GET /api/history/folders` - Get auto-generated folders
- `DELETE /api/history/{item_id}` - Delete history item
- `POST /api/history/clear` - Clear all history

### Snippet Endpoints
- `GET /api/snippets` - Get all snippet folders
- `POST /api/snippets` - Create new snippet
- `PUT /api/snippets/{folder}/{item_id}` - Update snippet
- `DELETE /api/snippets/{folder}/{item_id}` - Delete snippet

### Folder Endpoints
- `POST /api/folders` - Create folder
- `PUT /api/folders/rename` - Rename folder
- `DELETE /api/folders/{name}` - Delete folder

### Operations
- `POST /api/clipboard/copy` - Copy item to clipboard
- `GET /api/search?query={query}` - Search across all items
- `GET /api/health` - Backend health check

## Building and Running

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Python backend running on `http://127.0.0.1:8000`

### Steps to Build

1. **Ensure Python Backend is Running**
   ```bash
   # In the project root
   cd /home/user/SimpleCP
   python3 -m uvicorn api.main:app --reload
   ```

2. **Open Xcode Project**
   ```bash
   open SimpleCP.xcodeproj
   ```

3. **Build and Run**
   - Select "SimpleCP" scheme in Xcode
   - Choose your Mac as the build target
   - Press Cmd+R to build and run
   - Or use Product → Run from the menu

### Alternative: Command Line Build
```bash
cd /home/user/SimpleCP
xcodebuild -project SimpleCP.xcodeproj -scheme SimpleCP -configuration Debug
```

## Data Models

All Swift models exactly match the Python backend models:

### ClipboardItem
```swift
struct ClipboardItem {
    let clipId: String
    let content: String
    let contentType: String
    let timestamp: Date
    let displayString: String
    let sourceApp: String?
    let itemType: String
    let hasName: Bool
    let snippetName: String?
    let folderPath: String?
    let tags: [String]
}
```

## State Management

The app uses `@StateObject` and `@EnvironmentObject` for state management:

- **AppState**: Central observable state for UI
- **APIClient**: HTTP client shared across services
- **Services**: Business logic layer (Clipboard, Snippet, Search)

## Error Handling

Comprehensive error handling is implemented throughout:
- Network failures display error dialogs
- Loading states show progress indicators
- Invalid responses are caught and reported
- User actions can be retried on failure

## Testing with Backend

To test the complete integration:

1. **Start the Python backend** (should already be running and tested)
2. **Run the Swift app** in Xcode
3. **Verify basic operations:**
   - History items load from backend
   - Search works across both columns
   - Saving snippets creates them in backend
   - Click to copy functionality works
   - Folder management works (create, rename, delete)

## Known Limitations

These items are intentionally left for local Claude to polish:

- Visual styling is functional but minimal
- No animations or transitions
- Basic macOS native styling only
- Window management is simple
- Menu bar integration is basic

## Next Steps for Local Development

The frontend is fully functional and ready for:

1. **Visual Polish** - Colors, fonts, spacing, animations
2. **Advanced UI** - Custom controls, better layouts
3. **Menu Bar** - Native macOS menu integration
4. **Keyboard Shortcuts** - More comprehensive shortcuts
5. **Preferences** - Extended settings and configuration

## Development Notes

### Code Organization
- Services handle all API communication
- Views are purely presentational
- State is managed centrally in AppState
- Models match backend exactly for seamless serialization

### Performance
- Async/await for all network calls
- MainActor isolation for UI updates
- Efficient list rendering with SwiftUI

### Security
- App Sandbox enabled
- Network client permission granted
- No unnecessary entitlements

## Support

For issues or questions about the Swift frontend:
1. Check that the Python backend is running and healthy
2. Verify API endpoints are responding correctly
3. Review Xcode console for error messages
4. Test individual API calls in Settings window

---

**Built with:** SwiftUI, Foundation, macOS SDK
**Target:** macOS 14.0+
**Swift Version:** 5.9+

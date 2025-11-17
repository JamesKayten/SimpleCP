# SimpleCP - Swift macOS Frontend

Native macOS application for SimpleCP clipboard manager, built with SwiftUI.

## Architecture

This is a **hybrid application**:
- **Python Backend**: Handles all business logic, clipboard monitoring, and data persistence
- **Swift Frontend**: Provides native macOS UI and communicates with Python via REST API

```
┌─────────────────────────┐
│   Swift macOS App       │  ← This project
│   (UI Only)             │
│                         │
│   - Menu bar icon       │
│   - Main window         │
│   - Settings            │
└───────────┬─────────────┘
            │
            │ HTTP REST API
            │ (localhost:8000)
            │
┌───────────▼─────────────┐
│   Python Daemon         │  ← ../daemon.py
│   (All Logic)           │
│                         │
│   - Clipboard monitor   │
│   - Data persistence    │
│   - Business logic      │
│   - FastAPI server      │
└─────────────────────────┘
```

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Python 3.8+ with SimpleCP backend running

## Project Structure

```
SimpleCPApp/
├── Package.swift                          # Swift Package Manager configuration
├── Sources/SimpleCPApp/
│   ├── SimpleCPApp.swift                 # App entry point
│   ├── Models/
│   │   ├── ClipboardItem.swift           # Data models matching Python API
│   │   ├── APIModels.swift               # Request/response models
│   │   └── AppState.swift                # Observable app state
│   ├── Services/
│   │   └── APIClient.swift               # HTTP client for Python backend
│   ├── Views/
│   │   ├── ContentView.swift             # Main window layout
│   │   ├── Components/
│   │   │   ├── HeaderView.swift          # Window header
│   │   │   ├── SearchBarView.swift       # Global search
│   │   │   ├── ControlBarView.swift      # Action buttons
│   │   │   ├── StatusBarView.swift       # Status messages
│   │   │   └── SettingsView.swift        # Settings window
│   │   ├── History/
│   │   │   ├── HistoryColumnView.swift   # Left column
│   │   │   ├── HistoryItemView.swift     # History items
│   │   │   └── HistoryFolderView.swift   # Auto-folders (11-20, etc.)
│   │   └── Snippets/
│   │       ├── SnippetsColumnView.swift  # Right column
│   │       ├── SnippetFolderView.swift   # Snippet folders
│   │       ├── SnippetItemView.swift     # Snippet items
│   │       └── SaveSnippetDialog.swift   # Save workflow
│   └── Resources/
└── README.md                              # This file
```

## Building from Source

### Option 1: Using Swift Package Manager (Command Line)

```bash
cd SimpleCPApp
swift build
swift run
```

### Option 2: Using Xcode

1. Open Terminal and navigate to the SimpleCPApp directory:
   ```bash
   cd SimpleCPApp
   ```

2. Generate Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```

3. Open in Xcode:
   ```bash
   open SimpleCPApp.xcodeproj
   ```

4. Build and run (⌘R)

### Option 3: Direct Swift Package in Xcode

1. Open Xcode
2. File → Open → Select `SimpleCPApp/Package.swift`
3. Build and run (⌘R)

## Running the Complete Application

The Swift frontend requires the Python backend to be running.

### Step 1: Start Python Backend

In the parent directory:

```bash
cd ..
python daemon.py
```

You should see:
```
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://127.0.0.1:8000    ║
╚══════════════════════════════════════════╝
```

### Step 2: Start Swift Frontend

In the SimpleCPApp directory:

```bash
swift run
```

Or run from Xcode.

### Step 3: Verify Connection

1. The app should open with a two-column layout
2. Check Settings → General → Status should show "Connected"
3. You should see any existing clipboard history and snippets

## Features Implemented

### ✅ Complete Features

- **Two-Column Layout**: History (left) and Snippets (right)
- **Search**: Real-time search across history and snippets
- **History Management**:
  - View recent clipboard items (1-10)
  - Auto-generated folders (11-20, 21-30, etc.)
  - Click to copy
  - Delete items
  - Clear all history
- **Snippet Management**:
  - Organize snippets in folders
  - Save clipboard items as snippets
  - Smart name suggestions
  - Tags support
  - Folder operations (create, rename, delete)
  - Move snippets between folders
- **Save Snippet Workflow**:
  - Complete dialog with preview
  - Auto-name suggestions
  - Create new folders inline
  - Tag support
- **Backend Integration**:
  - Dynamic API discovery via `/config` endpoint
  - All API endpoints implemented
  - Health checking
  - Error handling

### 🎨 UI/UX

- Native macOS design with SwiftUI
- Hover effects on items
- Context menus (right-click)
- Keyboard shortcuts
- Loading states
- Error messages
- Settings window

## API Integration

### Base URL Discovery

The app automatically discovers the API configuration:

```swift
let config = try await apiClient.fetchConfig()
// Uses /config endpoint to get http://127.0.0.1:8000/api/v1
```

### Available Endpoints

All endpoints match the Python backend `/api/v1` API:

- **History**: `GET /api/v1/history`, `GET /api/v1/history/recent`, `GET /api/v1/history/folders`
- **Snippets**: `GET /api/v1/snippets`, `POST /api/v1/snippets`, `PUT/DELETE /api/v1/snippets/{folder}/{id}`
- **Folders**: `POST /api/v1/snippets/folders`, `PUT/DELETE /api/v1/snippets/folders/{name}`
- **Clipboard**: `POST /api/v1/clipboard/copy`
- **Search**: `GET /api/v1/search?q={query}`
- **Health**: `GET /health`

## Configuration

### Backend URL

Default: `http://127.0.0.1:8000`

To change the backend URL, edit `APIClient.swift`:

```swift
init(baseURL: String = "http://127.0.0.1:8000") {
    // Change to your backend URL
}
```

### Auto-Refresh

In Settings → General, adjust the auto-refresh interval (1-30 seconds).

## Keyboard Shortcuts

- **⌘,** - Open Settings
- **⌘R** - Refresh data
- **⌘F** - Focus search
- **⌘S** - Save as Snippet
- **⌘W** - Close window

## Troubleshooting

### "Cannot connect to backend"

1. Ensure Python daemon is running:
   ```bash
   python daemon.py
   ```

2. Check the daemon is listening on port 8000:
   ```bash
   lsof -i :8000
   ```

3. Test the API manually:
   ```bash
   curl http://127.0.0.1:8000/health
   ```

### "No clipboard items showing"

1. Check backend logs for clipboard monitoring status
2. On Linux, ensure `xclip` is installed:
   ```bash
   sudo apt-get install xclip
   ```

### Build Errors

1. Ensure Xcode Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```

2. Clean and rebuild:
   ```bash
   swift package clean
   swift build
   ```

## Development

### Adding New Features

1. **Models**: Add to `Models/` directory
2. **API Calls**: Extend `Services/APIClient.swift`
3. **Views**: Add to appropriate `Views/` subdirectory
4. **State**: Update `Models/AppState.swift`

### Code Style

- SwiftUI for all views
- @MainActor for observable objects
- async/await for API calls
- Codable for JSON serialization

## Known Limitations

- **No real-time updates**: Currently polls backend (not WebSocket)
- **No batch operations**: One API call per operation
- **No offline mode**: Requires backend connection
- **No pagination**: Loads all items at once

## Future Enhancements

- [ ] WebSocket for real-time clipboard monitoring
- [ ] Batch operations support
- [ ] Offline mode with local caching
- [ ] Pagination for large datasets
- [ ] Advanced search filters
- [ ] Import/export functionality
- [ ] Keyboard-only navigation
- [ ] macOS menu bar app (status item)

## License

Same as parent SimpleCP project.

## Credits

Built with:
- SwiftUI (Apple)
- Swift Package Manager
- Foundation URLSession for HTTP

Backend: FastAPI (Python)

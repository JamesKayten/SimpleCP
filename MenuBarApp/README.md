# SimpleCP Menu Bar App

Native macOS menu bar integration for SimpleCP clipboard manager.

## Features

### 🎯 Menu Bar Integration
- **Status Bar Icon**: Always-accessible clipboard icon in menu bar
- **Item Count Display**: Shows number of clipboard items
- **Quick Access Menu**: Right-click menu for common actions
- **Popover Window**: Quick access to recent clipboard items

### ⌨️ Global Hotkeys
- **Cmd+Shift+V**: Toggle quick access popover
- **Cmd+Shift+C**: Quick copy last item
- **Cmd+Shift+X**: Clear clipboard history (with confirmation)

### 🚀 Quick Actions
- **Show SimpleCP**: Launch main application window
- **Quick Copy**: Copy most recent clipboard item
- **Clear History**: Clear all clipboard history
- **Settings**: Open preferences window
- **Quit**: Exit menu bar app

### 📊 Real-Time Updates
- Automatic clipboard count updates every 5 seconds
- Live search in quick access popover
- Instant copy to clipboard

## Requirements

- macOS 12.0 or later
- SimpleCP backend running on `localhost:8000`
- Xcode 14.0+ (for building)

## Installation

### Option 1: Pre-built App
1. Download `SimpleCPMenuBar.app` from releases
2. Move to `/Applications/` folder
3. Launch the app
4. Grant accessibility permissions when prompted

### Option 2: Build from Source
```bash
cd MenuBarApp
xcodebuild -scheme SimpleCPMenuBar -configuration Release
```

The built app will be in `build/Release/SimpleCPMenuBar.app`

## Configuration

### Backend Connection
By default, the menu bar app connects to:
```
http://127.0.0.1:8000
```

To use a different backend URL, modify `SimpleCPAPIClient.swift`:
```swift
init(baseURL: String = "http://your-backend-url:port") {
    self.baseURL = baseURL
}
```

### Customizing Hotkeys
Edit `HotkeyManager.swift` to customize global hotkeys:
```swift
static let defaultHotkeys: [String: Hotkey] = [
    "quickToggle": Hotkey(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey), action: "toggle"),
    // Add your custom hotkeys here
]
```

**Key Codes:**
- 0: A
- 6: X
- 7: X
- 8: C
- 9: V
- See Carbon framework documentation for complete list

## Architecture

### Components

#### SimpleCPMenuBarApp.swift
Main application delegate that manages:
- Status bar item
- Popover window
- Menu creation
- Event monitoring
- Clipboard count updates

#### HotkeyManager.swift
Global hotkey registration and handling:
- Registers hotkeys with macOS
- Handles hotkey events
- Executes hotkey actions

#### SimpleCPAPIClient.swift
REST API client for backend communication:
- Async/await based
- Type-safe API calls
- Error handling
- Model definitions

#### QuickAccessView.swift
SwiftUI view for quick access popover:
- Recent items list
- Search functionality
- One-click copy
- Context menu actions

#### SettingsView.swift
SwiftUI preferences window:
- General settings
- Privacy configuration
- Analytics preferences
- About information

### Data Flow

```
Menu Bar App
    ↓
HotkeyManager → API Client → Backend (localhost:8000)
    ↓                              ↓
Quick Access ← JSON Response ← REST API
```

## Usage

### Quick Access Popover
1. Click menu bar icon OR press Cmd+Shift+V
2. Type to search clipboard history
3. Click item to copy to clipboard
4. Right-click for more options (Delete, etc.)

### Menu Bar Menu
- **Show SimpleCP**: Opens main window
- **Quick Copy**: Copies last clipboard item
- **Clear History**: Clears all history (with confirmation)
- **Settings**: Opens preferences
- **Quit**: Exits menu bar app

### Hotkey Actions
- **Cmd+Shift+V**: Toggle quick access
- **Cmd+Shift+C**: Quick copy last item
- **Cmd+Shift+X**: Clear history (with prompt)

### Settings Window
Access via menu or Cmd+, shortcut:
- **General**: Configure history limits
- **Privacy**: Manage excluded apps and privacy mode
- **Analytics**: Enable/disable usage tracking
- **About**: App information and features

## Permissions

### Accessibility
Required for global hotkey registration.

**To grant permission:**
1. System Preferences → Security & Privacy → Privacy
2. Select "Accessibility"
3. Add SimpleCPMenuBar.app
4. Check the checkbox

### Notifications (Optional)
For notification banners when copying items.

**To grant permission:**
1. System Preferences → Notifications
2. Find SimpleCPMenuBar
3. Enable notifications

## Troubleshooting

### Menu bar icon not appearing
- Ensure app is running (check Activity Monitor)
- Restart the app
- Check Console.app for error messages

### Hotkeys not working
- Grant Accessibility permissions
- Check for conflicting hotkeys in System Preferences
- Restart the app after granting permissions

### Can't connect to backend
- Ensure Python backend is running: `python daemon.py`
- Check backend is on `localhost:8000`
- Check firewall settings
- View API logs for connection errors

### Popover shows "No clipboard history"
- Backend may not be running
- Check network connection to backend
- Verify API endpoint: `curl http://localhost:8000/api/history/recent`

### Search not working
- Check backend logs for errors
- Ensure backend has search index built
- Try restarting both apps

## Development

### Project Structure
```
MenuBarApp/
├── SimpleCPMenuBar.swift       # Main app delegate
├── HotkeyManager.swift         # Hotkey management
├── SimpleCPAPIClient.swift     # API client
├── Views/
│   ├── QuickAccessView.swift  # Quick access UI
│   └── SettingsView.swift     # Settings UI
└── README.md                   # This file
```

### Building for Development
```bash
# Open in Xcode
open MenuBarApp.xcodeproj

# Or build from command line
xcodebuild -scheme SimpleCPMenuBar -configuration Debug
```

### Debugging
Enable debug logging in `SimpleCPAPIClient.swift`:
```swift
func debugLog(_ message: String) {
    #if DEBUG
    print("[API] \(message)")
    #endif
}
```

## Advanced Features

### Launch at Login
To make the menu bar app launch at login:
1. System Preferences → Users & Groups → Login Items
2. Add SimpleCPMenuBar.app

Or programmatically using LaunchAtLogin framework.

### Custom Menu Bar Icon
Replace icon in `setupMenuBar()`:
```swift
button.image = NSImage(named: "YourCustomIcon")
```

### Background Service
The app runs as a menu bar app (no dock icon) by default.

To show in dock, add to Info.plist:
```xml
<key>LSUIElement</key>
<false/>
```

## Security Considerations

### Local-Only by Default
The menu bar app only connects to localhost by default for security.

### HTTPS for Remote Backend
If connecting to remote backend, use HTTPS:
```swift
let apiClient = SimpleCPAPIClient(baseURL: "https://your-secure-backend.com")
```

### Privacy Mode
When privacy mode is enabled in settings:
- No clipboard tracking occurs
- Existing history remains but new items are not added
- Can be toggled via API or settings

## Performance

### Memory Usage
Typical memory footprint: 30-50 MB

### CPU Usage
Idle: <1%
Active (searching): 2-5%

### Network
Minimal bandwidth usage (REST API calls only)

## Roadmap

- [ ] Keyboard shortcuts customization UI
- [ ] Custom menu bar icon themes
- [ ] Touch Bar support
- [ ] Multiple backend support
- [ ] Offline mode
- [ ] iCloud sync
- [ ] Share extension

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

MIT License - see LICENSE file for details

## Support

- GitHub Issues: https://github.com/JamesKayten/SimpleCP/issues
- Documentation: https://docs.simplecp.app
- Email: support@simplecp.app

## Credits

Built with:
- Swift 5.7+
- SwiftUI
- Carbon framework (hotkeys)
- URLSession (networking)

Inspired by:
- Flycut
- Alfred
- Paste

# SimpleCP macOS Frontend

Native Swift/SwiftUI frontend for SimpleCP clipboard manager.

## Architecture
- **Backend:** Python REST API (localhost:8080)
- **Frontend:** Native macOS SwiftUI app
- **Communication:** URLSession HTTP client

## Project Structure
```
SimpleCP-macOS/
├── SimpleCP/
│   ├── Views/
│   │   ├── ContentView.swift           # Main interface
│   │   ├── HistoryView.swift          # Clipboard history
│   │   ├── SnippetsView.swift         # Saved snippets
│   │   └── SettingsView.swift         # Configuration
│   ├── Models/
│   │   ├── ClipboardItem.swift        # Data model
│   │   └── APIResponse.swift          # API response models
│   ├── Services/
│   │   ├── APIClient.swift            # REST API client
│   │   └── ClipboardService.swift     # Clipboard operations
│   ├── App/
│   │   ├── SimpleCPApp.swift          # App entry point
│   │   └── AppDelegate.swift          # System integration
│   └── Resources/
│       ├── Assets.xcassets            # Icons and images
│       └── Info.plist                 # App configuration
├── SimpleCP.xcodeproj                 # Xcode project
└── README.md                          # This file
```

## Features
- Two-column layout (history + snippets)
- Real-time clipboard monitoring
- Full-text search across all items
- Keyboard shortcuts
- System menu bar integration
- Native macOS styling

## Next Steps
1. Create Xcode project
2. Implement URLSession API client
3. Build SwiftUI interface
4. Add keyboard shortcuts
5. Integrate with menu bar

## Requirements
- macOS 13.0+
- Xcode 14.0+
- Swift 5.7+
- Python backend running on localhost:8080
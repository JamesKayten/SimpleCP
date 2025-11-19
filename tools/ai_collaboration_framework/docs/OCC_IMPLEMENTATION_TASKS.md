# SimpleCP Swift Implementation Tasks for OCC

## Gap Analysis: Current vs Required UX

### Current Swift Implementation Issues:
1. **App Structure**: Uses AppDelegate instead of MenuBarExtra
2. **Window Size**: Not 600x400 as specified
3. **Layout**: Basic single-column instead of required two-column layout
4. **Search Bar**: Missing combined search/control bar at top
5. **Snippet Management**: No snippet folders, saving, or workflow
6. **Settings**: No multi-tab settings window
7. **Drag & Drop**: Not implemented
8. **Menu Structure**: Missing menu bar integration

---

## PRIORITY 1: Fix App Structure & Window (CRITICAL)

### Task 1.1: Replace AppDelegate with MenuBarExtra
**File:** `App.swift`
```swift
// REPLACE ENTIRE FILE with MenuBarExtra structure from UX spec:
@main
struct SimpleCPApp: App {
    var body: some Scene {
        MenuBarExtra("SimpleCP", systemImage: "clipboard") {
            ContentView()
                .frame(width: 600, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
```

### Task 1.2: Rebuild ContentView for Two-Column Layout
**File:** `ContentView.swift`
```swift
// REPLACE ENTIRE FILE with two-column structure:
struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Combined Search/Control Bar
            SearchControlBar(searchText: $searchText)
                .environmentObject(clipboardManager)

            Divider()

            // Two-Column Content
            HStack(spacing: 0) {
                RecentClipsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity)
                    .environmentObject(clipboardManager)
                Divider()
                SavedSnippetsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity)
                    .environmentObject(clipboardManager)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
```

---

## PRIORITY 2: Create Missing View Components

### Task 2.1: Create SearchControlBar Component
**New File:** `Views/SearchControlBar.swift`
```swift
// Implement combined search/control bar as per UX spec lines 337-381
// Include: search field, ➕📁📋⚙️ buttons
struct SearchControlBar: View {
    @Binding var searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showingSettings = false
    // ... implementation from UX spec
}
```

### Task 2.2: Create RecentClipsColumn Component
**New File:** `Views/RecentClipsColumn.swift`
```swift
// Left column showing numbered recent clips 1-10 plus folder groups
// Include hover buttons for quick save [💾]
struct RecentClipsColumn: View {
    let searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager
    // ... implementation
}
```

### Task 2.3: Create SavedSnippetsColumn Component
**New File:** `Views/SavedSnippetsColumn.swift`
```swift
// Right column with expandable folders and snippets
// Include drag & drop zones
struct SavedSnippetsColumn: View {
    let searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager
    // ... implementation
}
```

---

## PRIORITY 3: Implement Snippet Management System

### Task 3.1: Update ClipboardManager with Snippet Support
**File:** `ClipboardManager.swift`
```swift
// ADD these new structures and methods:
struct SnippetFolder: Identifiable, Codable {
    let id = UUID()
    var name: String
    var icon: String
    var snippets: [SavedSnippet]
    var isExpanded: Bool = true
}

struct SavedSnippet: Identifiable, Codable {
    let id = UUID()
    var name: String
    var content: String
    var tags: [String]
    var folder: UUID
    var createdAt: Date
}

class ClipboardManager: ObservableObject {
    // ADD to existing class:
    @Published var snippetFolders: [SnippetFolder] = []

    func saveAsSnippet(content: String, name: String, folderID: UUID, tags: [String]) { }
    func createFolder(name: String, icon: String) -> SnippetFolder { }
    func deleteFolder(id: UUID) { }
    func moveSnippet(snippetID: UUID, toFolderID: UUID) { }
    // ... more snippet methods
}
```

### Task 3.2: Create Save Snippet Workflow Dialog
**New File:** `Views/SaveSnippetDialog.swift`
```swift
// Implement complete dialog from UX spec lines 96-126
struct SaveSnippetDialog: View {
    let content: String
    @State private var snippetName: String
    @State private var selectedFolder: SnippetFolder?
    @State private var createNewFolder = false
    @State private var newFolderName = ""
    @State private var tags = ""
    // ... implementation
}
```

---

## PRIORITY 4: Settings & Configuration

### Task 4.1: Create Settings Window
**New File:** `Views/SettingsWindow.swift`
```swift
// Multi-tab settings window from UX spec lines 245-289
struct SettingsWindow: View {
    @State private var selectedTab = 0
    // Tabs: General, Appearance, Clips, Snippets
    // ... implementation
}
```

### Task 4.2: Create Settings Manager
**New File:** `Services/SettingsManager.swift`
```swift
class SettingsManager: ObservableObject {
    @Published var launchAtLogin = true
    @Published var startMinimized = true
    @Published var windowPosition = WindowPosition.center
    @Published var theme = Theme.auto
    // ... all settings from UX spec
}
```

---

## PRIORITY 5: Advanced Features

### Task 5.1: Implement Drag & Drop
**New File:** `Services/DragDropManager.swift`
```swift
// Implement drag from left column to right column folders
// Visual feedback, drop zones, etc.
```

### Task 5.2: Add Context Menus
- Right-click menus for clips and snippets
- Folder management menus
- Quick actions

### Task 5.3: Search Functionality
- Real-time filtering across both columns
- Highlight search matches
- Search in snippet content and tags

---

## PRIORITY 6: Polish & UX Refinements

### Task 6.1: Add Animations
- Folder expand/collapse animations
- Smooth transitions
- Hover effects

### Task 6.2: Keyboard Shortcuts
- Global hotkeys for opening app
- Quick paste shortcuts (⌘⌥1, ⌘⌥2, etc.)
- Search focus shortcut

### Task 6.3: Visual Polish
- Proper spacing and padding
- Icon consistency
- Color scheme matching system
- Dark/light mode support

---

## FILE STRUCTURE CHANGES NEEDED:

```
SimpleCP/
├── App.swift (REPLACE ENTIRELY)
├── ContentView.swift (REPLACE ENTIRELY)
├── Views/
│   ├── SearchControlBar.swift (NEW)
│   ├── RecentClipsColumn.swift (NEW)
│   ├── SavedSnippetsColumn.swift (NEW)
│   ├── SaveSnippetDialog.swift (NEW)
│   └── SettingsWindow.swift (NEW)
├── Services/
│   ├── ClipboardManager.swift (MAJOR UPDATES)
│   ├── SettingsManager.swift (NEW)
│   ├── DragDropManager.swift (NEW)
│   └── APIService.swift (update for snippets)
├── Models/ (NEW DIRECTORY)
│   ├── SnippetFolder.swift (NEW)
│   ├── SavedSnippet.swift (NEW)
│   └── ClipboardItem.swift (move from ClipboardManager)
└── Resources/
    └── ... (existing assets)
```

---

## IMPLEMENTATION ORDER:

1. **CRITICAL**: Fix App.swift MenuBarExtra structure
2. **CRITICAL**: Rebuild ContentView two-column layout
3. Create SearchControlBar component
4. Create RecentClipsColumn component
5. Create SavedSnippetsColumn component
6. Add snippet management to ClipboardManager
7. Create SaveSnippetDialog
8. Implement Settings system
9. Add drag & drop functionality
10. Polish animations and UX

---

## NOTES FOR OCC:

- **Current Swift files are NOT compatible** with UX spec - major rebuilding required
- MenuBarExtra is the correct approach for menu bar apps in modern SwiftUI
- Two-column layout is core to the entire design
- Snippet workflow is the key differentiator feature
- Must maintain connection to existing Python backend API
- Window should be 600x400 points exactly
- Use system colors for proper dark/light mode support

**CURRENT STATUS**: The existing Swift files are a basic starting template that needs to be completely restructured to match the comprehensive UX specification.
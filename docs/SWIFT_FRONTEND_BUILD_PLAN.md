# Swift Frontend Build Plan for Web Claude

## 🎯 **Mission: Build Swift Frontend Structure**

After backend testing is complete, build the complete Swift frontend structure that connects to your Python backend. Focus on **functionality over visual polish** - local Claude will handle visual refinements.

## 📱 **Xcode Project Structure to Create**

```
SimpleCP.xcodeproj/
├── SimpleCP/
│   ├── App/
│   │   ├── SimpleCPApp.swift           # App entry point
│   │   ├── ContentView.swift           # Main window container
│   │   └── AppDelegate.swift           # Menu bar integration
│   ├── Views/
│   │   ├── Components/
│   │   │   ├── HeaderView.swift        # Title + search + settings gear
│   │   │   ├── SearchBar.swift         # Always-visible search
│   │   │   ├── ControlBar.swift        # Save snippet + manage buttons
│   │   │   └── SettingsWindow.swift    # Gear icon settings
│   │   ├── History/
│   │   │   ├── HistoryColumnView.swift # Left column - recent clips
│   │   │   ├── HistoryItemView.swift   # Individual history items
│   │   │   └── HistoryFolderView.swift # Auto-folders (11-20, etc.)
│   │   ├── Snippets/
│   │   │   ├── SnippetsColumnView.swift    # Right column - snippet folders
│   │   │   ├── SnippetFolderView.swift     # Expandable folders
│   │   │   ├── SnippetItemView.swift       # Individual snippets
│   │   │   └── SaveSnippetDialog.swift     # Complete snippet save workflow
│   │   └── Shared/
│   │       ├── LoadingView.swift       # Loading states
│   │       └── ErrorView.swift         # Error handling
│   ├── Services/
│   │   ├── APIClient.swift             # HTTP client for Python backend
│   │   ├── ClipboardService.swift      # History operations
│   │   ├── SnippetService.swift        # Snippet CRUD operations
│   │   └── SearchService.swift         # Search functionality
│   ├── Models/
│   │   ├── ClipboardItem.swift         # Matches Python ClipboardItem
│   │   ├── SnippetFolder.swift         # Folder organization
│   │   ├── HistoryFolder.swift         # Auto-generated folders
│   │   ├── APIModels.swift             # Request/response models
│   │   └── AppState.swift              # ObservableObject for state
│   ├── Utils/
│   │   ├── DateUtils.swift             # Date formatting
│   │   ├── StringUtils.swift           # Text processing
│   │   └── Constants.swift             # App constants
│   └── Resources/
│       ├── Assets.xcassets             # App icons, colors
│       └── Info.plist                  # App configuration
├── SimpleCP.entitlements              # macOS permissions
└── README.md                           # Build instructions
```

## 🔧 **Core Components to Implement**

### 1. API Client (Highest Priority)
**File:** `Services/APIClient.swift`

```swift
// Build HTTP client that talks to your Python backend
class APIClient: ObservableObject {
    private let baseURL = "http://127.0.0.1:8000"

    // History endpoints
    func getHistory() async throws -> [ClipboardItem]
    func getHistoryFolders() async throws -> [HistoryFolder]
    func deleteHistoryItem(id: String) async throws
    func clearHistory() async throws

    // Snippet endpoints
    func getSnippets() async throws -> [String: [ClipboardItem]]
    func createSnippet(request: CreateSnippetRequest) async throws
    func updateSnippet(folderId: String, itemId: String, request: UpdateSnippetRequest) async throws
    func deleteSnippet(folderId: String, itemId: String) async throws

    // Folder endpoints
    func createFolder(name: String) async throws
    func renameFolder(oldName: String, newName: String) async throws
    func deleteFolder(name: String) async throws

    // Operations
    func copyToClipboard(itemId: String) async throws
    func search(query: String) async throws -> SearchResults
    func getHealth() async throws -> HealthStatus
}
```

### 2. Data Models (Match Your Python Models)
**File:** `Models/ClipboardItem.swift`

```swift
// Exact Swift equivalent of your Python ClipboardItem
struct ClipboardItem: Identifiable, Codable {
    let id = UUID()
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

    // Match your Python to_dict() format exactly
}
```

### 3. Main UI Structure (Basic Layout)
**File:** `ContentView.swift`

```swift
// Two-column layout matching UI spec v3
struct ContentView: View {
    @StateObject private var apiClient = APIClient()
    @StateObject private var appState = AppState()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()           // Title + search + settings
            ControlBar()           // Save snippet + manage buttons

            HStack(spacing: 0) {
                HistoryColumnView()     // Left: Recent clips + auto-folders
                    .frame(maxWidth: .infinity)

                Divider()

                SnippetsColumnView()    // Right: Snippet folders
                    .frame(maxWidth: .infinity)
            }
        }
        .environmentObject(apiClient)
        .environmentObject(appState)
    }
}
```

### 4. Snippet Save Workflow (Core Feature)
**File:** `Views/Snippets/SaveSnippetDialog.swift`

```swift
// Complete snippet save dialog from UI spec v3
struct SaveSnippetDialog: View {
    let clipboardItem: ClipboardItem
    @State private var snippetName = ""
    @State private var selectedFolder = ""
    @State private var newFolderName = ""
    @State private var tags = ""

    var body: some View {
        VStack {
            // Content preview
            ScrollView {
                Text(clipboardItem.content)
                    .textSelection(.enabled)
            }
            .frame(height: 120)

            // Name field with smart suggestion
            TextField("Snippet Name", text: $snippetName)
                .onAppear {
                    snippetName = suggestName(for: clipboardItem)
                }

            // Folder selection + create new option
            Picker("Folder", selection: $selectedFolder) {
                ForEach(availableFolders, id: \.self) { folder in
                    Text(folder).tag(folder)
                }
            }

            // Create new folder option
            HStack {
                Toggle("Create new folder:", isOn: $showNewFolder)
                if showNewFolder {
                    TextField("Folder name", text: $newFolderName)
                }
            }

            // Tags (optional)
            TextField("Tags (optional)", text: $tags)

            // Action buttons
            HStack {
                Button("Cancel") { dismiss() }
                Button("Save Snippet") { saveSnippet() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}
```

## 🔄 **Backend Integration Requirements**

### API Communication
- **All HTTP calls** must match your Python backend endpoints exactly
- **Error handling** for network failures and API errors
- **Loading states** during API calls
- **Real-time updates** when backend data changes

### Data Flow
```swift
User Action → SwiftUI View → Service Layer → APIClient → Python Backend
Python Backend → APIClient → Service Layer → AppState → SwiftUI Views
```

### Key Integrations
1. **Clipboard monitoring sync** - Poll backend for new items
2. **Search integration** - Use your `/api/search` endpoint
3. **Snippet workflow** - Complete save process via API
4. **Auto-folder display** - Show your auto-generated history folders

## 📋 **Implementation Priority**

### Phase 1: Core Infrastructure
1. **Xcode project setup** - Create project with all files
2. **APIClient implementation** - All endpoint methods
3. **Data models** - Exact Swift equivalents of Python models
4. **Basic two-column layout** - Functional but not polished

### Phase 2: History Column (Left Side)
1. **HistoryColumnView** - Display recent clips from API
2. **HistoryFolderView** - Show auto-generated folders (11-20, etc.)
3. **Click to copy** - Integrate with `/api/clipboard/copy`
4. **Real-time updates** - Refresh when backend adds clips

### Phase 3: Snippets Column (Right Side)
1. **SnippetsColumnView** - Display folders and snippets
2. **SaveSnippetDialog** - Complete snippet creation workflow
3. **Folder management** - Create, rename, delete folders
4. **Drag & drop** - From history to snippet folders

### Phase 4: Search & Polish
1. **SearchBar integration** - Use `/api/search` endpoint
2. **Settings window** - Basic preferences
3. **Error handling** - Graceful failure modes
4. **Loading states** - Better UX during API calls

## 🎯 **Success Criteria**

### ✅ **Must Work:**
- [x] Xcode project builds successfully
- [x] All API endpoints are called correctly
- [x] Two-column layout displays data from backend
- [x] Snippet save workflow functions completely
- [x] History auto-folders display correctly
- [x] Search works across history and snippets
- [x] Click to copy functionality works
- [x] Data updates in real-time from backend

### 🎨 **Visual Polish (Leave for Local Claude):**
- ❌ **Don't focus on:** Colors, animations, fonts, spacing
- ❌ **Don't focus on:** Advanced UI polish or native macOS styling
- ❌ **Don't focus on:** Window management or menu bar integration

## 📤 **Deliverables**

When complete, provide:
1. **Complete Xcode project** - All files and structure
2. **Build instructions** - How to run the project
3. **API integration status** - Which endpoints work
4. **Known issues** - What needs refinement
5. **Testing results** - Basic functionality verification

## 🔄 **Handoff to Local Claude**

After you complete the functional Swift frontend:
- **Local Claude** will handle visual polish and Xcode management
- **You (OCC)** can assist with any API integration issues
- **Local user** will handle final UI refinements and testing

---

**Your mission: Build the complete functional Swift frontend that connects perfectly to your Python backend! 🚀**
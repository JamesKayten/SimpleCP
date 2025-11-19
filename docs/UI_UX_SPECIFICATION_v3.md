# SimpleCP - UI/UX Specification v3 (MenuBarExtra Dropdown)

This document defines the **MenuBarExtra dropdown interface** for SimpleCP, providing quick access to clipboard history and snippets from the macOS menu bar.

## App Design Overview

**Type**: macOS MenuBarExtra (menu bar dropdown)
**Size**: 600x400 pixels
**Style**: Modern, clean two-column layout
**Access**: Click menu bar icon to toggle dropdown

```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 [Search clips and snippets...........] ➕ 📁 📋 ⚙️    │ ← Combined Bar
├─────────────────────┬───────────────────────────────────────┤
│ 📋 RECENT CLIPS     │ 📁 SAVED SNIPPETS                    │
│                     │                                       │
│ 1. "Latest clip..." │ 📁 Email Templates ▼                │
│ 2. "Second clip..." │   ├── Meeting Request                │
│ 3. "Third clip..."  │   ├── Follow Up                      │
│ 4. "Fourth clip..." │   └── Thank You                      │
│ 5. "Fifth clip..."  │                                       │
│ 6. "Sixth clip..."  │ 📁 Code Snippets ▼                  │
│ 7. "Seventh..."     │   ├── Python Main                    │
│ 8. "Eighth..."      │   ├── Git Commit                     │
│ 9. "Ninth..."       │   └── Docker Run                     │
│ 10. "Tenth..."      │                                       │
│ ──────────────────  │ 📁 Common Text ▲ (collapsed)         │
│ 📁 11 - 20         │                                       │
│ 📁 21 - 30         │                                       │
│ 📁 31 - 40         │                                       │
└─────────────────────┴───────────────────────────────────────┘
```

## Combined Search & Control Bar

Single horizontal bar containing all main controls:

```
🔍 [Search clips and snippets...........................] ➕ 📁 📋 ⚙️
```

### Layout (Left to Right):
1. **🔍 Search Field** (expandable, takes most space)
   - Placeholder: "Search clips and snippets..."
   - Real-time filtering of both columns
   - Searches content and snippet names

2. **➕ Create Snippet** - Opens snippet creation dialog
3. **📁 Manage Folders** - Opens folder management
4. **📋 Clear History** - Clears all clipboard history
5. **⚙️ Settings** - Opens settings window

### Key Features:
- **Space-efficient**: All controls in one compact row
- **Clean design**: No separate header or title bar
- **Quick access**: Most important actions immediately visible
- **No window chrome**: Pure content (MenuBarExtra dropdown has no title bar)

## Two-Column Layout

### Left Column: Recent Clips

Shows the 10 most recent clipboard items:

```
📋 RECENT CLIPS
─────────────────
1. "Latest clipboard item..."        [💾]
2. "Second most recent item..."      [💾]
3. "Third clipboard item..."         [💾]
...
10. "Tenth item..."                  [💾]
──────────────────
📁 11 - 20
📁 21 - 30
📁 31 - 40
```

**Features**:
- Numbered list (1-10 most recent)
- Auto-generated folders for older items (11-20, 21-30, etc.)
- Hover shows save button [💾]
- Click to copy to clipboard
- Right-click context menu:
  - Copy Again
  - Save as Snippet...
  - Remove from History

### Right Column: Saved Snippets

Organized folders of saved snippets:

```
📁 SAVED SNIPPETS
─────────────────────
📁 Email Templates ▼
  ├── Meeting Request
  ├── Follow Up
  └── Thank You
  ──────────────────
  ➕ Add snippet here...

📁 Code Snippets ▲
  (5 snippets)

📁 Common Text ▼
  ├── Email signature
  └── Address
```

**Features**:
- Expandable/collapsible folders
- Folder icons (customizable)
- Snippet count when collapsed
- Quick add option in each folder
- Click snippet to copy
- Right-click context menu:
  - Copy to Clipboard
  - Edit Content...
  - Rename...
  - Duplicate
  - Move to Folder →
  - Delete

## Search Functionality

### Real-time Filtering

As user types in search field:
- Both columns filter simultaneously
- Matching text highlighted
- Folders auto-expand to show matches

```
Search: "meeting"

📋 RECENT CLIPS (Filtered)    │ 📁 SAVED SNIPPETS (Filtered)
                              │
2. "Schedule the meeting..."   │ 📁 Email Templates ▼
8. "Meeting notes from..."     │   ├── 🔍 Meeting Request
                              │   └── 🔍 Meeting Follow-up
📁 11-20 (2 matches)          │
📁 21-30 (1 match)           │ 📁 Work Notes ▼
                              │   └── 🔍 Weekly meeting agenda
```

### Search Scope:
- Clipboard content
- Snippet names
- Snippet content
- Tags (if present)

## Snippet Creation Workflow

### Save as Snippet Dialog

Opened via:
- ➕ button in control bar
- 💾 hover button on clipboard items
- Right-click → "Save as Snippet..."

```
┌───────────────────────────────────────────────────┐
│ Save as Snippet                              [ X ] │
├───────────────────────────────────────────────────┤
│ Content Preview:                                  │
│ ┌─────────────────────────────────────────────┐   │
│ │ This is the current clipboard content      │   │
│ │ that will be saved as a snippet...         │   │
│ │ [Content shows here]                       │   │
│ └─────────────────────────────────────────────┘   │
│                                                   │
│ Snippet Name:                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Meeting Request Template                    │   │ ← Auto-suggested
│ └─────────────────────────────────────────────┘   │
│                                                   │
│ Save to Folder:                                   │
│ ┌─────────────────────────────────────────────┐   │
│ │ Email Templates                         ▼   │   │ ← Dropdown
│ └─────────────────────────────────────────────┘   │
│ ☐ Create new folder: [________________]          │
│                                                   │
│ Tags: (optional)                                  │
│ ┌─────────────────────────────────────────────┐   │
│ │ #email #template #meeting                   │   │
│ └─────────────────────────────────────────────┘   │
│                                                   │
│        [ Save Snippet ]  [ Cancel ]               │
└───────────────────────────────────────────────────┘
```

### Smart Name Suggestions
- Auto-detect content type (email, code, URL, etc.)
- Extract meaningful names from content
- Learn from user naming patterns
- First line or key phrase suggestions

## Folder Management

### Manage Folders Dialog

Opened via 📁 button:

```
┌─────────────────────┐
│ Manage Folders      │
├─────────────────────┤
│ 📁 Email Templates  │ ← Drag to reorder
│ 📁 Code Snippets    │
│ 📁 Common Text      │
│ 📁 Work Notes       │
├─────────────────────┤
│ ➕ New Folder       │
│ 🗑️ Delete Selected  │
│                     │
│ [ Done ]            │
└─────────────────────┘
```

### Folder Context Menu
Right-click any folder:
- Rename Folder...
- Change Icon...
- Folder Statistics...
- Delete Folder

### Folder Icons
Available icons for customization:
- 📁 📂 📋 📝 📊 💼 🔧 ⚙️ 📧
- 🏢 👥 🎯 💡 🔒 🌟 🎨 📱 🖥️
- And more...

## Settings Window

Opened via ⚙️ button:

```
┌─────────────────────────────────────┐
│ SimpleCP Preferences                │
├─────────────────────────────────────┤
│ 🔧 General   🎨 Appearance   📋 Data │
├─────────────────────────────────────┤
│ GENERAL SETTINGS                    │
│                                     │
│ Startup:                            │
│ ☑ Launch at login                   │
│                                     │
│ Shortcuts:                          │
│ Open SimpleCP: [⌘⌥V     ] [Set]    │
│ Paste #1: [⌘⌥1         ] [Set]    │
│ Paste #2: [⌘⌥2         ] [Set]    │
│                                     │
│ History:                            │
│ Keep items: [100           ▼]      │
│ ☑ Monitor clipboard                 │
│                                     │
│ [ Save ] [ Cancel ] [ Defaults ]    │
└─────────────────────────────────────┘
```

### Appearance Settings Tab
```
🎨 APPEARANCE SETTINGS

Theme: ● Auto  ○ Light  ○ Dark

Fonts:
Interface: [SF Pro        ▼] Size: [13▼]
Clips: [SF Mono          ▼] Size: [12▼]

☑ Show folder icons
☑ Animate folder expand/collapse
☑ Show save button on hover
```

### Data Settings Tab
```
📋 DATA SETTINGS

History:
Max items: [100         ] items
Auto-clear: [Never      ▼]

Snippets:
☑ Sync via iCloud
☑ Backup automatically

[ 📤 Export All ] [ 📥 Import ] [ 🗑️ Clear All ]
```

## Interaction Patterns

### Click Actions
- **Clipboard item**: Copy to clipboard
- **Snippet**: Copy to clipboard
- **Folder header**: Expand/collapse
- **Save button (💾)**: Open save dialog

### Hover States
- Show save button on clipboard items
- Highlight rows
- Show tooltips on buttons

### Context Menus
- Right-click clipboard items
- Right-click snippets
- Right-click folders

### Keyboard Shortcuts
- `⌘⌥V`: Toggle SimpleCP dropdown
- `⌘⌥1-9`: Quick paste from positions 1-9
- `⌘F`: Focus search field
- `Esc`: Close dropdown

## Technical Implementation (Swift/SwiftUI)

### App Structure
```swift
@main
struct SimpleCPApp: App {
    var body: some Scene {
        MenuBarExtra("SimpleCP", systemImage: "doc.on.clipboard") {
            ContentView()
                .frame(width: 600, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
```

### Main View Structure
```swift
struct ContentView: View {
    @StateObject var appState = AppState()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Combined search & control bar
            CombinedBar(searchText: $searchText)

            Divider()

            // Two-column layout
            HStack(spacing: 0) {
                RecentClipsColumn(searchText: searchText)
                Divider()
                SavedSnippetsColumn(searchText: searchText)
            }
        }
        .environmentObject(appState)
    }
}
```

### Combined Bar Component
```swift
struct CombinedBar: View {
    @Binding var searchText: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search clips and snippets...", text: $searchText)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            Spacer()

            // Control buttons
            Button(action: { appState.showCreateSnippet = true }) {
                Image(systemName: "plus.circle.fill")
            }
            Button(action: { appState.showManageFolders = true }) {
                Image(systemName: "folder.fill")
            }
            Button(action: { appState.showClearHistory = true }) {
                Image(systemName: "doc.on.clipboard.fill")
            }
            Button(action: { appState.showSettings = true }) {
                Image(systemName: "gearshape.fill")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
```

### Data Models
```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let clipId: String
    let content: String
    let timestamp: Date
    let displayString: String
    let snippetName: String?
    let folderPath: String?
    let tags: [String]
}

struct SnippetFolder: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    var isExpanded: Bool
    var snippets: [ClipboardItem]
}
```

### Backend Integration
```swift
class APIClient {
    private let baseURL = "http://127.0.0.1:8000"

    func getHistory() async throws -> [ClipboardItem]
    func getSnippets() async throws -> [String: [ClipboardItem]]
    func createSnippet(request: CreateSnippetRequest) async throws
    func deleteHistoryItem(id: String) async throws
    func clearHistory() async throws
}
```

## Implementation Priority

### Phase 1: Core Structure ✅
- [x] MenuBarExtra app setup
- [x] Combined search & control bar
- [x] Two-column layout
- [x] Basic data models

### Phase 2: History Column
- [ ] Display recent clips from backend
- [ ] Auto-generated history folders
- [ ] Click to copy functionality
- [ ] Right-click context menus
- [ ] Hover save button

### Phase 3: Snippets Column
- [ ] Display snippet folders
- [ ] Expand/collapse folders
- [ ] Click snippet to copy
- [ ] Context menus
- [ ] Folder management

### Phase 4: Snippet Workflow
- [ ] Save as snippet dialog
- [ ] Smart name suggestions
- [ ] Folder selection
- [ ] Tags support
- [ ] Quick save from history

### Phase 5: Search & Filtering
- [ ] Real-time search
- [ ] Filter both columns
- [ ] Highlight matches
- [ ] Auto-expand matching folders

### Phase 6: Settings & Polish
- [ ] Settings window
- [ ] Theme support
- [ ] Keyboard shortcuts
- [ ] Import/export
- [ ] iCloud sync

## Design Principles

1. **Simplicity**: Clean, uncluttered MenuBarExtra dropdown
2. **Speed**: Quick access from menu bar, instant search
3. **Efficiency**: Combined bar saves vertical space
4. **Familiarity**: Standard macOS UI patterns
5. **Flexibility**: Customizable folders and shortcuts

---

**This MenuBarExtra design provides a lightweight, always-accessible clipboard manager that integrates seamlessly with macOS!** 🚀

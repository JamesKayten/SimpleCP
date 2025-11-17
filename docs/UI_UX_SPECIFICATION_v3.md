# SimpleCP - UI/UX Specification v3 (Header + Two-Column Layout)

This document defines the **modern header-based interface** for SimpleCP, inspired by elegant clipboard managers like Clip-It.

## Window Design Overview

```
┌─────────────────────────────────────────────────────────────┐
│ SimpleCP                                     🔍 [⚙️] [ X ]│ ← Header Bar
├─────────────────────────────────────────────────────────────┤
│ 🔍 Search clips and snippets...                           │ ← Search Bar
├─────────────────────────────────────────────────────────────┤
│ ➕ Create Folder    📁 Manage Folders    📋 Clear History   │ ← Control Bar
├─────────────────────┬───────────────────────────────────────┤
│ 📋 RECENT CLIPS     │ 📁 SAVED SNIPPETS                   │
│                     │                                       │
│ 1. "Latest clip..." │ 📁 Email Templates ▼               │
│ 2. "Second clip..." │   ├── Meeting Request                │
│ 3. "Third clip..."  │   ├── Follow Up                      │ ← Two-Column
│ 4. "Fourth clip..." │   └── Thank You                      │   Content Area
│ 5. "Fifth clip..."  │                                       │
│ 6. "Sixth clip..."  │ 📁 Code Snippets ▼                  │
│ 7. "Seventh..."     │   ├── Python Main                    │
│ 8. "Eighth..."      │   ├── Git Commit                     │
│ 9. "Ninth..."       │   └── Docker Run                     │
│ 10. "Tenth..."      │                                       │
│ ──────────────────  │ 📁 Common Text ▲ (collapsed)        │
│ 📁 11 - 20         │                                       │
│ 📁 21 - 30         │                                       │
│ 📁 31 - 40         │                                       │
│ 📁 41 - 50         │                                       │
└─────────────────────┴───────────────────────────────────────┘
```

## Header Bar Design

### Window Header
- **Title**: "SimpleCP" (left-aligned)
- **Search Icon**: 🔍 (for global search, right side)
- **Settings Icon**: ⚙️ (gear icon, top right)
- **Close Button**: Standard macOS window controls

### Search Bar (Always Visible)
- **Placeholder**: "Search clips and snippets..."
- **Real-time filtering**: Updates both columns as user types
- **Search scope**: Searches both recent clips and saved snippets
- **Clear button**: ✖ appears when text is entered

### Control Bar (Snippet Management)
```
┌─────────────────────────────────────────────────────────────┐
│ ➕ Create Folder    📁 Manage Folders    📋 Clear History   │
│                                           📤 Export  📥 Import │
└─────────────────────────────────────────────────────────────┘
```

#### Control Bar Buttons:
- **➕ Create Folder**: Quick folder creation dialog
- **📁 Manage Folders**: Dropdown with folder operations
- **📋 Clear History**: Clear all clipboard history
- **📤 Export**: Export snippets to file
- **📥 Import**: Import snippets from file

### Manage Folders Dropdown
```
📁 Manage Folders ▼
├── 📝 Rename Folder...
├── 📁 Organize Folders...
├── 🎨 Change Folder Icon...
├── ───────────────────────
├── 📊 Folder Statistics...
├── 🔒 Lock/Unlock Folders...
├── ───────────────────────
└── 🗑️ Delete Empty Folders
```

## Search Functionality

### Global Search Behavior
- **As-you-type filtering**: Instant results while typing
- **Highlights matches**: Search terms highlighted in results
- **Cross-column search**: Searches both recent clips and snippets
- **Smart ranking**: Most recent and most relevant results first

### Search Results Display
```
Search: "meeting"

📋 RECENT CLIPS (Filtered)    │ 📁 SAVED SNIPPETS (Filtered)
                              │
2. "Schedule the meeting..."   │ 📁 Email Templates ▼
8. "Meeting notes from..."     │   ├── 🔍 Meeting Request ← highlighted
                              │   └── 🔍 Meeting Follow-up ← highlighted
📁 11-20 (2 matches)          │
📁 21-30 (1 match)           │ 📁 Work Notes ▼
                              │   └── 🔍 Weekly meeting agenda
```

## Snippet Folder Management

### Quick Folder Creation (Header Button)
```
➕ Create Folder
│
└── Inline creation:
    ┌─────────────────────────────┐
    │ 📁 [New folder name...  ]   │
    │    [ ✓ Create ] [ ✖ Cancel ] │
    └─────────────────────────────┘
```

### Advanced Folder Management
```
📁 Manage Folders → Opens sidebar:

┌─────────────────────┐
│ Folder Management   │
├─────────────────────┤
│ 📁 Email Templates  │ ← Drag to reorder
│ 📁 Code Snippets    │
│ 📁 Common Text      │
│ 📁 Work Notes       │
├─────────────────────┤
│ ➕ New Folder       │
│ 📋 Import Folder    │
│ 🗑️ Delete Selected  │
│                     │
│ [ Done ]            │
└─────────────────────┘
```

### Folder Icons and Customization
```
🎨 Change Folder Icon → Icon picker:

┌─────────────────────────────────┐
│ Choose Folder Icon              │
├─────────────────────────────────┤
│ 📁 📂 📋 📝 📊 💼 🔧 ⚙️ 📧  │
│ 🏢 👥 🎯 💡 🔒 🌟 🎨 📱 🖥️  │
│ 🔍 📈 📉 📅 ⏰ 🎵 📷 🎮 🍕  │
├─────────────────────────────────┤
│ Custom: [🎭] [Load Image...]    │
│                                 │
│ [ Apply ] [ Cancel ] [ Reset ]  │
└─────────────────────────────────┘
```

## Right Column Enhancements

### Folder States and Controls
```
📁 Email Templates ▼                    ← Expanded, click to collapse
  ├── Meeting Request                    ← Individual snippets
  ├── Follow Up
  └── Thank You
  ──────────────────
  ➕ Add snippet here...                 ← Quick add option

📁 Code Snippets ▲                      ← Collapsed, click to expand
  (5 snippets)                          ← Show count when collapsed

📁 Work Notes ▼                         ← Expanded folder
  ├── Daily standup template
  ├── Project status update
  └── Weekly meeting agenda
  ──────────────────
  📋 Paste current clipboard here        ← Quick add from current clipboard
```

### Snippet Operations
```
Right-click any snippet:
├── 📋 Copy to Clipboard
├── 📝 Edit...
├── 🏷️ Rename...
├── 📋 Duplicate
├── ───────────────────
├── 📁 Move to Folder ▶
├── ⭐ Add to Favorites
├── ───────────────────
└── 🗑️ Delete
```

## Settings Window (⚙️ Gear Icon)

```
⚙️ SimpleCP Settings

┌─────────────────────────────────────┐
│ SimpleCP Preferences                │
├─────────────────────────────────────┤
│ 🔧 General   🎨 Appearance   📋 Clips  📁 Snippets │ ← Tabs
├─────────────────────────────────────┤
│ GENERAL SETTINGS                    │
│                                     │
│ Startup:                            │
│ ☑ Launch at login                   │
│ ☑ Start minimized                   │
│                                     │
│ Window:                             │
│ Position: ● Center  ○ Remember      │
│ Size: ○ Compact ● Normal ○ Large    │
│                                     │
│ Shortcuts:                          │
│ Open SimpleCP: [⌘⌥V     ] [Set]    │
│ Quick search: [⌘⌥F      ] [Set]    │
│ Paste #1: [⌘⌥1         ] [Set]    │
│                                     │
│ [ Save ] [ Cancel ] [ Defaults ]    │
└─────────────────────────────────────┘
```

### Appearance Settings Tab
```
🎨 APPEARANCE SETTINGS

Theme: ● Auto  ○ Light  ○ Dark
Window opacity: [████████▓▓] 90%

Fonts:
Interface: [SF Pro        ▼] Size: [13▼]
Clips: [SF Mono          ▼] Size: [12▼]

Colors:
Header: [#2D3748] Accent: [#3182CE]
Background: [#F7FAFC] Text: [#2D3748]

☑ Show folder icons
☑ Animate folder expand/collapse
☐ Show snippet previews on hover
```

## Technical Implementation Updates

### New Class Structure
```python
class SimpleCP(rumps.App):
    def __init__(self):
        super().__init__("📋")
        self.main_window = None

    @rumps.clicked("Open SimpleCP")
    def show_main_window(self, _):
        if not self.main_window:
            self.main_window = MainWindow()
        self.main_window.show()

class MainWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.setup_window()
        self.create_header()
        self.create_search_bar()
        self.create_control_bar()
        self.create_two_columns()

    def create_header(self):
        # Window header with title, search icon, settings icon
        pass

    def create_search_bar(self):
        # Always-visible search with real-time filtering
        pass

    def create_control_bar(self):
        # Snippet management buttons
        pass
```

### Header Manager
```python
class HeaderManager:
    def __init__(self, parent_window):
        self.window = parent_window
        self.search_var = tk.StringVar()

    def create_header_bar(self):
        # Title, search icon, settings gear
        pass

    def create_search_bar(self):
        # Real-time search with filtering
        self.search_var.trace('w', self.on_search_change)

    def on_search_change(self, *args):
        # Filter both columns based on search
        search_term = self.search_var.get()
        self.window.filter_content(search_term)

    def show_settings(self):
        # Open settings window
        pass
```

### Settings Manager
```python
class SettingsManager:
    def __init__(self):
        self.load_settings()

    def show_settings_window(self):
        # Multi-tab settings window
        pass

    def apply_theme(self, theme_name):
        # Apply light/dark/auto theme
        pass

    def set_shortcuts(self, shortcuts_dict):
        # Configure keyboard shortcuts
        pass
```

## Implementation Priority

### Phase 1: Header Framework
1. ✅ Window with proper header bar
2. 🔍 Search bar implementation
3. ➕ Control bar with basic buttons
4. ⚙️ Settings window framework

### Phase 2: Enhanced Two-Column
1. 📋 Left column with auto-folders (maintain from v2)
2. 📁 Right column with expandable folders
3. 🔍 Real-time search filtering
4. 📋 Click to copy functionality

### Phase 3: Folder Management
1. ➕ Quick folder creation from header
2. 📁 Advanced folder management sidebar
3. 🎨 Folder icon customization
4. 📊 Folder statistics and organization

### Phase 4: Polish & Settings
1. ⚙️ Complete settings with tabs
2. 🎨 Theme system (light/dark/auto)
3. ⌨️ Keyboard shortcuts
4. 💾 Advanced import/export

This header-based design is **much more professional** and provides better organization of controls while maintaining the two-column efficiency!
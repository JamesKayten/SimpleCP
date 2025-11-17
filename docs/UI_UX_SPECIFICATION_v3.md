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

### Control Bar (Streamlined Snippet Workflow)
```
┌─────────────────────────────────────────────────────────────┐
│ 💾 Save as Snippet    📁 Manage Folders    📋 Clear History │
│                                           📤 Export  📥 Import │
└─────────────────────────────────────────────────────────────┘
```

#### Control Bar Buttons:
- **💾 Save as Snippet**: Complete snippet creation workflow (saves current clipboard)
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

### Complete Save as Snippet Workflow

#### Main Save as Snippet Dialog (💾 Button)
```
💾 Save as Snippet → Opens complete workflow dialog:

┌───────────────────────────────────────────────────┐
│ Save as Snippet                              [ X ] │
├───────────────────────────────────────────────────┤
│ Content Preview:                                  │
│ ┌─────────────────────────────────────────────┐   │
│ │ This is the current clipboard content      │   │
│ │ that will be saved as a snippet...         │   │ ← Preview area
│ │ [Content shows here]                       │   │
│ └─────────────────────────────────────────────┘   │
│                                                   │
│ Snippet Name:                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Meeting Request Template                    │   │ ← Auto-suggested name
│ └─────────────────────────────────────────────┘   │
│                                                   │
│ Save to Folder:                                   │
│ ┌─────────────────────────────────────────────┐   │
│ │ Email Templates                         ▼   │   │ ← Dropdown with existing folders
│ └─────────────────────────────────────────────┘   │
│ ☐ Create new folder: [________________]          │ ← Option to create new folder
│                                                   │
│ Tags: (optional)                                  │
│ ┌─────────────────────────────────────────────┐   │
│ │ #email #template #meeting                   │   │ ← Optional tags for organization
│ └─────────────────────────────────────────────┘   │
│                                                   │
│        [ Save Snippet ]  [ Cancel ]               │
└───────────────────────────────────────────────────┘
```

#### Quick Save from History (Right-click any clip)
```
Right-click any history item:
├── 📋 Copy Again
├── 💾 Save as Snippet...     ← Opens same dialog with this clip's content
├── ───────────────────────
└── 🗑️ Remove from History
```

#### Smart Name Suggestions
- **Auto-detect content type**: Email templates, code snippets, addresses, etc.
- **Suggest meaningful names**: "Meeting Request Template", "Git Commit Command", etc.
- **Learn from user patterns**: Remember naming conventions
- **Extract from content**: Use first line or key phrases as suggestions

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

### Quick Save Options from Left Column
```
Each recent clip has a quick save button on hover:

1. "Latest clipboard item preview..."     [💾]  ← Quick save button
2. "Second most recent item..."           [💾]
3. "Third clipboard item..."              [💾]
```

#### Drag & Drop Workflow
```
📋 RECENT CLIPS                    │ 📁 SAVED SNIPPETS
                                   │
1. "Meeting template..."     [💾]  │ 📁 Email Templates ▼
   ┌─────────────────────┐        │   ├── Previous template
   │ Drag me to folder → │ ═══════│   └── [Drop zone highlighted]
   └─────────────────────┘        │
                                   │ 📁 Code Snippets ▼
                                   │   └── [Drop zone]
```

- **Drag from left to right**: Auto-opens name dialog
- **Visual feedback**: Drop zones highlight when valid
- **Smart folder detection**: Suggests appropriate folder based on content

### Snippet Operations
```
Right-click any snippet:
├── 📋 Copy to Clipboard
├── 📝 Edit Content...
├── 🏷️ Rename...
├── 📋 Duplicate
├── ───────────────────
├── 📁 Move to Folder ▶
├── ⭐ Add to Favorites
├── 🏷️ Edit Tags...
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

### Snippet Workflow Manager
```python
class SnippetWorkflowManager:
    def __init__(self, parent_window):
        self.window = parent_window
        self.name_suggester = NameSuggester()

    def save_as_snippet(self, content=None):
        # Open complete save workflow dialog
        if content is None:
            content = pyperclip.paste()

        dialog = SnippetSaveDialog(
            content=content,
            suggested_name=self.name_suggester.suggest(content),
            existing_folders=self.get_folders()
        )
        return dialog.show()

    def quick_save_from_history(self, clip_item):
        # Right-click save from history item
        return self.save_as_snippet(clip_item.content)

    def drag_drop_save(self, clip_content, target_folder):
        # Handle drag & drop to folder
        name_dialog = QuickNameDialog(clip_content, target_folder)
        return name_dialog.show()

class NameSuggester:
    def suggest(self, content):
        # AI-powered name suggestion based on content
        # - Detect email templates, code, URLs, etc.
        # - Extract meaningful phrases
        # - Learn from user patterns
        pass

class SnippetSaveDialog:
    def __init__(self, content, suggested_name, existing_folders):
        self.content = content
        self.suggested_name = suggested_name
        self.folders = existing_folders
        self.create_dialog()

    def create_dialog(self):
        # Create the complete save workflow dialog
        # - Content preview
        # - Name field with suggestion
        # - Folder dropdown + create new option
        # - Tags field
        # - Save/Cancel buttons
        pass
```

### Drag & Drop Manager
```python
class DragDropManager:
    def __init__(self, left_column, right_column):
        self.left_column = left_column
        self.right_column = right_column
        self.setup_drag_drop()

    def setup_drag_drop(self):
        # Enable drag from left column items
        # Enable drop on right column folders
        pass

    def on_drag_start(self, clip_item):
        # Visual feedback for drag operation
        pass

    def on_drop_hover(self, folder):
        # Highlight drop zones
        pass

    def on_drop_complete(self, clip_item, target_folder):
        # Complete the save workflow
        workflow = SnippetWorkflowManager(self.parent)
        workflow.drag_drop_save(clip_item.content, target_folder)
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

    def get_snippet_settings(self):
        # Return settings for snippet behavior
        # - Auto-name suggestions on/off
        # - Default folder behavior
        # - Tag suggestions
        pass
```

## Implementation Priority

### Phase 1: Core Window Framework
1. ✅ Window with header bar (title + gear icon)
2. 🔍 Always-visible search bar
3. 💾 Control bar with "Save as Snippet" button
4. 📋 Basic two-column layout

### Phase 2: Snippet Workflow (Key Feature)
1. 💾 Complete "Save as Snippet" dialog
2. 🤖 Smart name suggestion system
3. 📁 Folder creation within snippet workflow
4. 🏷️ Tags and organization features
5. 📋 Quick save buttons on history items

### Phase 3: Advanced Interactions
1. 🖱️ Drag & drop from history to folders
2. 👆 Right-click context menus
3. 🔍 Real-time search filtering
4. 📂 Folder expand/collapse functionality

### Phase 4: History Management
1. 📋 Auto-generated history folders (11-20, 21-30, etc.)
2. 📊 History size configuration
3. 🗑️ History management features
4. 💾 Data persistence and loading

### Phase 5: Polish & Settings
1. ⚙️ Multi-tab settings window
2. 🎨 Theme system (light/dark/auto)
3. ⌨️ Global keyboard shortcuts
4. 📤 Import/export functionality
5. 🎨 Folder icons and customization

**Key Priority**: The snippet workflow (Phase 2) is the **core differentiator** and should be implemented early to validate the user experience.

This header-based design is **much more professional** and provides better organization of controls while maintaining the two-column efficiency!
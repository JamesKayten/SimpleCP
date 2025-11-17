# SimpleCP - UI/UX Specification v2 (Two-Column Layout)

This document defines the **two-column interface** for SimpleCP - a modern, Finder-style layout that's much more user-friendly than traditional dropdown menus.

## Menu Bar Icon

**Icon:** 📋 (clipboard emoji)
**Behavior:** Click to open two-column interface window
**Window Style:** Floating window, similar to Spotlight or Alfred

## Two-Column Interface Layout

```
┌─────────────────────────────────────────────────────────┐
│ 📋 SimpleCP                                        [ X ] │
├─────────────────────┬───────────────────────────────────┤
│ 📋 RECENT CLIPS     │ 📁 SAVED SNIPPETS               │
│                     │                                   │
│ 1. "Latest clip..." │ 📁 Email Templates               │
│ 2. "Second clip..." │   ├── Meeting Request            │
│ 3. "Third clip..."  │   ├── Follow Up                  │
│ 4. "Fourth clip..." │   └── Thank You                  │
│ 5. "Fifth clip..."  │                                   │
│ 6. "Sixth clip..."  │ 📁 Code Snippets                 │
│ 7. "Seventh..."     │   ├── Python Main                │
│ 8. "Eighth..."      │   ├── Git Commit                 │
│ 9. "Ninth..."       │   └── Docker Run                 │
│ 10. "Tenth..."      │                                   │
│ ──────────────────  │ 📁 Common Text                   │
│ 📁 11 - 20         │   ├── Email Signature            │
│ 📁 21 - 30         │   └── Lorem Ipsum                │
│ 📁 31 - 40         │                                   │
│ 📁 41 - 50         │ ➕ Create New Folder...           │
│                     │                                   │
│                     │                                   │
└─────────────────────┴───────────────────────────────────┘
```

## Left Column: Recent Clips

### Direct Clips Display (Top 10)
- **Always visible**: Most recent 10 clipboard items
- **Numbered**: "1. Preview text...", "2. Next item..."
- **Click behavior**: Copy to clipboard and close window
- **Text truncation**: Fit within column width (~40 characters)
- **Visual**: Clean list, easy scanning

### Auto-Generated History Folders
- **Below the top 10**: Folders for older clips
- **Automatic creation**: Based on user's history size setting
- **Naming pattern**: "11 - 20", "21 - 30", "31 - 40", etc.
- **Folder size**: User-configurable (default: 10 clips per folder)
- **Hover behavior**: Show submenu with clips in that range
- **Empty folders**: Hidden until they contain clips

### Example with 50-item history:
```
📋 RECENT CLIPS
1. "Most recent..."
2. "Second recent..."
...
10. "Tenth recent..."
──────────────────
📁 11 - 20  (hover shows submenu)
📁 21 - 30  (hover shows submenu)
📁 31 - 40  (hover shows submenu)
📁 41 - 50  (hover shows submenu)
```

### Hover Submenu for History Folders:
```
📁 11 - 20 ──▶ ┌─────────────────────┐
               │ 11. "Clip text..."  │
               │ 12. "Another..."    │
               │ 13. "Third..."      │
               │ ...                 │
               │ 20. "Last in..."    │
               └─────────────────────┘
```

## Right Column: Saved Snippets

### User-Created Folders
- **Custom names**: User can name folders anything
- **Unlimited folders**: Create as many as needed
- **Expandable**: Click to expand/collapse folder contents
- **Drag & drop**: Drag clips from left column to save
- **Right-click**: Context menu for folder operations

### Folder Structure:
```
📁 Email Templates
  ├── Meeting Request
  ├── Follow Up
  └── Thank You

📁 Code Snippets
  ├── Python Main
  ├── Git Commit
  └── Docker Run

📁 Common Text
  ├── Email Signature
  └── Lorem Ipsum

➕ Create New Folder...
```

### Folder Operations:
- **Create**: Click "➕ Create New Folder..."
- **Rename**: Right-click folder → "Rename..."
- **Delete**: Right-click folder → "Delete Folder"
- **Add snippet**: Drag from left or right-click → "Add to [Folder]..."

## User Interactions

### Copying Clips/Snippets
- **Left column clips**: Single click copies and closes window
- **Right column snippets**: Single click copies and closes window
- **Keyboard navigation**: Arrow keys + Enter

### Adding Snippets
1. **Drag & Drop**: Drag any clip from left column to right column folder
2. **Right-click**: Right-click any clip → "Save to..." → Choose folder
3. **Current clipboard**: Right-click folder → "Add current clipboard..."

### Managing History Size
```
User sets: "Keep 50 clips in history"
App automatically creates:
- Direct display: 1-10
- 📁 11-20
- 📁 21-30
- 📁 31-40
- 📁 41-50

User changes to: "Keep 30 clips in history"
App automatically adjusts:
- Direct display: 1-10
- 📁 11-20
- 📁 21-30
(Folders 31-40, 41-50 disappear)
```

## Window Behavior

### Opening/Closing
- **Open**: Click menu bar icon or global hotkey
- **Close**: Click outside window, Esc key, or copy something
- **Size**: Fixed width, height adapts to content
- **Position**: Center of screen or remember last position

### Visual Design
- **Modern macOS style**: Clean, minimal
- **Two-column split**: 50/50 or 60/40 (left wider)
- **Separators**: Subtle lines between sections
- **Icons**: Folder emojis (📁) and clipboard (📋)
- **Hover effects**: Subtle highlighting

## Settings/Preferences

```
⚙️ SimpleCP Preferences

History Settings:
☑ Keep clipboard history
Total clips to remember: [50    ] ↕
Clips per folder: [10    ] ↕
Show timestamps: ☐

Window Settings:
Position: ○ Center ● Remember last position
Size: ○ Compact ● Normal ○ Large

Shortcuts:
Open SimpleCP: [⌘⇧V] [Set]
Clear history: [⌘⇧C] [Set]

[ Save ]  [ Cancel ]  [ Reset to Defaults ]
```

## Implementation Architecture

### Core Classes Needed

#### HistoryManager
```python
class HistoryManager:
    def __init__(self, max_items=50, items_per_folder=10):
        self.max_items = max_items
        self.items_per_folder = items_per_folder

    def get_recent_items(self, count=10):
        # Return first 10 items for direct display

    def get_folder_ranges(self):
        # Return list like [(11,20), (21,30), (31,40)]

    def get_items_in_range(self, start, end):
        # Return clips 11-20, 21-30, etc.
```

#### SnippetManager
```python
class SnippetManager:
    def create_folder(self, name):
        # Create new user folder

    def add_to_folder(self, folder_name, clip):
        # Save clip to specific folder

    def get_folders(self):
        # Return all user folders with contents
```

#### WindowManager
```python
class WindowManager:
    def show_two_column_interface(self):
        # Create and display the two-column window

    def update_left_column(self):
        # Refresh recent clips and folder structure

    def update_right_column(self):
        # Refresh saved snippets
```

### Technical Implementation (rumps + tkinter)

Since rumps is designed for simple dropdown menus, we'll need to use **tkinter** or **PyQt** for the two-column interface:

```python
import rumps
import tkinter as tk

class SimpleCP(rumps.App):
    def __init__(self):
        super().__init__("📋")
        self.window = None

    @rumps.clicked("Open SimpleCP")
    def open_interface(self, _):
        if not self.window:
            self.window = TwoColumnWindow()
        self.window.show()

class TwoColumnWindow:
    def __init__(self):
        self.root = tk.Tk()
        self.setup_two_column_layout()
```

## Implementation Priority

### Phase 1: Window Framework
1. Create tkinter two-column window
2. Basic layout with left/right panes
3. Menu bar integration (rumps + tkinter)

### Phase 2: Left Column (History)
1. Display recent 10 clips
2. Auto-generate history folders
3. Hover submenus for folder contents
4. Click to copy functionality

### Phase 3: Right Column (Snippets)
1. User folder creation/management
2. Snippet saving and organization
3. Expand/collapse folders
4. Drag & drop between columns

### Phase 4: Polish
1. Preferences window
2. Keyboard shortcuts
3. Visual refinements
4. Data persistence

This two-column design is **much more professional** and will provide a far better user experience than a traditional dropdown menu!
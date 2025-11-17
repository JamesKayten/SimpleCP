# SimpleCP - UI/UX Specification

This document defines how SimpleCP should look and behave. Web Claude should follow this specification when implementing the menu interface and user interactions.

## Menu Bar Icon

**Icon:** 📋 (clipboard emoji)
**Behavior:** Click to open dropdown menu
**Visual State:** No special states (keep simple)

## Main Menu Structure

The dropdown menu is organized into clear tabbed sections:

```
📋 SimpleCP
├── 📋 Recent Clips
│   ├── 1. "Latest clipboard item preview..."
│   ├── 2. "Second most recent item..."
│   ├── 3. "Third clipboard item..."
│   ├── ... (up to 10 recent items)
│   └── ───────────────────── (separator)
├── 📁 Snippet Folders
│   ├── 📁 Email Templates ▶
│   │   ├── Meeting Request
│   │   ├── Follow Up
│   │   └── Add to Email Templates...
│   ├── 📁 Code Snippets ▶
│   │   ├── Python Main
│   │   ├── Git Commit
│   │   └── Add to Code Snippets...
│   ├── 📁 Common Text ▶
│   │   ├── Email Signature
│   │   └── Add to Common Text...
│   ├── ───────────────────── (separator)
│   └── ➕ Create New Folder...
├── ─────────────────────────── (separator)
├── 🔍 Search Clips & Snippets...
├── ⚙️ Preferences...
├── 🗑️ Clear History
└── ❌ Quit SimpleCP
```

## Navigation Behavior

### 1. Nested Submenus (Chosen)
- **Folders with ▶ indicator** become submenus on hover
- **Hover delay**: 500ms before submenu opens
- **Visual feedback**: Highlight folder when hovered
- **Submenu positioning**: Right side of parent menu item

### 2. Menu Items with Numbers
- **Recent clips numbered**: "1. Preview text...", "2. Next item..."
- **Click behavior**: Immediately copy to clipboard and close menu
- **Preview length**: 50 characters max with "..." truncation

### 3. Snippet Organization
- **Folders always shown**, even if empty
- **"Add to [Folder]..." option** at bottom of each submenu
- **Alphabetical sorting** of both folders and snippets within folders

## User Interactions

### Adding New Snippets (Multiple Methods Chosen)

#### Method 1: Right-Click Context Menu
```
Right-click on any recent clip item:
├── Copy Again
├── ───────────
├── 📁 Save to Folder ▶
│   ├── 📁 Email Templates
│   ├── 📁 Code Snippets
│   ├── 📁 Common Text
│   ├── ───────────────
│   └── ➕ Create New Folder...
└── 🗑️ Remove from History
```

#### Method 2: Dedicated Menu Item
- **"Add to [Folder]..."** at bottom of each folder submenu
- **Opens dialog**: Name, content (pre-filled with current clipboard)

#### Method 3: Keyboard Shortcuts
- **⌘⇧S**: Save current clipboard to folder (opens folder picker)
- **⌘⇧V**: Open SimpleCP menu (global hotkey)
- **⌘⇧C**: Clear clipboard history

### Search Functionality
```
🔍 Search Clips & Snippets...
│
└── Opens search dialog:
    ┌─────────────────────────────┐
    │ Search: [____________]      │
    │                             │
    │ Results:                    │
    │ 📋 "matching history item"  │
    │ 📁 Email > Meeting Request  │
    │ 📁 Code > Python Main       │
    └─────────────────────────────┘
```

### Folder Management
```
➕ Create New Folder...
│
└── Opens dialog:
    ┌─────────────────────────────┐
    │ Folder Name: [___________]  │
    │                             │
    │ [ Create ]  [ Cancel ]      │
    └─────────────────────────────┘
```

## Visual Design Guidelines

### Menu Styling
- **Font**: System font (SF Pro on macOS)
- **Size**: Standard menu item height
- **Icons**: Emoji for visual hierarchy (📋 📁 ⚙️ 🗑️ ❌)
- **Separators**: Thin lines to group sections
- **Hover**: System blue highlight

### Text Truncation
- **Clip previews**: 50 characters + "..."
- **Snippet names**: 30 characters + "..."
- **Folder names**: 25 characters + "..."
- **Clean whitespace**: Replace \n and \t with spaces

### Section Headers
```
📋 Recent Clips          (not clickable, visual separator)
📁 Snippet Folders       (not clickable, visual separator)
```

## User Workflows

### 1. Quick Paste from History
```
User copies something →
Click 📋 icon →
Click numbered item →
Text copied to clipboard & menu closes
```

### 2. Save to Snippet Folder
```
User has text in clipboard →
Click 📋 icon →
Right-click recent item →
"Save to Folder" → Choose folder →
Opens dialog to name snippet →
Saved for reuse
```

### 3. Use Saved Snippet
```
Click 📋 icon →
Hover "Email Templates" folder →
Click "Meeting Request" →
Text copied to clipboard & menu closes
```

### 4. Search Everything
```
Click 📋 icon →
Click "Search Clips & Snippets..." →
Type search term →
Click result →
Text copied to clipboard
```

## Settings/Preferences Window

```
⚙️ Preferences... → Opens window:

┌─────────────────────────────────────┐
│ SimpleCP Preferences                │
├─────────────────────────────────────┤
│ General:                            │
│ ☑ Start with macOS                  │
│ ☑ Show timestamps in history        │
│                                     │
│ History:                            │
│ Max items: [50      ] ↕             │
│ Preview length: [50      ] ↕        │
│                                     │
│ Shortcuts:                          │
│ Open menu: [⌘⇧V    ] [Set]         │
│ Quick save: [⌘⇧S   ] [Set]         │
│                                     │
│ [ Save ]  [ Cancel ]  [ Defaults ]  │
└─────────────────────────────────────┘
```

## Implementation Priority

### Phase 1: Basic Menu Structure
1. ✅ Menu bar icon and dropdown
2. 📋 Recent clips section with numbered items
3. 📁 Static snippet folders section
4. ⚙️ Basic menu items (Preferences, Clear, Quit)

### Phase 2: Core Functionality
1. 💾 HistoryStore with proper truncation and numbering
2. 📁 SnippetStore with folder/snippet management
3. 🖱️ Click handlers for copying items
4. 💾 Persistence (save/load from JSON)

### Phase 3: Advanced Features
1. ▶ Nested submenus for folders
2. ➕ Add snippet functionality (dialog boxes)
3. 🔍 Search interface
4. ⌨️ Keyboard shortcuts
5. 🎛️ Preferences window

### Phase 4: Polish
1. 🎨 Right-click context menus
2. 🗑️ Delete/rename snippets and folders
3. 📤 Import/export functionality
4. 🔧 Advanced settings

## Technical Implementation Notes

### For Web Claude:
- **Use rumps.MenuItem()** for all menu items
- **Use rumps.separator** for visual dividers
- **Implement hover submenus** with rumps submenu functionality
- **Create dialogs** using rumps.alert() and rumps.window()
- **Handle right-clicks** with custom event handlers
- **Store UI state** in Settings class for persistence

### Key Classes Needed:
- **MenuBuilder**: Generates the dynamic menu structure
- **DialogManager**: Handles input dialogs and preferences
- **ShortcutManager**: Global hotkey registration
- **SnippetManager**: CRUD operations for snippets/folders

This specification provides clear guidance for implementing SimpleCP's interface while maintaining the simple, non-subscription-based goal!
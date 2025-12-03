# Clipboard Manager Project Handover

## Project Goal
Create a simple macOS menu bar clipboard manager application with snippet folders functionality, because existing options are subscription-based or over-developed.

## Requirements Gathered
- **Platform**: macOS only
- **Interface**: Menu bar app (system tray with dropdown)
- **Core Feature**: Snippet folders for reusable clips
- **Additional Features**: Text history, search/filter, persistence

## Technical Research Completed

### Flycut Analysis
I analyzed the open-source Flycut repository (https://github.com/TermiT/Flycut) which is a mature clipboard manager with:

**Architecture (58k lines Objective-C):**
- `AppController` - Main UI controller (menu bar, hotkeys, bezel display)
- `FlycutOperator` - Core business logic managing multiple stores
- `FlycutStore` - Data model for collections of clippings
- `FlycutClipping` - Individual clipboard items with metadata

**Key Finding:** Flycut already has a "favorites" system with separate `clippingStore` (history) and `favoritesStore` (saved items), but no folder organization.

**Decision:** Rather than extend the complex Objective-C codebase, build our own Python version inspired by Flycut's solid architecture.

## Recommended Architecture

### Technology Stack
- **rumps** - Python menu bar apps for macOS
- **pyperclip** - Clipboard monitoring and manipulation
- **JSON files** - Simple persistence (easy backup/sync)
- **Python 3** - Cross-platform, easy to maintain

### Core Components Design

```
ClipboardManager (main app class)
├── HistoryStore (recent clipboard history)
├── SnippetStore (organized snippet folders)
├── MenuBuilder (dynamic menu generation)
└── Settings (preferences and persistence)
```

### Key Classes Needed

1. **ClipboardManager**
   - Main rumps.App subclass
   - Clipboard polling timer
   - Hotkey registration
   - Menu bar icon and dropdown

2. **HistoryStore**
   - List of recent clipboard items
   - Automatic deduplication
   - Configurable history length
   - Search functionality

3. **SnippetStore**
   - Folder-based organization
   - CRUD operations for folders/snippets
   - Import/export functionality
   - Search across snippets

4. **ClipboardItem**
   - Text content
   - Timestamp
   - Source application
   - Type (history vs snippet)

5. **Settings**
   - JSON-based configuration
   - Hotkey preferences
   - Display settings
   - Persistence management

## Environment Setup Completed
- Installed required packages: `rumps==0.4.0`, `pyperclip==1.11.0`
- Project directory created at: `/Volumes/User_Smallfavor/Users/Smallfavor/clipboard_manager/`
- Flycut repository cloned for reference

## Current Status
- ✅ Requirements gathered
- ✅ Technology research completed
- ✅ Architecture designed
- ✅ Dependencies installed
- 🔄 Ready to start implementation

## Next Steps for Implementation

### Phase 1: Basic Framework
1. Create main `ClipboardManager` class with rumps
2. Implement basic menu bar presence
3. Add clipboard monitoring timer
4. Create simple text display in menu

### Phase 2: History System
1. Implement `HistoryStore` class
2. Add clipboard change detection
3. Store recent items with metadata
4. Display history in menu dropdown

### Phase 3: Snippet Folders
1. Design folder data structure
2. Implement `SnippetStore` class
3. Add folder creation/management
4. Integrate folders into menu system

### Phase 4: Polish
1. Add search functionality
2. Implement settings/preferences
3. Add hotkey support
4. Create app icons and packaging

## File Structure Planned
```
clipboard_manager/
├── main.py                 # Entry point
├── clipboard_manager.py    # Main app class
├── stores/
│   ├── __init__.py
│   ├── history_store.py    # Recent clipboard history
│   ├── snippet_store.py    # Organized snippets
│   └── clipboard_item.py   # Data model
├── ui/
│   ├── __init__.py
│   └── menu_builder.py     # Menu generation
├── settings.py             # Configuration management
├── data/
│   ├── history.json        # Recent items
│   ├── snippets.json       # Snippet folders
│   └── config.json         # App settings
└── assets/
    └── icon.png           # Menu bar icon
```

## Code to Start With

Since dependencies are already installed, you can begin with this basic structure:

```python
import rumps
import pyperclip
import json
import os
from datetime import datetime

class ClipboardManager(rumps.App):
    def __init__(self):
        super(ClipboardManager, self).__init__("📋", quit_button=None)
        self.clipboard_history = []
        self.snippet_folders = {}
        self.current_clipboard = ""

    @rumps.timer(1)  # Check clipboard every second
    def check_clipboard(self, _):
        try:
            current = pyperclip.paste()
            if current != self.current_clipboard and current.strip():
                self.current_clipboard = current
                self.add_to_history(current)
                self.update_menu()
        except:
            pass

    def add_to_history(self, text):
        # Add implementation here
        pass

    def update_menu(self):
        # Add implementation here
        pass

if __name__ == "__main__":
    app = ClipboardManager()
    app.run()
```

## Context for Web Claude
"I want to continue building a macOS clipboard manager with snippet folders. I've already analyzed Flycut and chosen Python with rumps for the implementation. Please continue from Phase 1 of the implementation plan above."

---

**Ready to hand over! Copy everything above to continue in web Claude.**
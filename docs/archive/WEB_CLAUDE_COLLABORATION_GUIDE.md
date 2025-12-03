# Web Claude Collaboration Guide for SimpleCP

This guide helps web Claude continue development of SimpleCP clipboard manager.

## Project Overview

**SimpleCP** is a simple macOS menu bar clipboard manager with snippet folders, built because existing solutions are subscription-based or over-developed.

## Current Status

✅ **Completed Setup**
- Project structure created
- Git repository initialized
- Dependencies identified (`rumps`, `pyperclip`)
- Basic framework started
- All files use "SimpleCP" as the app name

🔄 **Ready for Implementation**
- Core functionality needs to be built
- Snippet folders system to be implemented
- Menu management to be enhanced

## Repository Structure

```
clipboard_manager/
├── main.py                     # ✅ Entry point
├── clipboard_manager.py        # 🔄 Main app class (basic framework)
├── stores/
│   ├── __init__.py            # ✅ Package init
│   ├── history_store.py       # 📝 TODO: Implement HistoryStore
│   ├── snippet_store.py       # 📝 TODO: Implement SnippetStore
│   └── clipboard_item.py      # ✅ Data model complete
├── ui/
│   ├── __init__.py            # ✅ Package init
│   └── menu_builder.py        # 📝 TODO: Implement MenuBuilder
├── settings.py                 # 📝 TODO: Implement Settings
├── data/
│   ├── example_*.json         # ✅ Example data formats
│   └── (actual data files will be gitignored)
└── docs/
    └── (documentation files)
```

## Technologies Used

- **rumps** - Python macOS menu bar apps
- **pyperclip** - Clipboard operations
- **JSON** - Data persistence
- **Python 3.7+** - Core language

## Next Implementation Steps

### Priority 1: Core Functionality
1. **Complete HistoryStore class** (`stores/history_store.py`)
   - Automatic deduplication
   - Size limits
   - Search functionality

2. **Enhance ClipboardManager** (`clipboard_manager.py`)
   - Better clipboard monitoring
   - Improved menu updates
   - Error handling

### Priority 2: Snippet Folders
1. **Implement SnippetStore class** (`stores/snippet_store.py`)
   - Folder-based organization
   - CRUD operations
   - Import/export

2. **Create MenuBuilder class** (`ui/menu_builder.py`)
   - Dynamic menu generation
   - Folder navigation
   - Search integration

### Priority 3: Settings & Polish
1. **Implement Settings class** (`settings.py`)
   - JSON configuration
   - Hotkey management
   - User preferences

2. **Add advanced features**
   - Keyboard shortcuts
   - Search functionality
   - App icons

## Current Working Code

The `clipboard_manager.py` has a basic working framework with:
- ✅ Menu bar presence
- ✅ Clipboard monitoring timer
- ✅ Basic history management
- ✅ JSON persistence
- ✅ Simple menu updates

## Development Workflow

### To Start Development:
```bash
cd clipboard_manager
git status
git pull origin main  # If working on existing repo

# Test current functionality:
python3 main.py

# Make your changes, then:
git add .
git commit -m "feat: description of your changes"
git push origin main  # If pushing to remote
```

### Testing the App
```bash
# Install dependencies (if not already installed):
pip3 install rumps pyperclip

# Run the app:
python3 main.py

# The app will appear in the macOS menu bar with a 📋 icon
```

## Key Implementation Notes

1. **Menu Bar App**: Uses rumps for macOS menu bar integration
2. **Clipboard Monitoring**: Timer checks clipboard every second
3. **Data Storage**: JSON files in `data/` directory (gitignored)
4. **Error Handling**: Wrap clipboard operations in try/catch
5. **File System Safety**: "SimpleCP" name avoids special characters

## Code Style Guidelines

- Use type hints where helpful
- Add docstrings to classes and methods
- Keep functions focused and small
- Use descriptive variable names
- Handle exceptions gracefully

## Architecture Inspiration

Based on analysis of [Flycut](https://github.com/TermiT/Flycut):
- **AppController** → `ClipboardManager`
- **FlycutStore** → `HistoryStore` + `SnippetStore`
- **FlycutClipping** → `ClipboardItem`

## Common Tasks

### Add New Menu Item
```python
# In clipboard_manager.py
menu_item = rumps.MenuItem("New Item", callback=self.handle_item)
self.menu.add(menu_item)
```

### Save/Load Data
```python
# JSON persistence is already set up
self.save_data()  # Saves both history and snippets
self.load_data()  # Loads both history and snippets
```

### Handle Clipboard Changes
```python
# The check_clipboard timer method handles this
# Modify add_to_history() for custom behavior
```

## Ready to Code!

The foundation is solid. Focus on implementing the core classes:
1. **HistoryStore** for clipboard history
2. **SnippetStore** for organized snippets
3. **MenuBuilder** for dynamic menus

The basic app framework is working and ready for enhancement!

---

**Need Help?** Check the example data files in `data/` for expected JSON formats.
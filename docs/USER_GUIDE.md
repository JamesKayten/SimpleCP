# SimpleCP User Guide

Complete guide to using SimpleCP, the intelligent clipboard manager for macOS.

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Core Features](#core-features)
- [Clipboard History](#clipboard-history)
- [Snippets](#snippets)
- [Search](#search)
- [Settings & Configuration](#settings--configuration)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Tips & Tricks](#tips--tricks)
- [FAQ](#faq)

---

## Introduction

### What is SimpleCP?

SimpleCP is a powerful clipboard manager inspired by Flycut that helps you:
- **Never lose clipboard data** - Keeps up to 50 recent items
- **Organize snippets** - Save frequently used text for quick access
- **Search instantly** - Find any copied item in seconds
- **Boost productivity** - Access clipboard history with one click

### Key Features

✨ **Smart History Management**
- Automatic clipboard monitoring
- Up to 50 recent items saved
- Intelligent content type detection (text, code, URLs, JSON)

📁 **Snippet Organization**
- Create custom folders
- Name and categorize snippets
- Quick access from menu bar

🔍 **Powerful Search**
- Search across history and snippets
- Case-insensitive matching
- Instant results

⚡ **Fast & Lightweight**
- Menu bar integration
- Low memory footprint
- Background clipboard monitoring

🛡️ **Privacy First**
- All data stored locally
- No cloud sync required
- Optional crash reporting

---

## Installation

### Requirements

- **Operating System**: macOS 10.14 or later
- **Python**: 3.9 or higher
- **Memory**: 50MB RAM minimum
- **Disk Space**: 10MB for application + data

### Installation Steps

#### Option 1: From Release (Recommended)

1. Download the latest release from GitHub
2. Open the `.dmg` file
3. Drag SimpleCP to Applications folder
4. Launch SimpleCP from Applications

#### Option 2: From Source

```bash
# Clone repository
git clone https://github.com/YourUsername/SimpleCP.git
cd SimpleCP

# Install dependencies
pip install -r requirements.txt

# Run daemon
python daemon.py
```

### First Launch

1. **Launch SimpleCP** from Applications or Launchpad
2. **Grant Permissions** when prompted:
   - Accessibility access (for clipboard monitoring)
   - Full Disk Access (for data storage)
3. **Check Menu Bar** - SimpleCP icon appears in menu bar
4. **Configure Settings** (optional) - Click icon → Preferences

---

## Getting Started

### Quick Start Tutorial

#### Step 1: Copy Something

Copy any text normally (⌘+C). SimpleCP automatically saves it.

#### Step 2: Access History

Click SimpleCP menu bar icon to see recent clipboard items.

#### Step 3: Paste from History

Click any item to copy it to clipboard, then paste (⌘+V).

#### Step 4: Save as Snippet (Optional)

Right-click an item → "Save as Snippet" to keep it permanently.

### Understanding the Interface

#### Menu Bar Icon

**SimpleCP Icon States**:
- 📋 Normal: Ready and monitoring
- ⚠️ Warning: Configuration issue
- ❌ Error: Not running properly

**Click Icon to Open**:
- Recent clipboard items (last 10)
- Search bar
- Snippets folder
- Settings
- Quit option

#### Main Window

**Sections**:
1. **Recent Items** (top): Last 10 clipboard items
2. **History Folders**: Grouped older items (11-20, 21-30, etc.)
3. **Snippets**: Your saved items organized by folder
4. **Search**: Find anything instantly

---

## Core Features

### Automatic Clipboard Monitoring

SimpleCP continuously monitors your clipboard in the background.

**What Gets Saved**:
- ✅ Text content
- ✅ Code snippets
- ✅ URLs
- ✅ JSON data
- ✅ Formatted text

**What Doesn't Get Saved**:
- ❌ Images (currently)
- ❌ Files
- ❌ Empty clipboard
- ❌ Duplicate consecutive items

**Performance**:
- Checks every 1 second (configurable)
- Minimal CPU usage (<1%)
- Low memory footprint

### Content Type Detection

SimpleCP automatically detects content types:

| Type | Detection | Example |
|------|-----------|---------|
| **URL** | http://, https:// | https://example.com |
| **Code** | Multiple lines with indentation | def hello():\n    pass |
| **JSON** | Valid JSON format | {"key": "value"} |
| **Text** | Default for everything else | Regular text |

**Benefits**:
- Better organization
- Syntax-aware display
- Smart formatting

### Storage & Limits

**History Limits**:
- Maximum items: 50 (configurable)
- Oldest items automatically removed
- Recent 10 items always shown

**Snippet Storage**:
- Unlimited snippets
- Organized in folders
- Persistent across restarts

**Data Storage**:
- Location: `~/Library/Application Support/SimpleCP/`
- Format: JSON files
- Backup: Automatic on quit

---

## Clipboard History

### Viewing History

**Recent Items** (Last 10):
1. Click menu bar icon
2. See most recent 10 items at top
3. Click any item to copy to clipboard

**Older Items**:
1. Click "History Folders"
2. Browse by range (11-20, 21-30, etc.)
3. Click to expand folder
4. Click item to copy

**Full History**:
1. Open main window
2. Click "View All History"
3. Scroll through all items
4. Use search to filter

### Managing History

**Copy Item**:
- Click item → automatically copied to clipboard
- Or right-click → "Copy to Clipboard"

**Delete Item**:
- Right-click item → "Delete"
- Or swipe left (trackpad gesture)
- Confirmation prompt shown

**Clear All History**:
- Menu bar → "Clear History"
- Or Settings → "Clear All History"
- ⚠️ This cannot be undone!

**Save as Snippet**:
- Right-click item → "Save as Snippet"
- Choose folder
- Enter name (optional)
- Snippet created and saved

### History Display

Each item shows:
- **Content Preview**: First 50 characters
- **Type Icon**: 📝 Text, 💻 Code, 🔗 URL, 📊 JSON
- **Timestamp**: When copied
- **Source App**: Where it was copied from

**Display Format**:
```
💻 def hello():           [2 min ago] [VSCode]
🔗 https://github.com     [5 min ago] [Safari]
📝 Hello World            [10 min ago] [Notes]
```

---

## Snippets

### What are Snippets?

Snippets are saved clipboard items you want to keep permanently:
- **Never expire** - Stay until you delete them
- **Organized in folders** - Group by category
- **Named** - Give meaningful names
- **Quick access** - One click to copy

### Creating Snippets

#### Method 1: From History

1. Find item in history
2. Right-click → "Save as Snippet"
3. Select folder (or create new)
4. Enter name
5. Click "Save"

#### Method 2: Direct Entry

1. Click menu bar icon → "New Snippet"
2. Enter content
3. Choose folder
4. Enter name
5. Click "Create"

#### Method 3: Via API

```bash
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Your snippet content",
    "folder_name": "Work",
    "name": "Important Note"
  }'
```

### Organizing Snippets

**Folder Structure**:
```
📁 Work
  ├── 📝 Email Signatures
  ├── 💻 Code Templates
  └── 📊 SQL Queries

📁 Personal
  ├── 📝 Addresses
  ├── 🔗 Favorite Links
  └── 📝 Phone Numbers

📁 Code
  ├── 💻 Python Snippets
  ├── 💻 JavaScript Snippets
  └── 💻 Shell Commands
```

**Managing Folders**:
- **Create**: Click "+" next to Snippets
- **Rename**: Right-click folder → "Rename"
- **Delete**: Right-click folder → "Delete" (deletes contents!)
- **Reorder**: Drag and drop (coming soon)

### Using Snippets

**Copy to Clipboard**:
1. Browse to snippet
2. Click to copy
3. Paste anywhere (⌘+V)

**Edit Snippet**:
1. Right-click snippet → "Edit"
2. Modify content or name
3. Click "Save"

**Move Snippet**:
1. Right-click snippet → "Move to..."
2. Select destination folder
3. Snippet moved

**Delete Snippet**:
1. Right-click snippet → "Delete"
2. Confirm deletion
3. Snippet removed permanently

### Snippet Best Practices

✅ **DO**:
- Use descriptive names
- Organize by category
- Regular cleanup of unused snippets
- Back up important snippets

❌ **DON'T**:
- Store sensitive data (passwords, API keys)
- Create too many folders (keep it simple)
- Use very long snippet names
- Forget to backup before major changes

---

## Search

### Search Functionality

**Search Scope**:
- ✅ All clipboard history
- ✅ All snippets across folders
- ✅ Content matching
- ✅ Case-insensitive

**Search Location**:
- Menu bar → Search field
- Main window → Search bar at top
- Keyboard shortcut: ⌘+F (in main window)

### Using Search

**Basic Search**:
1. Click search field
2. Type query
3. Results appear instantly
4. Click result to copy

**Search Tips**:
- **Partial matching**: "hell" matches "hello"
- **Case insensitive**: "HELLO" = "hello" = "Hello"
- **Multiple words**: Searches for all words
- **Special chars**: Include in search query

**Search Results**:
```
History Results (3):
  💻 def hello():...
  📝 Hello world message
  🔗 https://hello.com

Snippet Results (2):
  📝 Hello Email Template [Work]
  💻 Hello World Code [Code]
```

### Advanced Search

**Filter by Type**:
- Coming soon: Filter by content type
- Coming soon: Filter by date range
- Coming soon: Filter by source app

**Search Shortcuts**:
- `⌘+F`: Open search
- `↓/↑`: Navigate results
- `Enter`: Copy selected result
- `Esc`: Close search

---

## Settings & Configuration

### Accessing Settings

**Via Menu Bar**:
1. Click SimpleCP icon
2. Click "Preferences" or "Settings"
3. Configure options

**Via Config File**:
Edit `.env` file in application directory.

### General Settings

**Clipboard Monitoring**:
- Enable/Disable automatic monitoring
- Check interval (default: 1 second)
- Monitor all apps vs specific apps

**History Settings**:
- Maximum history items (default: 50)
- Display count in menu (default: 10)
- Auto-clean old items

**Storage Settings**:
- Data directory location
- Automatic backup frequency
- Data retention period

### Display Settings

**Menu Bar**:
- Show/hide icon
- Icon style (light/dark mode)
- Show item count badge

**Display Format**:
- Preview length (characters)
- Show timestamps
- Show source app
- Show content type icons

### Privacy & Security

**Data Privacy**:
- All data stored locally
- No cloud sync by default
- Optional encryption (coming soon)

**Monitoring Exclusions**:
- Exclude specific apps
- Exclude password managers
- Exclude private browsing

**Crash Reporting**:
- Enable Sentry (optional)
- Anonymous error reporting
- Helps improve SimpleCP

### Advanced Settings

**Performance**:
- Memory limit
- Cache size
- Cleanup frequency

**Logging**:
- Log level (DEBUG, INFO, WARNING, ERROR)
- Log to file (yes/no)
- Log file location

**API Server**:
- Enable/disable REST API
- API port (default: 8000)
- CORS origins

### Configuration File

**Location**: `SimpleCP/.env`

**Example**:
```env
# General
MAX_HISTORY_ITEMS=50
DISPLAY_COUNT=10
CLIPBOARD_CHECK_INTERVAL=1

# Monitoring
ENABLE_SENTRY=false
LOG_LEVEL=INFO
LOG_TO_FILE=true

# API
API_HOST=127.0.0.1
API_PORT=8000
```

---

## Keyboard Shortcuts

### Global Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘+⇧+V` | Open SimpleCP menu |
| `⌘+⇧+C` | Show clipboard history |
| `⌘+⇧+S` | Show snippets |

*(Note: Shortcuts customizable in Settings)*

### In-App Shortcuts

**Main Window**:
| Shortcut | Action |
|----------|--------|
| `⌘+F` | Open search |
| `⌘+N` | New snippet |
| `⌘+W` | Close window |
| `⌘+,` | Open settings |
| `⌘+Q` | Quit SimpleCP |

**List Navigation**:
| Shortcut | Action |
|----------|--------|
| `↑/↓` | Navigate items |
| `Enter` | Copy to clipboard |
| `⌘+Delete` | Delete item |
| `Space` | Preview item |
| `⌘+I` | Show info |

**Editing**:
| Shortcut | Action |
|----------|--------|
| `⌘+E` | Edit snippet |
| `⌘+R` | Rename |
| `⌘+M` | Move to folder |
| `⌘+D` | Duplicate |

---

## Tips & Tricks

### Productivity Hacks

**1. Email Signatures**
Save multiple email signatures as snippets:
- Professional signature → "Work" folder
- Personal signature → "Personal" folder
- Quick replies → "Email Templates" folder

**2. Code Templates**
Save frequently used code patterns:
```python
# Function template
def function_name():
    """Docstring."""
    pass

# Class template
class ClassName:
    def __init__(self):
        pass
```

**3. Text Expansions**
Use snippets for common responses:
- "Thanks for your email..."
- "Let me follow up on this..."
- "Please find attached..."

**4. Multi-Step Workflows**
1. Copy all needed items
2. Access from history in order
3. Paste sequentially

**5. Research Notes**
While researching:
- Copy interesting quotes
- Copy URLs
- Copy code examples
- Review history later
- Save best items as snippets

### Power User Features

**Batch Operations** (via API):
```bash
# Copy multiple snippets
for snippet in snippet1 snippet2 snippet3; do
  curl http://localhost:8000/api/clipboard/copy \
    -d "{\"clip_id\": \"$snippet\"}"
done
```

**Automated Backups**:
```bash
# Create backup script
#!/bin/bash
cp -r ~/Library/Application\ Support/SimpleCP \
   ~/Backups/SimpleCP-$(date +%Y%m%d)
```

**Integration with Alfred/Raycast**:
- Use API to query clipboard
- Create custom workflows
- Trigger from other apps

---

## FAQ

### General Questions

**Q: Is SimpleCP free?**
A: Yes, SimpleCP is open source and free to use.

**Q: Does SimpleCP work offline?**
A: Yes, all features work offline. No internet required.

**Q: Where is my data stored?**
A: Locally in `~/Library/Application Support/SimpleCP/data/`

**Q: Can I sync across devices?**
A: Not currently built-in. You can manually sync the data folder.

**Q: Does it work on Windows/Linux?**
A: Currently macOS only, but backend works cross-platform.

### Privacy & Security

**Q: Is my clipboard data secure?**
A: Yes, all data stored locally on your Mac. No cloud upload.

**Q: Can others see my clipboard?**
A: No, data is private to your user account.

**Q: Should I store passwords?**
A: No, use a password manager instead.

**Q: What data does Sentry collect?**
A: Only crash reports if enabled. No clipboard content ever sent.

### Troubleshooting

**Q: SimpleCP isn't monitoring clipboard**
A: Check System Preferences → Security & Privacy → Accessibility. SimpleCP must be enabled.

**Q: Menu bar icon not showing**
A: Check if SimpleCP is running. Restart if needed.

**Q: Lost my clipboard history**
A: Check `~/Library/Application Support/SimpleCP/data/history.json`

**Q: High CPU usage**
A: Increase check interval in settings. Default is 1 second.

**Q: Out of memory**
A: Reduce max history items. Default is 50.

For more help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Getting Help

- **Documentation**: [docs/](.)
- **Issues**: [GitHub Issues](https://github.com/YourUsername/SimpleCP/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YourUsername/SimpleCP/discussions)
- **Email**: support@simplecp.app

---

**Happy Clipping! 📋✨**

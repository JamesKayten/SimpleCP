# SimpleCP Swift Frontend - Quick Start

This guide explains how to run the complete hybrid SimpleCP application with the Python backend and Swift macOS frontend.

## Architecture Overview

SimpleCP is a **hybrid application**:

```
┌──────────────────────────────────┐
│  Swift macOS App (SimpleCPApp/)  │  Native UI
│  Port: N/A (native app)          │
└────────────┬─────────────────────┘
             │
             │ HTTP REST API
             │
┌────────────▼─────────────────────┐
│  Python Backend (daemon.py)      │  All Logic
│  Port: 8000                      │
└──────────────────────────────────┘
```

### Division of Responsibilities

**Python Backend** (Already complete):
- ✅ Clipboard monitoring
- ✅ Data persistence (JSON files)
- ✅ Business logic
- ✅ REST API server (FastAPI)
- ✅ Thread-safe operations
- ✅ Configuration management
- ✅ Logging

**Swift Frontend** (Just created):
- ✅ Native macOS UI (SwiftUI)
- ✅ Two-column layout (History | Snippets)
- ✅ Search functionality
- ✅ Save snippet workflow
- ✅ Folder management
- ✅ HTTP communication with backend
- ✅ No business logic (pure UI)

## Running the Complete Application

### Prerequisites

1. **Python 3.8+** with dependencies installed:
   ```bash
   pip install -r requirements.txt
   ```

2. **macOS 13.0+** with Xcode 15.0+

3. **(Linux only)** Clipboard dependencies:
   ```bash
   sudo apt-get install xclip
   ```

### Step-by-Step Startup

#### 1. Start Python Backend

From the repository root:

```bash
python daemon.py
```

Expected output:
```
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://127.0.0.1:8000    ║
║  📊 Stats: 0 history items               ║
╚══════════════════════════════════════════╝
```

**Verify backend is running:**
```bash
curl http://127.0.0.1:8000/health
# Should return: {"status":"healthy","stats":{...}}
```

#### 2. Start Swift Frontend

In a new terminal:

```bash
cd SimpleCPApp
swift run
```

Or open in Xcode:
```bash
cd SimpleCPApp
swift package generate-xcodeproj
open SimpleCPApp.xcodeproj
# Then press ⌘R to build and run
```

#### 3. Verify Connection

1. The Swift app window should open
2. Go to **Settings** (gear icon) → **General**
3. Status should show: **● Connected**
4. You should see any existing clipboard items

## Using the Application

### Main Window

The app displays a two-column layout:

```
┌─────────────────────────────────────────────┐
│ SimpleCP                         [⚙️] [ X ] │
├─────────────────────────────────────────────┤
│ 🔍 Search clips and snippets...             │
├─────────────────────────────────────────────┤
│ [Save Snippet] [Create Folder] [Clear]     │
├──────────────────┬──────────────────────────┤
│ 📋 RECENT CLIPS  │ 📁 SAVED SNIPPETS        │
│                  │                          │
│ 1. "Latest..."   │ 📁 Email Templates ▼    │
│ 2. "Second..."   │   ├── Meeting Request    │
│ 3. "Third..."    │   └── Follow Up          │
│                  │                          │
│ 📁 11-20        │ 📁 Code Snippets ▼       │
│ 📁 21-30        │   ├── Python Main         │
└──────────────────┴──────────────────────────┘
```

### Basic Operations

#### Copy from History
1. **Click** any history item → copies to clipboard
2. **Right-click** for more options

#### Save as Snippet
1. **Click "Save Snippet"** button
2. Enter name, select/create folder, add tags
3. **Click "Save"**

Or:
1. **Right-click** any history item
2. Select **"Save as Snippet..."**

#### Manage Folders
1. **Click "Create Folder"** to add new folder
2. **Right-click folder** to rename or delete
3. **Drag snippets** between folders (via context menu)

#### Search
1. **Type in search bar**
2. Results filter in real-time across both columns

## Development Workflow

### Making Changes to Backend

1. Edit Python files
2. Stop daemon (Ctrl+C)
3. Restart: `python daemon.py`
4. Swift frontend automatically reconnects

### Making Changes to Frontend

1. Edit Swift files in `SimpleCPApp/Sources/`
2. Rebuild in Xcode (⌘B) or `swift build`
3. Run (⌘R) or `swift run`

### Backend + Frontend Together

**Terminal 1** (Python):
```bash
python daemon.py --log-level DEBUG
```

**Terminal 2** (Swift):
```bash
cd SimpleCPApp
swift run
```

## API Endpoints Used

The Swift frontend uses these Python backend endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/config` | GET | Discover API base URL |
| `/health` | GET | Check backend status |
| `/api/v1/history` | GET | Get all history |
| `/api/v1/history/recent` | GET | Get recent items (1-10) |
| `/api/v1/history/folders` | GET | Get auto-folders (11-20, etc.) |
| `/api/v1/history/{id}` | DELETE | Delete history item |
| `/api/v1/history` | DELETE | Clear all history |
| `/api/v1/snippets` | GET | Get all snippets |
| `/api/v1/snippets` | POST | Create snippet |
| `/api/v1/snippets/{folder}/{id}` | PUT | Update snippet |
| `/api/v1/snippets/{folder}/{id}` | DELETE | Delete snippet |
| `/api/v1/snippets/folders` | POST | Create folder |
| `/api/v1/snippets/folders/{name}` | PUT | Rename folder |
| `/api/v1/snippets/folders/{name}` | DELETE | Delete folder |
| `/api/v1/clipboard/copy` | POST | Copy item to clipboard |
| `/api/v1/search?q={query}` | GET | Search all content |

## Configuration

### Backend Configuration

Edit `~/.simplecp/config.json` or use CLI args:

```json
{
  "host": "127.0.0.1",
  "port": 8000,
  "check_interval": 1,
  "max_history": 50,
  "cors_origins": ["*"],
  "log_level": "INFO"
}
```

Or:
```bash
python daemon.py --host 0.0.0.0 --port 9000 --log-level DEBUG
```

### Frontend Configuration

Currently hardcoded to `http://127.0.0.1:8000`.

To change, edit `SimpleCPApp/Sources/SimpleCPApp/Services/APIClient.swift`:

```swift
init(baseURL: String = "http://127.0.0.1:8000") {
    // Change to match your backend
}
```

## Troubleshooting

### Backend Not Starting

```bash
# Check if port 8000 is in use
lsof -i :8000

# Kill process if needed
kill -9 <PID>

# Use different port
python daemon.py --port 9000
```

### Frontend Can't Connect

1. **Verify backend is running:**
   ```bash
   curl http://127.0.0.1:8000/health
   ```

2. **Check Swift app settings:**
   - Open Settings → General
   - Click "Check Connection"

3. **View logs:**
   ```bash
   # Backend logs
   cat logs/simplecp.log

   # Or run with debug
   python daemon.py --log-level DEBUG
   ```

### No Clipboard Items Showing

**On macOS:**
- Should work out of the box

**On Linux:**
```bash
# Install clipboard tools
sudo apt-get install xclip

# Test manually
echo "test" | xclip -selection clipboard
xclip -selection clipboard -o
```

### Swift Build Errors

```bash
# Clean build
cd SimpleCPApp
swift package clean
swift build

# Update Xcode tools
xcode-select --install
```

## File Structure

```
SimpleCP/
├── daemon.py                    # Python backend entry point
├── clipboard_manager.py         # Core business logic
├── config.py                    # Configuration management
├── api/
│   ├── server.py               # FastAPI server
│   ├── endpoints.py            # API routes
│   └── models.py               # Pydantic models
├── SimpleCPApp/                # Swift frontend
│   ├── Package.swift           # SPM configuration
│   ├── Sources/SimpleCPApp/
│   │   ├── SimpleCPApp.swift  # App entry point
│   │   ├── Models/            # Data models
│   │   ├── Services/          # API client
│   │   └── Views/             # SwiftUI views
│   └── README.md              # Frontend docs
└── SWIFT_FRONTEND.md          # This file
```

## Next Steps

1. **Test the integration** - Copy some text, save as snippet
2. **Explore features** - Try search, folders, tags
3. **Customize** - Adjust settings, create folders
4. **Develop** - Add features to either backend or frontend

## Getting Help

- **Backend issues**: Check `logs/simplecp.log`
- **Frontend issues**: Check Xcode console
- **API issues**: Test endpoints with `curl` or browser at `http://127.0.0.1:8000/docs`

## Credits

- **Backend**: Python + FastAPI + Pydantic
- **Frontend**: Swift + SwiftUI + Foundation
- **Architecture**: Hybrid REST API approach

Enjoy your new hybrid clipboard manager! 🚀

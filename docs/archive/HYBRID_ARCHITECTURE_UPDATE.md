# CRITICAL UPDATE: Hybrid Architecture Approach

## 🚨 **Architecture Change for Web Claude**

**STOP current Python UI work.** SimpleCP will use a **hybrid architecture** for maximum visual polish:

- **Python Backend** (your focus) - Core logic + REST API
- **Swift Frontend** (later Xcode work) - Native macOS UI

## 🎯 **New Focus: Python Backend + API**

Instead of building Python UI (tkinter/PyQt), focus on:

### 1. Core Backend Implementation
```python
# Your new target architecture:

SimpleCP-Backend/
├── main.py                 # Background daemon entry point
├── api/
│   ├── __init__.py
│   ├── server.py          # Flask/FastAPI REST server
│   ├── endpoints.py       # API routes
│   └── models.py          # API data models
├── core/
│   ├── clipboard_manager.py   # Core logic (using Flycut patterns)
│   ├── stores/               # HistoryStore, SnippetStore
│   └── persistence.py        # Data saving/loading
├── daemon.py              # Background clipboard monitoring
└── config.py              # Settings management
```

### 2. REST API Endpoints
Build these API endpoints for the Swift frontend:

#### Clipboard History
```python
GET  /api/history                    # Get recent clips
GET  /api/history/folders           # Get auto-generated history folders (11-20, etc.)
GET  /api/history/{folder}          # Get clips in specific folder range
POST /api/history/copy             # Copy item to clipboard
DELETE /api/history              # Clear history
```

#### Snippets Management
```python
GET    /api/snippets               # Get all snippet folders
GET    /api/snippets/{folder}      # Get snippets in folder
POST   /api/snippets               # Save new snippet
PUT    /api/snippets/{id}          # Update snippet
DELETE /api/snippets/{id}          # Delete snippet
POST   /api/folders                # Create new folder
```

#### Search & Utilities
```python
GET /api/search?q={query}          # Search clips and snippets
GET /api/settings                  # Get app settings
PUT /api/settings                  # Update settings
GET /api/status                    # Backend health check
```

### 3. Background Daemon
```python
# daemon.py - Runs continuously in background
class ClipboardDaemon:
    def __init__(self):
        self.manager = ClipboardManager()
        self.api_server = APIServer()

    def run(self):
        # Start clipboard monitoring
        self.start_clipboard_monitoring()

        # Start API server on localhost
        self.api_server.run(host='127.0.0.1', port=8080)

    def start_clipboard_monitoring(self):
        # Use Flycut patterns for clipboard monitoring
        # Add new clips to history_store automatically
        pass
```

## 🚀 **Implementation Priority (Revised)**

### Phase 1: Core Backend (Your Focus)
1. **Enhanced ClipboardItem** - Using Flycut patterns
2. **Multi-store ClipboardManager** - History + Snippet stores
3. **Background daemon** - Clipboard monitoring service
4. **REST API server** - Flask/FastAPI endpoints

### Phase 2: API Development
1. **History endpoints** - CRUD for clipboard history
2. **Snippet endpoints** - Full snippet workflow API
3. **Search functionality** - Cross-store search
4. **Settings API** - Configuration management

### Phase 3: Testing & Documentation
1. **API testing** - Postman/curl tests for all endpoints
2. **API documentation** - OpenAPI/Swagger docs
3. **Background service** - Proper daemon behavior

### Phase 4: Swift Frontend (Later - Local Claude)
1. **Xcode project setup** - Native macOS app
2. **SwiftUI interface** - Beautiful two-column design
3. **API integration** - HTTP client to Python backend
4. **Visual polish** - Native macOS animations and styling

## 🔄 **Why This Change?**

**Benefits of Hybrid Approach:**
- **Visual Polish** - True native macOS appearance with SwiftUI
- **Performance** - Native frontend + Python backend strengths
- **Maintainability** - Clear separation of concerns
- **Distribution** - Can be App Store ready
- **Best of Both** - Python's simplicity + Swift's polish

## 📋 **Updated Instructions for Web Claude**

**STOP** working on:
- ❌ tkinter/PyQt UI development
- ❌ Python window management
- ❌ Menu bar interface in Python

**START** working on:
- ✅ Core ClipboardManager with Flycut patterns
- ✅ HistoryStore and SnippetStore implementation
- ✅ REST API server with Flask/FastAPI
- ✅ Background clipboard monitoring daemon
- ✅ API endpoints for snippet workflow

## 🛠️ **Technical Stack (Updated)**

**Python Backend:**
- **rumps** - Only for background daemon menu bar icon
- **Flask/FastAPI** - REST API server
- **pyperclip** - Clipboard operations
- **Flycut patterns** - Proven architecture
- **JSON/SQLite** - Data persistence

**Swift Frontend (Later):**
- **SwiftUI** - Native macOS interface
- **URLSession** - HTTP API client
- **Xcode** - Development environment

## 🎯 **Your New Goal**

Build a **robust Python backend** that the Swift frontend can communicate with via REST API. Focus on the **core clipboard management logic** and **API design** rather than UI appearance.

This approach will result in a **much more professional final product**!

---

**Start with:** Converting the current ClipboardManager to run as a background service with REST API endpoints.
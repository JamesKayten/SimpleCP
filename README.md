# SimpleCP - Simple macOS Clipboard Manager

**Hybrid Architecture: Python REST API Backend + Native Swift Frontend**

A professional clipboard manager with a Python backend for logic and a native Swift/SwiftUI frontend for visual polish.

## Architecture Overview

SimpleCP uses a **hybrid architecture** for maximum quality:

- **Python Backend** (Current): REST API server with clipboard monitoring
- **Swift Frontend** (Future): Native macOS UI built in Xcode

This approach provides:
- Professional visual polish with native macOS UI
- Robust backend logic in Python
- Clean separation of concerns
- App Store ready distribution

## Features

🚀 **Core Functionality**
- Automatic clipboard history tracking (background daemon)
- Organized snippet folders for reusable text
- REST API for frontend integration
- Search across history and snippets
- Configurable settings via API

📁 **Snippet Management**
- Organize snippets into folders
- Full CRUD operations via API
- Quick access to frequently used text
- JSON-based storage (easy backup)

🎯 **Professional Architecture**
- FastAPI REST API backend
- Background clipboard monitoring
- Auto-deduplication of history items
- Flycut-inspired architecture patterns
- Thread-safe operation

## Installation

### Prerequisites
- macOS 10.13+
- Python 3.8+

### Setup
```bash
# Clone the repository
git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP

# Install dependencies
pip3 install -r requirements.txt

# Run the backend daemon
python3 main.py
```

The API will be available at `http://127.0.0.1:8080`

### API Documentation

Once running, visit:
- **Interactive API Docs**: http://127.0.0.1:8080/docs
- **Alternative Docs**: http://127.0.0.1:8080/redoc

## Architecture

### Hybrid Design

```
┌─────────────────────────────────────────┐
│     Swift Frontend (Future)             │
│     Native macOS UI                     │
│     SwiftUI + URLSession                │
└──────────────┬──────────────────────────┘
               │ HTTP REST API
               ▼
┌─────────────────────────────────────────┐
│     Python Backend (Current)            │
│  ┌─────────────────────────────────┐   │
│  │   FastAPI REST Server           │   │
│  │   Port 8080                     │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │   Clipboard Monitor Daemon      │   │
│  │   Background Thread             │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │   Data Stores                   │   │
│  │   - HistoryStore                │   │
│  │   - SnippetStore                │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Project Structure
```
SimpleCP/
├── main.py                 # Backend entry point
├── daemon.py               # Clipboard monitoring daemon
├── api/
│   ├── __init__.py
│   ├── server.py           # FastAPI application
│   └── models.py           # Pydantic models
├── stores/
│   ├── __init__.py
│   ├── history_store.py    # Clipboard history management
│   ├── snippet_store.py    # Snippet folder management
│   └── clipboard_item.py   # Data models
├── data/
│   ├── history.json        # Clipboard history (gitignored)
│   ├── snippets.json       # Snippets (gitignored)
│   └── snippets_full.json  # Full snippet metadata (gitignored)
├── docs/
│   ├── API_DOCUMENTATION.md           # Complete API docs
│   ├── HYBRID_ARCHITECTURE_UPDATE.md  # Architecture details
│   └── FLYCUT_ARCHITECTURE_ADAPTATION.md  # Design patterns
└── test_api.py             # API endpoint tests
```

### Core Components

- **daemon.py**: Background service that runs clipboard monitoring and API server
- **api/server.py**: FastAPI REST API with all endpoints
- **HistoryStore**: Manages clipboard history with auto-deduplication and auto-folders
- **SnippetStore**: Handles snippet CRUD operations and folder management
- **ClipboardItem**: Data model for clipboard items

## Development Status

### ✅ Phase 1: Python Backend (COMPLETED)
- [x] REST API server with FastAPI
- [x] Clipboard monitoring daemon
- [x] HistoryStore with Flycut patterns
- [x] SnippetStore with folder management
- [x] All API endpoints implemented
- [x] Search functionality
- [x] Settings management
- [x] Auto-deduplication of clipboard items
- [x] Auto-folder generation (1-10, 11-20, etc.)
- [x] JSON persistence
- [x] API documentation
- [x] Test suite

### 🔄 Phase 2: Swift Frontend (TODO)
- [ ] Xcode project setup
- [ ] SwiftUI interface design
- [ ] API client implementation
- [ ] Two-column layout (History + Snippets)
- [ ] Native macOS styling
- [ ] Keyboard shortcuts
- [ ] Menu bar icon integration

## Development Workflow

This project is designed for collaboration between local Claude Code and web Claude:

1. **Local Development** (Claude Code): System integration, testing, file operations
2. **Web Development** (Online Claude): Core logic implementation, algorithms
3. **Shared Repository**: Single source of truth for collaboration

### Collaboration Guidelines

For **Web Claude**:
```bash
# To continue development:
git pull origin main
# Make your changes
git add .
git commit -m "feat: description of changes"
git push origin main
```

For **Claude Code**:
- Handle system-specific operations
- Test application functionality
- Manage file operations and Git workflow

## Technology Stack

### Python Backend
- **FastAPI**: Modern REST API framework with automatic OpenAPI docs
- **Uvicorn**: ASGI server for running FastAPI
- **Pydantic**: Data validation and serialization
- **pyperclip**: Cross-platform clipboard operations
- **Python 3.8+**: Core implementation language
- **JSON**: Simple data persistence

### Swift Frontend (Future)
- **SwiftUI**: Native macOS UI framework
- **URLSession**: HTTP API client
- **Xcode**: Development environment

## API Testing

### Running Tests

```bash
# Terminal 1: Start the daemon
python3 main.py

# Terminal 2: Run test suite
python3 test_api.py
```

### Manual Testing with curl

```bash
# Check backend status
curl http://127.0.0.1:8080/api/status

# Get clipboard history
curl http://127.0.0.1:8080/api/history

# Create a snippet
curl -X POST http://127.0.0.1:8080/api/snippets \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","content":"Hello World","folder":"General"}'

# Search
curl "http://127.0.0.1:8080/api/search?q=test"
```

### API Documentation

Complete API documentation is available in:
- `/docs/API_DOCUMENTATION.md` - Detailed endpoint reference
- `http://127.0.0.1:8080/docs` - Interactive Swagger UI (when running)

## Inspiration

Based on analysis of [Flycut](https://github.com/TermiT/Flycut), an excellent open-source clipboard manager. Our implementation provides:

- **Simpler architecture**: Python vs 58k lines of Objective-C
- **Snippet folders**: Built-in folder organization (missing in Flycut)
- **Easy customization**: JSON configuration vs complex preferences
- **Modern approach**: Designed for current macOS versions

## License

MIT License - Build, modify, and distribute freely.

## Contributing

1. Check current implementation status in `docs/IMPLEMENTATION_STATUS.md`
2. Follow the development workflow above
3. Test on macOS before pushing
4. Update documentation for new features

---

**Need to use API credits?** Continue development in web Claude with the collaboration workflow above!

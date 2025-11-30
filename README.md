# SimpleCP - Modern Clipboard Manager

A professional clipboard manager for macOS with Python backend and native Swift frontend.

## 🏗️ Project Structure

```
SimpleCP/
├── backend/                    # Python REST API Backend
│   ├── api/                   # REST API endpoints
│   ├── stores/                # Data persistence layer
│   ├── tests/                 # Backend test suite
│   ├── ui/                    # Menu/UI components
│   ├── data/                  # Sample and runtime data
│   ├── config/                # Configuration files
│   ├── main.py               # Backend entry point
│   ├── clipboard_manager.py   # Core clipboard logic
│   ├── requirements.txt       # Python dependencies
│   └── VERSION               # Version tracking
│
├── frontend/                  # Swift macOS Application
│   └── SimpleCP-macOS/       # Native macOS app (SwiftUI)
│       ├── Package.swift     # Swift Package Manager
│       ├── Sources/          # Swift source code
│       └── README.md         # Frontend documentation
│
├── docs/                     # Complete Documentation
│   ├── API.md               # API documentation
│   ├── UI_UX_SPECIFICATION_v3.md
│   ├── USER_GUIDE.md
│   └── ...                  # Additional guides
│
└── tools/                   # Development & Build Tools
    ├── scripts/             # Build automation
    ├── monitoring/          # System monitoring tools
    ├── create_session_snapshot.sh
    └── restore_session.sh
```

## 🚀 Quick Start

### Backend (Python API)
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### Frontend (Swift App)
```bash
cd frontend/SimpleCP-macOS
swift build && swift run
```

### Development Tools
```bash
cd tools
./scripts/build_python.sh    # Build Python backend
./scripts/build_swift.sh     # Build Swift frontend
```

## 🔧 Architecture

- **Backend**: FastAPI Python server (localhost:8080)
- **Frontend**: Native SwiftUI MenuBar app
- **Communication**: REST API over HTTP
- **Data**: JSON file storage with history management

## 📁 Key Components

### Backend (`/backend`)
- **`main.py`** - Server entry point
- **`clipboard_manager.py`** - Core clipboard monitoring
- **`api/server.py`** - FastAPI REST endpoints
- **`stores/`** - Data persistence and storage
- **`tests/`** - Comprehensive test suite

### Frontend (`/frontend/SimpleCP-macOS`)
- **`SimpleCPApp.swift`** - MenuBarExtra application
- **`ClipboardManager.swift`** - Swift clipboard interface
- **`ContentView.swift`** - Main UI (600x400 window)
- **Package.swift** - Modern SPM configuration

## 📚 Documentation

- [API Documentation](docs/API.md)
- [UI/UX Specification](docs/UI_UX_SPECIFICATION_v3.md)
- [User Guide](docs/USER_GUIDE.md)

## 🛠️ Development

This project uses:
- **Python 3.11+** with FastAPI
- **Swift 5.9+** with SwiftUI
- **Modern development tools** for build automation

## ✅ Current Status

**✅ Complete:**
- Python backend with REST API
- Swift MenuBar frontend
- Complete testing infrastructure
- Development tools and monitoring
- Clean project structure

**🔧 Ready for:**
- Production deployment
- Feature expansion
- User testing

---

**Clean, organized, and production-ready.**
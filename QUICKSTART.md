# SimpleCP Quick Start Guide

Get SimpleCP up and running in 5 minutes!

## Prerequisites

- macOS 10.14 or later
- Python 3.9 or higher
- 10MB disk space

---

## Installation

### Step 1: Install Python (if needed)

```bash
# Check if Python 3.9+ is installed
python3 --version

# If not installed, use Homebrew
brew install python@3.11
```

### Step 2: Clone Repository

```bash
git clone https://github.com/YourUsername/SimpleCP.git
cd SimpleCP
```

### Step 3: Install Dependencies

```bash
pip3 install -r requirements.txt
```

---

## Running SimpleCP

### Start the Daemon

```bash
python3 daemon.py
```

You should see:
```
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  Version: 1.0.0                          ║
║  Environment: development                ║
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://127.0.0.1:8000    ║
║  📊 History: 0 items                     ║
║  📁 Snippets: 0 snippets                 ║
╚══════════════════════════════════════════╝
```

---

## Test It Out

### 1. Copy Something

Copy any text (⌘+C):
```
Hello, SimpleCP!
```

### 2. Check History

```bash
curl http://localhost:8000/api/history/recent | jq
```

Output:
```json
[
  {
    "clip_id": "abc123...",
    "content": "Hello, SimpleCP!",
    "timestamp": "2025-01-15T10:30:00",
    "content_type": "text"
  }
]
```

### 3. Create a Snippet

```bash
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "content": "def hello():\n    print(\"Hello, World!\")",
    "folder_name": "Code",
    "name": "Hello Function"
  }'
```

### 4. Search

```bash
curl "http://localhost:8000/api/search?q=hello" | jq
```

---

## Configuration (Optional)

### Create .env file

```bash
cp .env.example .env
```

### Edit settings

```env
# Clipboard
MAX_HISTORY_ITEMS=50
CLIPBOARD_CHECK_INTERVAL=1

# API
API_PORT=8000

# Logging
LOG_LEVEL=INFO
LOG_TO_FILE=true
```

---

## Common Commands

### View History
```bash
curl http://localhost:8000/api/history
```

### Create Snippet
```bash
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{"content":"text","folder_name":"Folder","name":"Name"}'
```

### Search
```bash
curl "http://localhost:8000/api/search?q=keyword"
```

### Get Stats
```bash
curl http://localhost:8000/api/stats
```

### Health Check
```bash
curl http://localhost:8000/health
```

---

## Interactive API Documentation

Open in browser:
```
http://localhost:8000/docs
```

Try out API endpoints interactively!

---

## Stop SimpleCP

Press `Ctrl+C` in the terminal running the daemon, or:

```bash
pkill -f daemon.py
```

---

## Next Steps

- **Read the [User Guide](docs/USER_GUIDE.md)** for detailed features
- **Check [API Documentation](docs/API.md)** for all endpoints
- **See [Examples](examples/)** for integration ideas
- **Join [Discussions](https://github.com/YourUsername/SimpleCP/discussions)** for help

---

## Troubleshooting

### Daemon won't start?
```bash
# Check if port 8000 is in use
lsof -i :8000

# View logs
tail -f logs/simplecp.log
```

### Dependencies failed?
```bash
# Use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### More help?
See [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

---

**You're ready to go! 🚀**

Start copying text and SimpleCP will automatically track your clipboard history!

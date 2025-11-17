# SimpleCP REST API Documentation

## Overview

SimpleCP provides a REST API backend for clipboard management. The Python backend handles:
- Clipboard monitoring and history storage
- Snippet management with folders
- Search functionality
- Settings management

The API is designed to be consumed by a native Swift/SwiftUI macOS frontend.

## Getting Started

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Start the daemon
python3 main.py
```

The API server will start on `http://127.0.0.1:8080`

### Interactive Documentation

FastAPI provides automatic interactive documentation:
- **Swagger UI**: http://127.0.0.1:8080/docs
- **ReDoc**: http://127.0.0.1:8080/redoc

## API Endpoints

### Root

#### `GET /`
Get API information

**Response:**
```json
{
  "name": "SimpleCP API",
  "version": "1.0.0",
  "description": "REST API for SimpleCP clipboard manager",
  "docs": "/docs",
  "status": "running"
}
```

---

## History Management

### `GET /api/history`
Get recent clipboard history

**Query Parameters:**
- `limit` (optional): Limit number of items returned

**Response:**
```json
{
  "items": [
    {
      "content": "Full clipboard text...",
      "timestamp": "2024-11-17T15:30:00.000000",
      "preview": "Full clipboard text...",
      "source_app": "TextEdit",
      "item_type": "history",
      "index": 0
    }
  ],
  "total": 50
}
```

### `GET /api/history/folders`
Get auto-generated history folders

**Response:**
```json
[
  {
    "name": "1-10",
    "start": 0,
    "end": 10,
    "count": 10
  },
  {
    "name": "11-20",
    "start": 10,
    "end": 20,
    "count": 10
  }
]
```

### `GET /api/history/{folder}`
Get clips in specific folder range

**Path Parameters:**
- `folder`: Folder name (e.g., "1-10", "11-20")

**Response:**
```json
{
  "items": [...],
  "total": 10
}
```

### `POST /api/history/copy`
Copy a history item to clipboard

**Request:**
```json
{
  "index": 0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Copied to clipboard"
}
```

### `DELETE /api/history`
Clear all clipboard history

**Response:**
```json
{
  "success": true,
  "message": "History cleared"
}
```

---

## Snippet Management

### `GET /api/snippets`
Get all snippet folders

**Response:**
```json
[
  {
    "name": "Email Templates",
    "snippet_count": 5
  },
  {
    "name": "Code Snippets",
    "snippet_count": 10
  }
]
```

### `GET /api/snippets/{folder}`
Get all snippets in a folder

**Path Parameters:**
- `folder`: Folder name

**Response:**
```json
[
  {
    "id": "uuid-here",
    "name": "Meeting Request",
    "content": "Hi [NAME],...",
    "folder": "Email Templates",
    "created_at": "2024-11-17T15:30:00.000000"
  }
]
```

### `POST /api/snippets`
Create a new snippet

**Request:**
```json
{
  "name": "New Snippet",
  "content": "Snippet content here",
  "folder": "My Folder"
}
```

**Response:**
```json
{
  "id": "uuid-here",
  "name": "New Snippet",
  "content": "Snippet content here",
  "folder": "My Folder",
  "created_at": "2024-11-17T15:30:00.000000"
}
```

### `PUT /api/snippets/{snippet_id}`
Update a snippet

**Path Parameters:**
- `snippet_id`: Snippet UUID

**Request:**
```json
{
  "name": "Updated Name",
  "content": "Updated content",
  "folder": "Different Folder"
}
```

All fields are optional. Only provided fields will be updated.

**Response:**
```json
{
  "id": "uuid-here",
  "name": "Updated Name",
  "content": "Updated content",
  "folder": "Different Folder",
  "created_at": "2024-11-17T15:30:00.000000"
}
```

### `DELETE /api/snippets/{snippet_id}`
Delete a snippet

**Path Parameters:**
- `snippet_id`: Snippet UUID

**Response:**
```json
{
  "success": true,
  "message": "Snippet deleted"
}
```

### `POST /api/folders`
Create a new folder

**Request:**
```json
{
  "name": "New Folder"
}
```

**Response:**
```json
{
  "name": "New Folder",
  "snippet_count": 0
}
```

---

## Search

### `GET /api/search`
Search clipboard history and snippets

**Query Parameters:**
- `q`: Search query (required)

**Response:**
```json
{
  "query": "test",
  "results": [
    {
      "type": "history",
      "content": "test content",
      "preview": "test content",
      "timestamp": "2024-11-17T15:30:00.000000",
      "index": 0
    },
    {
      "type": "snippet",
      "content": "test snippet",
      "preview": "test snippet",
      "id": "uuid-here",
      "name": "Test Snippet",
      "folder": "Code Snippets"
    }
  ],
  "total": 2
}
```

---

## Settings

### `GET /api/settings`
Get application settings

**Response:**
```json
{
  "max_history_items": 50,
  "clipboard_check_interval": 1.0,
  "show_timestamps": true,
  "menu_item_length": 50,
  "api_port": 8080
}
```

### `PUT /api/settings`
Update application settings

**Request:**
```json
{
  "max_history_items": 100,
  "clipboard_check_interval": 0.5,
  "show_timestamps": false,
  "menu_item_length": 75
}
```

All fields are optional. Only provided fields will be updated.

**Response:**
```json
{
  "max_history_items": 100,
  "clipboard_check_interval": 0.5,
  "show_timestamps": false,
  "menu_item_length": 75,
  "api_port": 8080
}
```

---

## Status

### `GET /api/status`
Get backend health and status

**Response:**
```json
{
  "status": "running",
  "version": "1.0.0",
  "uptime_seconds": 3600.5,
  "clipboard_monitoring": true,
  "history_count": 50,
  "snippet_count": 25,
  "folders_count": 5
}
```

---

## Error Handling

All endpoints return standard HTTP status codes:

- `200 OK`: Success
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error responses follow this format:

```json
{
  "error": "Error message",
  "detail": "Additional details (optional)"
}
```

---

## Data Storage

### File Structure

```
data/
├── history.json          # Clipboard history (legacy format)
├── snippets.json         # Snippets (legacy format)
└── snippets_full.json    # Snippets with full metadata (API format)
```

### Persistence

- History and snippets are automatically saved to JSON files
- Data persists across restarts
- Files are created automatically if they don't exist

---

## Testing

Use the provided test script:

```bash
# Start daemon in one terminal
python3 main.py

# Run tests in another terminal
python3 test_api.py
```

Or use curl:

```bash
# Get status
curl http://127.0.0.1:8080/api/status

# Get history
curl http://127.0.0.1:8080/api/history

# Create snippet
curl -X POST http://127.0.0.1:8080/api/snippets \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","content":"Hello","folder":"General"}'
```

---

## Swift Integration

### Example Swift Code

```swift
import Foundation

struct HistoryItem: Codable {
    let content: String
    let timestamp: String
    let preview: String
    let index: Int
}

struct HistoryResponse: Codable {
    let items: [HistoryItem]
    let total: Int
}

func fetchHistory() async throws -> HistoryResponse {
    let url = URL(string: "http://127.0.0.1:8080/api/history")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(HistoryResponse.self, from: data)
}
```

---

## Architecture

### Components

1. **daemon.py**: Background daemon that runs:
   - Clipboard monitoring thread
   - FastAPI server thread

2. **api/server.py**: FastAPI application with all endpoints

3. **stores/**: Data management
   - `history_store.py`: Clipboard history with auto-deduplication
   - `snippet_store.py`: Snippet folders and CRUD operations
   - `clipboard_item.py`: Data models

### Thread Safety

The daemon uses separate threads for clipboard monitoring and API server. The stores use simple locking mechanisms via Python's GIL for thread safety.

---

## Future Enhancements

Planned features for future versions:

- [ ] Source app detection (using AppKit on macOS)
- [ ] Image clipboard support
- [ ] Rich text formatting
- [ ] Encryption for sensitive snippets
- [ ] Cloud sync support
- [ ] Hotkey registration from API
- [ ] Clipboard change webhooks

---

## License

See LICENSE file for details.

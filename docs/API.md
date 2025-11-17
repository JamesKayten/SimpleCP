# SimpleCP REST API Documentation

Complete API reference for SimpleCP clipboard manager.

## Table of Contents

- [Overview](#overview)
- [Base URL](#base-url)
- [Authentication](#authentication)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Endpoints](#endpoints)
  - [Root & Health](#root--health)
  - [Clipboard History](#clipboard-history)
  - [Snippets](#snippets)
  - [Folders](#folders)
  - [Clipboard Operations](#clipboard-operations)
  - [Search](#search)
  - [Statistics](#statistics)
- [Data Models](#data-models)
- [Examples](#examples)
- [Client Libraries](#client-libraries)

---

## Overview

SimpleCP provides a RESTful API for programmatic access to clipboard history and snippets.

**Features**:
- Full CRUD operations on history and snippets
- Search functionality
- Real-time clipboard operations
- Health monitoring
- Performance metrics

**Technology Stack**:
- Framework: FastAPI
- Protocol: HTTP/REST
- Format: JSON
- Documentation: OpenAPI 3.0 (Swagger)

---

## Base URL

**Default**:
```
http://localhost:8000
```

**Configure** via environment variables:
```bash
export API_HOST=127.0.0.1
export API_PORT=8000
```

---

## Authentication

**Current**: No authentication required (localhost only)

**Future**: API keys for remote access

**Security**:
- Default: Listens on localhost only
- CORS: Configurable origins
- Production: Use reverse proxy (nginx) with auth

---

## Response Format

### Success Response

```json
{
  "status": "success",
  "data": { ... },
  "message": "Operation completed successfully"
}
```

### Error Response

```json
{
  "error": "Error type",
  "detail": "Detailed error message",
  "status_code": 400
}
```

### Pagination

Not currently implemented. All endpoints return full results.

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created |
| 400 | Bad Request | Invalid request data |
| 404 | Not Found | Resource doesn't exist |
| 422 | Validation Error | Request data failed validation |
| 500 | Internal Server Error | Server error |

### Error Response Example

```json
{
  "error": "Validation Error",
  "detail": [
    {
      "loc": ["body", "folder_name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

---

## Rate Limiting

**Current**: No rate limiting

**Recommendations**:
- Use responsibly
- Max 100 requests/minute for automation
- Contact if higher limits needed

---

## Endpoints

### Root & Health

#### GET /

Get API information.

**Response**:
```json
{
  "name": "SimpleCP",
  "version": "1.0.0",
  "status": "running",
  "environment": "development"
}
```

**Example**:
```bash
curl http://localhost:8000/
```

---

#### GET /health

Health check with detailed metrics.

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development",
  "clipboard_stats": {
    "history_count": 25,
    "snippet_count": 15,
    "folder_count": 3,
    "max_history": 50
  },
  "monitoring": {
    "performance": { ... },
    "usage": { ... },
    "sentry_enabled": false,
    "environment": "development"
  }
}
```

**Example**:
```bash
curl http://localhost:8000/health
```

---

### Clipboard History

#### GET /api/history

Get all clipboard history items.

**Query Parameters**:
- `limit` (optional): Maximum number of items to return

**Response**:
```json
[
  {
    "clip_id": "abc123",
    "content": "Hello World",
    "timestamp": "2025-01-15T10:30:00",
    "content_type": "text",
    "source_app": "Terminal",
    "item_type": "history",
    "display_string": "Hello World",
    "has_name": false,
    "snippet_name": null,
    "folder_path": null,
    "tags": []
  }
]
```

**Examples**:
```bash
# Get all history
curl http://localhost:8000/api/history

# Get last 10 items
curl http://localhost:8000/api/history?limit=10
```

---

#### GET /api/history/recent

Get recent history items for display.

**Response**: Array of clipboard items (last 10 by default)

**Example**:
```bash
curl http://localhost:8000/api/history/recent
```

---

#### GET /api/history/folders

Get auto-generated history folders.

**Response**:
```json
[
  {
    "name": "11-20",
    "start_index": 11,
    "end_index": 20,
    "count": 10,
    "items": [ ... ]
  },
  {
    "name": "21-30",
    "start_index": 21,
    "end_index": 30,
    "count": 10,
    "items": [ ... ]
  }
]
```

**Example**:
```bash
curl http://localhost:8000/api/history/folders
```

---

#### DELETE /api/history/{clip_id}

Delete specific history item.

**Parameters**:
- `clip_id`: ID of item to delete

**Response**:
```json
{
  "success": true,
  "message": "Item deleted"
}
```

**Example**:
```bash
curl -X DELETE http://localhost:8000/api/history/abc123
```

---

#### DELETE /api/history

Clear all history.

**Response**:
```json
{
  "success": true,
  "message": "History cleared"
}
```

**Example**:
```bash
curl -X DELETE http://localhost:8000/api/history
```

---

### Snippets

#### GET /api/snippets

Get all snippets organized by folder.

**Response**:
```json
[
  {
    "folder_name": "Work",
    "snippets": [
      {
        "clip_id": "snippet1",
        "content": "Email signature",
        "snippet_name": "Professional Signature",
        "folder_path": "Work",
        "content_type": "text",
        "timestamp": "2025-01-15T10:30:00"
      }
    ]
  }
]
```

**Example**:
```bash
curl http://localhost:8000/api/snippets
```

---

#### GET /api/snippets/folders

Get list of snippet folder names.

**Response**:
```json
["Work", "Personal", "Code"]
```

**Example**:
```bash
curl http://localhost:8000/api/snippets/folders
```

---

#### GET /api/snippets/{folder_name}

Get snippets from specific folder.

**Parameters**:
- `folder_name`: Name of folder

**Response**:
```json
{
  "folder_name": "Work",
  "snippets": [ ... ]
}
```

**Example**:
```bash
curl http://localhost:8000/api/snippets/Work
```

---

#### POST /api/snippets

Create new snippet.

**Request Body** (Option 1 - From History):
```json
{
  "clip_id": "abc123",
  "folder_name": "Work",
  "name": "Important Note"
}
```

**Request Body** (Option 2 - Direct):
```json
{
  "content": "Snippet content here",
  "folder_name": "Work",
  "name": "My Snippet"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Snippet created",
  "clip_id": "snippet123"
}
```

**Examples**:
```bash
# From history
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "clip_id": "abc123",
    "folder_name": "Work",
    "name": "Important"
  }'

# Direct creation
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "content": "def hello():\n    print(\"Hello\")",
    "folder_name": "Code",
    "name": "Hello Function"
  }'
```

---

#### PUT /api/snippets/{folder}/{clip_id}

Update snippet.

**Parameters**:
- `folder`: Folder name
- `clip_id`: Snippet ID

**Request Body**:
```json
{
  "name": "Updated Name",
  "content": "Updated content"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Snippet updated"
}
```

**Example**:
```bash
curl -X PUT http://localhost:8000/api/snippets/Work/snippet123 \
  -H "Content-Type: application/json" \
  -d '{"name": "New Name"}'
```

---

#### DELETE /api/snippets/{folder}/{clip_id}

Delete snippet.

**Parameters**:
- `folder`: Folder name
- `clip_id`: Snippet ID

**Response**:
```json
{
  "success": true,
  "message": "Snippet deleted"
}
```

**Example**:
```bash
curl -X DELETE http://localhost:8000/api/snippets/Work/snippet123
```

---

#### POST /api/snippets/{folder}/{clip_id}/move

Move snippet to different folder.

**Parameters**:
- `folder`: Current folder
- `clip_id`: Snippet ID

**Request Body**:
```json
{
  "new_folder": "Personal"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Snippet moved"
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/api/snippets/Work/snippet123/move \
  -H "Content-Type: application/json" \
  -d '{"new_folder": "Personal"}'
```

---

### Folders

#### POST /api/folders

Create new folder.

**Request Body**:
```json
{
  "folder_name": "New Folder"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Folder created"
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/api/folders \
  -H "Content-Type: application/json" \
  -d '{"folder_name": "Projects"}'
```

---

#### PUT /api/folders/{folder_name}

Rename folder.

**Parameters**:
- `folder_name`: Current folder name

**Request Body**:
```json
{
  "new_name": "Renamed Folder"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Folder renamed"
}
```

**Example**:
```bash
curl -X PUT http://localhost:8000/api/folders/OldName \
  -H "Content-Type: application/json" \
  -d '{"new_name": "NewName"}'
```

---

#### DELETE /api/folders/{folder_name}

Delete folder and all contents.

**Parameters**:
- `folder_name`: Folder to delete

**Response**:
```json
{
  "success": true,
  "message": "Folder deleted"
}
```

**Example**:
```bash
curl -X DELETE http://localhost:8000/api/folders/OldFolder
```

---

### Clipboard Operations

#### POST /api/clipboard/copy

Copy item to system clipboard.

**Request Body**:
```json
{
  "clip_id": "abc123"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Copied to clipboard"
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/api/clipboard/copy \
  -H "Content-Type: application/json" \
  -d '{"clip_id": "abc123"}'
```

---

### Search

#### GET /api/search

Search across history and snippets.

**Query Parameters**:
- `q`: Search query (required)

**Response**:
```json
{
  "history": [ ... ],
  "snippets": [ ... ]
}
```

**Example**:
```bash
curl "http://localhost:8000/api/search?q=python"
```

---

### Statistics

#### GET /api/stats

Get clipboard manager statistics.

**Response**:
```json
{
  "history_count": 25,
  "snippet_count": 15,
  "folder_count": 3,
  "max_history": 50
}
```

**Example**:
```bash
curl http://localhost:8000/api/stats
```

---

## Data Models

### ClipboardItem

```typescript
{
  clip_id: string,          // Unique identifier
  content: string,          // Clipboard content
  timestamp: string,        // ISO 8601 format
  content_type: string,     // "text" | "code" | "url" | "json"
  source_app: string,       // Source application name
  item_type: string,        // "history" | "snippet"
  display_string: string,   // Truncated preview
  has_name: boolean,        // Is it a named snippet?
  snippet_name: string?,    // Snippet name (if has_name)
  folder_path: string?,     // Folder location (snippets only)
  tags: string[]            // Tags (future feature)
}
```

### Folder

```typescript
{
  folder_name: string,      // Folder name
  snippets: ClipboardItem[] // Items in folder
}
```

### HistoryFolder

```typescript
{
  name: string,             // e.g., "11-20"
  start_index: number,      // Starting index
  end_index: number,        // Ending index
  count: number,            // Number of items
  items: ClipboardItem[]    // Items in range
}
```

---

## Examples

### Python

```python
import requests

BASE_URL = "http://localhost:8000"

# Get recent history
response = requests.get(f"{BASE_URL}/api/history/recent")
history = response.json()

# Create snippet
snippet_data = {
    "content": "def hello():\n    print('Hello')",
    "folder_name": "Code",
    "name": "Hello Function"
}
response = requests.post(
    f"{BASE_URL}/api/snippets",
    json=snippet_data
)

# Search
response = requests.get(f"{BASE_URL}/api/search", params={"q": "python"})
results = response.json()

# Copy to clipboard
response = requests.post(
    f"{BASE_URL}/api/clipboard/copy",
    json={"clip_id": "abc123"}
)
```

### JavaScript

```javascript
const BASE_URL = "http://localhost:8000";

// Get recent history
fetch(`${BASE_URL}/api/history/recent`)
  .then(res => res.json())
  .then(history => console.log(history));

// Create snippet
fetch(`${BASE_URL}/api/snippets`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    content: "const hello = () => console.log('Hello')",
    folder_name: "Code",
    name: "Hello Function"
  })
})
  .then(res => res.json())
  .then(data => console.log(data));

// Search
fetch(`${BASE_URL}/api/search?q=python`)
  .then(res => res.json())
  .then(results => console.log(results));
```

### cURL

```bash
#!/bin/bash
BASE_URL="http://localhost:8000"

# Get stats
curl "$BASE_URL/api/stats"

# Create snippet
curl -X POST "$BASE_URL/api/snippets" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "#!/bin/bash\necho Hello",
    "folder_name": "Shell",
    "name": "Hello Script"
  }'

# Search
curl "$BASE_URL/api/search?q=hello"

# Delete history item
curl -X DELETE "$BASE_URL/api/history/abc123"
```

### Swift (for menu bar app)

```swift
import Foundation

class SimpleCPAPI {
    let baseURL = "http://localhost:8000"

    func getRecentHistory(completion: @escaping ([ClipboardItem]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/history/recent") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let items = try? JSONDecoder().decode([ClipboardItem].self, from: data)
            completion(items)
        }.resume()
    }

    func createSnippet(content: String, folder: String, name: String,
                      completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/snippets") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "content": content,
            "folder_name": folder,
            "name": name
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(error == nil)
        }.resume()
    }
}
```

---

## Client Libraries

### Official

Coming soon:
- Python client library
- JavaScript/TypeScript client
- Swift SDK

### Community

Check GitHub for community-contributed libraries.

---

## Interactive Documentation

**Swagger UI** (when running):
```
http://localhost:8000/docs
```

**ReDoc**:
```
http://localhost:8000/redoc
```

**OpenAPI JSON**:
```
http://localhost:8000/openapi.json
```

---

## API Versioning

**Current**: v1 (implicit)

**Future**: Versioned endpoints (`/api/v2/...`)

**Stability**: Breaking changes will be announced in advance

---

## Support

- **Issues**: [GitHub Issues](https://github.com/YourUsername/SimpleCP/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YourUsername/SimpleCP/discussions)
- **Email**: api@simplecp.app

---

**API Version**: 1.0.0
**Last Updated**: January 2025

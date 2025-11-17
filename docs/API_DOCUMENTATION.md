# SimpleCP REST API Documentation

## Overview

SimpleCP provides a comprehensive REST API for clipboard management, with advanced features including:
- Clipboard history management
- Snippet organization
- Advanced search with fuzzy matching and regex
- Analytics and insights
- Import/Export functionality
- Privacy and security features
- Settings management

**Base URL:** `http://localhost:8000`

**API Documentation:** `http://localhost:8000/docs` (Interactive Swagger UI)

---

## Table of Contents

1. [History Endpoints](#history-endpoints)
2. [Snippet Endpoints](#snippet-endpoints)
3. [Folder Endpoints](#folder-endpoints)
4. [Clipboard Operations](#clipboard-operations)
5. [Search Endpoints](#search-endpoints)
6. [Settings Endpoints](#settings-endpoints)
7. [Analytics Endpoints](#analytics-endpoints)
8. [Import/Export Endpoints](#import-export-endpoints)
9. [Bulk Operations](#bulk-operations)
10. [Pagination](#pagination)
11. [Privacy Endpoints](#privacy-endpoints)

---

## History Endpoints

### Get All History
```http
GET /api/history?limit={limit}
```

**Query Parameters:**
- `limit` (optional): Maximum number of items to return

**Response:**
```json
[
  {
    "clip_id": "abc123...",
    "content": "clipboard text content",
    "timestamp": "2024-11-17T10:30:00.000000",
    "content_type": "text",
    "source_app": "Chrome",
    "display_string": "clipboard text content",
    "snippet_name": null,
    "folder_path": null,
    "tags": []
  }
]
```

### Get Recent History
```http
GET /api/history/recent
```

Returns the 10 most recent clipboard items.

### Get History Folders
```http
GET /api/history/folders
```

Returns auto-generated folder ranges (11-20, 21-30, etc.).

### Delete History Item
```http
DELETE /api/history/{clip_id}
```

**Response:**
```json
{
  "success": true,
  "message": "Item deleted"
}
```

### Clear All History
```http
DELETE /api/history
```

**Response:**
```json
{
  "success": true,
  "message": "History cleared"
}
```

### Get Paginated History
```http
GET /api/history/paginated?page={page}&page_size={page_size}&sort_by={field}&reverse={bool}
```

**Query Parameters:**
- `page` (default: 1): Page number
- `page_size` (default: 20): Items per page
- `sort_by` (optional): Field to sort by (timestamp, content_type, source_app)
- `reverse` (default: false): Reverse sort order

**Response:**
```json
{
  "items": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_items": 100,
    "total_pages": 5,
    "has_next": true,
    "has_previous": false
  }
}
```

---

## Snippet Endpoints

### Get All Snippets
```http
GET /api/snippets
```

Returns all snippets organized by folder.

### Get Snippet Folders
```http
GET /api/snippets/folders
```

Returns list of folder names.

### Get Folder Snippets
```http
GET /api/snippets/{folder_name}
```

Returns all snippets in a specific folder.

### Create Snippet
```http
POST /api/snippets
```

**Request Body:**
```json
{
  "clip_id": "abc123...",  // Optional: convert from history
  "content": "snippet content",  // Optional: create directly
  "name": "My Snippet",
  "folder": "Code",
  "tags": ["python", "example"]
}
```

### Update Snippet
```http
PUT /api/snippets/{folder_name}/{clip_id}
```

**Request Body:**
```json
{
  "content": "updated content",
  "name": "Updated Name",
  "tags": ["new", "tags"]
}
```

### Delete Snippet
```http
DELETE /api/snippets/{folder_name}/{clip_id}
```

### Move Snippet
```http
POST /api/snippets/{folder_name}/{clip_id}/move
```

**Request Body:**
```json
{
  "to_folder": "New Folder"
}
```

### Get Paginated Snippets
```http
GET /api/snippets/paginated?folder={folder}&page={page}&page_size={page_size}
```

---

## Folder Endpoints

### Create Folder
```http
POST /api/folders
```

**Request Body:**
```json
{
  "folder_name": "My Folder"
}
```

### Rename Folder
```http
PUT /api/folders/{folder_name}
```

**Request Body:**
```json
{
  "new_name": "Renamed Folder"
}
```

### Delete Folder
```http
DELETE /api/folders/{folder_name}
```

Deletes folder and all its snippets.

---

## Clipboard Operations

### Copy to Clipboard
```http
POST /api/clipboard/copy
```

**Request Body:**
```json
{
  "clip_id": "abc123..."
}
```

Copies item to system clipboard and tracks analytics.

---

## Search Endpoints

### Basic Search
```http
GET /api/search?q={query}
```

Searches across history and snippets.

**Response:**
```json
{
  "history": [...],
  "snippets": [...]
}
```

### Advanced Search
```http
GET /api/search/advanced?q={query}&search_type={type}&content_types={types}&source_apps={apps}&tags={tags}&start_date={date}&end_date={date}&sort_by={field}&reverse={bool}
```

**Query Parameters:**
- `q` (optional): Search query
- `search_type` (default: fuzzy): Search type (fuzzy, regex, exact)
- `content_types` (optional): Comma-separated content types (text,url,email,code)
- `source_apps` (optional): Comma-separated app names
- `tags` (optional): Comma-separated tags
- `start_date` (optional): ISO format date (2024-11-17T00:00:00)
- `end_date` (optional): ISO format date
- `sort_by` (optional): Field to sort by
- `reverse` (default: false): Reverse sort order

**Examples:**
```bash
# Fuzzy search for "meeting"
GET /api/search/advanced?q=meeting&search_type=fuzzy

# Find all URLs from Chrome
GET /api/search/advanced?content_types=url&source_apps=Chrome

# Regex search for email addresses
GET /api/search/advanced?q=\w+@\w+\.com&search_type=regex

# Find items from last week
GET /api/search/advanced?start_date=2024-11-10T00:00:00&end_date=2024-11-17T23:59:59
```

---

## Settings Endpoints

### Get All Settings
```http
GET /api/settings
```

Returns complete settings configuration.

### Get Settings Section
```http
GET /api/settings/{section}
```

**Sections:** `history`, `privacy`, `shortcuts`, `search`, `display`, `menubar`, `startup`, `backend`, `analytics`, `export`

### Update Settings Section
```http
PUT /api/settings/{section}
```

**Request Body:**
```json
{
  "max_items": 100,
  "display_count": 15
}
```

### Import Settings
```http
POST /api/settings/import?merge={bool}
```

**Request Body:** Complete or partial settings object

**Query Parameters:**
- `merge` (default: true): Merge with existing or replace

### Reset Settings Section
```http
POST /api/settings/reset/{section}
```

Resets section to default values.

---

## Analytics Endpoints

### Get Analytics Summary
```http
GET /api/analytics/summary?period={period}
```

**Query Parameters:**
- `period` (default: week): Period to analyze (day, week, month, all)

**Response:**
```json
{
  "period": "week",
  "start_date": "2024-11-10T00:00:00",
  "end_date": "2024-11-17T23:59:59",
  "total_events": 150,
  "average_per_day": 21.43,
  "type_breakdown": {
    "text": 100,
    "url": 30,
    "code": 20
  },
  "app_breakdown": {
    "Chrome": 50,
    "VSCode": 40,
    "Terminal": 30
  },
  "action_breakdown": {
    "copy": 100,
    "paste": 50
  },
  "most_active_hour": 14
}
```

### Get Most Copied Items
```http
GET /api/analytics/most-copied?limit={limit}
```

**Query Parameters:**
- `limit` (default: 10): Number of items to return

**Response:**
```json
[
  {
    "item": {...},
    "copy_count": 15
  }
]
```

### Get App Statistics
```http
GET /api/analytics/apps
```

Returns usage statistics by source application.

### Get Type Statistics
```http
GET /api/analytics/types
```

Returns usage statistics by content type.

### Get Daily Statistics
```http
GET /api/analytics/daily?days={days}
```

**Query Parameters:**
- `days` (default: 30): Number of days to include

### Get Hourly Distribution
```http
GET /api/analytics/hourly
```

Returns hourly usage distribution.

### Get Insights
```http
GET /api/analytics/insights
```

Returns AI-generated insights about usage patterns.

### Cleanup Analytics
```http
POST /api/analytics/cleanup?retention_days={days}
```

**Query Parameters:**
- `retention_days` (default: 90): Days to retain

---

## Import/Export Endpoints

### Export History
```http
GET /api/export/history?format={format}&limit={limit}
```

**Query Parameters:**
- `format` (default: json): Export format (json, csv, txt)
- `limit` (optional): Maximum items to export

**Response:** File download

### Export Snippets
```http
GET /api/export/snippets?format={format}&folder={folder}
```

**Query Parameters:**
- `format` (default: json): Export format (json, csv, txt)
- `folder` (optional): Specific folder to export

### Export Selected Items
```http
POST /api/export/selected?format={format}
```

**Request Body:**
```json
{
  "clip_ids": ["abc123...", "def456..."],
  "format": "json"
}
```

### Create Backup
```http
POST /api/backup/create
```

Creates a complete backup zip file.

**Response:**
```json
{
  "success": true,
  "backup_file": "/tmp/simplecp_backup_20241117_153000.zip",
  "message": "Backup created"
}
```

### Restore Backup
```http
POST /api/backup/restore
```

**Request Body:**
```json
{
  "filepath": "/path/to/backup.zip"
}
```

### Import from JSON
```http
POST /api/import/json?merge={bool}
```

**Request Body:**
```json
{
  "filepath": "/path/to/export.json",
  "merge": true
}
```

### Import from CSV
```http
POST /api/import/csv?merge={bool}
```

---

## Bulk Operations

### Bulk Delete
```http
POST /api/bulk/delete
```

**Request Body:**
```json
{
  "clip_ids": ["abc123...", "def456...", "ghi789..."]
}
```

**Response:**
```json
{
  "success": true,
  "deleted_count": 3,
  "total_requested": 3
}
```

### Bulk Copy to Folder
```http
POST /api/bulk/copy
```

**Request Body:**
```json
{
  "clip_ids": ["abc123...", "def456..."],
  "folder": "Archive"
}
```

Copies multiple history items to a snippet folder.

---

## Privacy Endpoints

### Get Excluded Apps
```http
GET /api/privacy/excluded-apps
```

Returns list of excluded applications.

### Add Excluded App
```http
POST /api/privacy/exclude-app?app_name={app_name}
```

### Remove Excluded App
```http
DELETE /api/privacy/exclude-app?app_name={app_name}
```

### Toggle Privacy Mode
```http
POST /api/privacy/mode?enabled={bool}
```

**Query Parameters:**
- `enabled`: Enable or disable privacy mode

### Validate Content
```http
GET /api/privacy/validate?content={content}
```

Checks content for sensitive data.

**Response:**
```json
{
  "is_safe": false,
  "detected_types": ["password_indicators", "credit_card"],
  "should_filter": true,
  "risk_level": "high"
}
```

---

## Statistics Endpoint

### Get Stats
```http
GET /api/stats
```

**Response:**
```json
{
  "history_count": 45,
  "snippet_count": 23,
  "folder_count": 5,
  "max_history": 50,
  "analytics": {
    "total_copies": 1250,
    "unique_items": 320,
    "top_app": "Chrome",
    "top_type": "text",
    "most_active_hour": 14,
    "average_daily_copies": 35.5
  }
}
```

---

## Health Check

### Health Endpoint
```http
GET /health
```

Returns server health status with statistics.

---

## Error Responses

All endpoints return standard HTTP status codes:

- `200 OK`: Success
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource conflict (e.g., folder already exists)
- `500 Internal Server Error`: Server error

**Error Response Format:**
```json
{
  "detail": "Error message description"
}
```

---

## Rate Limiting

Currently no rate limiting is implemented. For production use, consider implementing rate limiting at the API gateway level.

---

## Authentication

Currently no authentication is required. The API is designed to run locally. For remote access, implement authentication middleware.

---

## CORS

CORS is enabled for all origins. For production, configure allowed origins in the FastAPI server configuration.

---

## Examples

### Python Example
```python
import requests

# Get recent history
response = requests.get('http://localhost:8000/api/history/recent')
items = response.json()

# Copy item to clipboard
requests.post('http://localhost:8000/api/clipboard/copy', json={'clip_id': items[0]['clip_id']})

# Advanced search
response = requests.get('http://localhost:8000/api/search/advanced', params={
    'q': 'meeting',
    'search_type': 'fuzzy',
    'content_types': 'text,url'
})
results = response.json()
```

### cURL Example
```bash
# Get stats
curl http://localhost:8000/api/stats

# Create snippet
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Example snippet",
    "name": "My Snippet",
    "folder": "Code",
    "tags": ["example"]
  }'

# Export history
curl http://localhost:8000/api/export/history?format=json -o history.json
```

---

## WebSocket Support (Future)

WebSocket support for real-time clipboard updates is planned for a future release.

---

## API Versioning

Current version: v1 (no version prefix in URL)

Future versions will use URL prefix: `/v2/api/...`

# SimpleCP API Reference

Complete reference for the SimpleCP REST API.

## Base URL

```
http://localhost:8000
```

## Authentication

Currently, SimpleCP does not require authentication. For production deployments, consider adding API key authentication via the `API_KEY` environment variable.

## Endpoints

### Health & Status

#### Health Check

Check if the API is healthy.

```http
GET /health
```

**Response**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0"
}
```

#### Statistics

Get usage statistics.

```http
GET /api/stats
```

**Response**

```json
{
  "history_count": 42,
  "snippet_count": 15,
  "folder_count": 3,
  "total_clips": 57
}
```

### History

#### Get All History

```http
GET /api/history
```

**Response**

```json
{
  "items": [
    {
      "clip_id": "abc123",
      "content": "example text",
      "content_type": "text",
      "timestamp": "2024-01-01T12:00:00Z"
    }
  ],
  "count": 1
}
```

#### Get Recent History

```http
GET /api/history/recent?limit=10
```

**Query Parameters**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | integer | 10 | Number of items to return |

#### Get History Folders

Auto-generated folders based on position in history.

```http
GET /api/history/folders
```

#### Delete History Item

```http
DELETE /api/history/{clip_id}
```

#### Clear All History

```http
DELETE /api/history
```

### Snippets

#### Get All Snippets

```http
GET /api/snippets
```

**Response**

```json
{
  "snippets": {
    "Code": [
      {
        "clip_id": "xyz789",
        "content": "print('hello')",
        "name": "Hello World",
        "tags": ["python", "example"]
      }
    ]
  }
}
```

#### Get Folder Contents

```http
GET /api/snippets/{folder_name}
```

#### Create Snippet

```http
POST /api/snippets
Content-Type: application/json

{
  "content": "example snippet",
  "name": "My Snippet",
  "folder": "Code",
  "tags": ["tag1", "tag2"],
  "from_history": false,
  "clip_id": null
}
```

#### Update Snippet

```http
PUT /api/snippets/{folder_name}/{clip_id}
Content-Type: application/json

{
  "name": "Updated Name",
  "tags": ["new", "tags"]
}
```

#### Delete Snippet

```http
DELETE /api/snippets/{folder_name}/{clip_id}
```

#### Move Snippet

```http
POST /api/snippets/{folder_name}/{clip_id}/move
Content-Type: application/json

{
  "target_folder": "New Folder"
}
```

### Folders

#### Get Folder List

```http
GET /api/snippets/folders
```

#### Create Folder

```http
POST /api/folders
Content-Type: application/json

{
  "name": "New Folder"
}
```

#### Rename Folder

```http
PUT /api/folders/{folder_name}
Content-Type: application/json

{
  "new_name": "Renamed Folder"
}
```

#### Delete Folder

```http
DELETE /api/folders/{folder_name}
```

### Operations

#### Copy to Clipboard

```http
POST /api/clipboard/copy
Content-Type: application/json

{
  "clip_id": "abc123"
}
```

#### Search

Search across all clipboard items and snippets.

```http
GET /api/search?q=query&limit=20
```

**Query Parameters**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| q | string | required | Search query |
| limit | integer | 20 | Max results per category |

**Response**

```json
{
  "history_results": [...],
  "snippet_results": [...],
  "total_results": 5
}
```

## Error Responses

### Error Format

```json
{
  "detail": "Error message here"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 404 | Not Found |
| 500 | Internal Server Error |

## Rate Limiting

Currently no rate limiting is enforced. Consider implementing rate limiting for production deployments.

## CORS

CORS is enabled by default for local development. Configure via `CORS_ORIGINS` environment variable.

## Interactive Documentation

Visit these URLs when the server is running:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- OpenAPI JSON: http://localhost:8000/openapi.json

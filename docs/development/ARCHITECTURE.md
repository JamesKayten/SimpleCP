# SimpleCP Architecture

## Overview

SimpleCP follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│         REST API Layer              │
│         (FastAPI)                   │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      Business Logic Layer           │
│      (ClipboardManager)             │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      Data Store Layer               │
│  (HistoryStore, SnippetStore)       │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      Persistence Layer              │
│         (JSON Files)                │
└─────────────────────────────────────┘
```

## Components

### 1. API Layer (`api/`)

**Responsibility**: HTTP interface and request/response handling

- `models.py` - Pydantic models for validation
- `endpoints.py` - Route handlers
- `server.py` - FastAPI application setup

**Key Features**:
- Request validation
- Response serialization
- OpenAPI documentation
- CORS handling

### 2. Business Logic (`clipboard_manager.py`)

**Responsibility**: Core application logic and coordination

- Clipboard monitoring
- Store management
- Content type detection
- Search coordination

**Key Features**:
- Clipboard polling
- Deduplication logic
- Event handling
- Cross-store operations

### 3. Data Stores (`stores/`)

**Responsibility**: Data management and persistence

#### ClipboardItem (`clipboard_item.py`)
- Data model for clipboard entries
- Content type detection
- Serialization/deserialization

#### HistoryStore (`history_store.py`)
- Manages clipboard history
- Auto-deduplication
- Size limits and trimming
- Auto-generated folders

#### SnippetStore (`snippet_store.py`)
- Folder-based organization
- CRUD operations
- Snippet metadata management

### 4. Configuration (`config/`)

**Responsibility**: Application configuration

- `settings.py` - Centralized settings
- `logging_config.py` - Logging setup

### 5. Monitoring (`monitoring/`)

**Responsibility**: Observability and health

- `metrics.py` - Metrics collection
- `health.py` - Health checks

## Design Patterns

### 1. Repository Pattern

Data stores act as repositories:

```python
# Abstract interface
class Store:
    def add(item) -> None
    def get(id) -> Item
    def delete(id) -> None
    def search(query) -> List[Item]
```

### 2. Singleton Pattern

Global instances for shared resources:

```python
_settings = None

def get_settings() -> Settings:
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings
```

### 3. Delegate Pattern

Event-driven updates (inspired by Flycut):

```python
class ClipboardManager:
    def on_clipboard_change(self, content):
        # Notify listeners
        self.history_store.add(content)
```

### 4. Facade Pattern

ClipboardManager provides simplified interface:

```python
manager = ClipboardManager()
manager.add_clip("text")  # Handles store selection
manager.search_all("query")  # Searches all stores
```

## Data Flow

### Adding Clipboard Item

```
User copies text
    ↓
ClipboardManager.monitor()
    ↓
Detect clipboard change
    ↓
Create ClipboardItem
    ↓
HistoryStore.add()
    ↓
Check for duplicates
    ↓
Save to JSON
    ↓
Notify via logs
```

### API Request Flow

```
HTTP Request
    ↓
FastAPI Router
    ↓
Pydantic Validation
    ↓
Endpoint Handler
    ↓
ClipboardManager
    ↓
Data Store
    ↓
JSON Persistence
    ↓
Response Serialization
    ↓
HTTP Response
```

## Persistence

### JSON Storage

- **Location**: `data/` directory
- **Format**: JSON with pretty printing
- **Files**:
  - `history.json` - Clipboard history
  - `snippets.json` - Snippet folders

### Data Structure

**history.json**:
```json
[
  {
    "clip_id": "uuid",
    "content": "text",
    "content_type": "text",
    "timestamp": "ISO8601"
  }
]
```

**snippets.json**:
```json
{
  "folder_name": [
    {
      "clip_id": "uuid",
      "content": "text",
      "name": "snippet name",
      "tags": ["tag1"]
    }
  ]
}
```

## Concurrency

### Current Implementation

- Single-threaded operation
- No concurrent access protection
- Suitable for single-user scenarios

### Future Considerations

For multi-user scenarios:
- Add file locking
- Implement database backend
- Use async/await throughout
- Add request queuing

## Error Handling

### Layers

1. **API Layer**: HTTP error responses
2. **Business Logic**: Custom exceptions
3. **Data Layer**: Validation errors
4. **Persistence**: IO errors

### Strategy

```python
try:
    item = store.add(content)
except ValueError as e:
    # Handle validation error
    raise HTTPException(400, str(e))
except IOError as e:
    # Handle persistence error
    raise HTTPException(500, "Storage error")
```

## Testing Strategy

### Unit Tests

Test individual components in isolation:
- ClipboardItem creation
- Store operations
- Manager logic

### Integration Tests

Test component interactions:
- API endpoints
- Full request/response cycle
- Store persistence

### Test Structure

```
tests/
├── unit/
│   ├── test_clipboard_item.py
│   ├── test_history_store.py
│   └── test_snippet_store.py
└── integration/
    └── test_api.py
```

## Performance Considerations

### Current Optimizations

- In-memory caching of stores
- Efficient deduplication
- Lazy loading of items
- Limited history size

### Bottlenecks

- JSON serialization for large histories
- Linear search in stores
- Clipboard polling overhead

### Future Optimizations

- Database backend (SQLite/PostgreSQL)
- Indexed search
- Incremental persistence
- Async clipboard monitoring

## Security Considerations

### Current Status

- No authentication
- Local-only by default
- CORS protection

### Recommendations

- Add API key authentication
- Implement rate limiting
- Add input sanitization
- Enable HTTPS
- Add audit logging

## Extensibility

### Adding New Features

1. **New Store Type**: Implement Store interface
2. **New API Endpoint**: Add to `endpoints.py`
3. **New Content Type**: Update detection logic
4. **New Export Format**: Add serialization method

### Plugin System (Future)

```python
class Plugin:
    def on_clip_added(self, item):
        pass

    def on_search(self, query):
        pass
```

## Dependencies

### Core

- **FastAPI**: Web framework
- **Pydantic**: Data validation
- **Uvicorn**: ASGI server
- **pyperclip**: Clipboard access

### Development

- **pytest**: Testing
- **black**: Formatting
- **mypy**: Type checking

## Deployment

### Standalone

```bash
python daemon.py
```

### Systemd

```bash
systemctl start simplecp
```

### Docker

```bash
docker-compose up
```

## Monitoring

### Metrics Collected

- Clipboard additions
- API requests
- Search queries
- Store sizes

### Health Checks

- API availability
- Disk space
- Memory usage
- Data directory access

## Future Architecture

### Planned Improvements

1. **Database Backend**: SQLite or PostgreSQL
2. **WebSocket Support**: Real-time updates
3. **Plugin System**: Extensibility
4. **Multi-user Support**: Authentication and isolation
5. **Encryption**: At-rest data encryption

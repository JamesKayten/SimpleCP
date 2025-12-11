# Folder API Integration Documentation

## Overview

This document describes the integration between SimpleCP's Swift frontend and Python backend for folder management operations.

## Architecture

### Hybrid Storage Model

SimpleCP uses a **hybrid architecture** that combines:

1. **Local Storage (UserDefaults)**: For fast, offline access and responsive UI
2. **Backend API (REST)**: For persistent storage and cross-device synchronization (future)

### Data Flow

```
User Action → Frontend (Swift)
    ↓
    ├─→ Update Local State (UserDefaults) [Immediate]
    │
    └─→ Sync with Backend API (async) [Background]
        ↓
        ├─→ Success: Log confirmation
        └─→ Failure: Revert local state + Show error
```

## Implementation Details

### Frontend Components

#### 1. APIClient (`Services/APIClient.swift`)

**Purpose**: Centralized API communication layer

**Key Features**:
- Singleton pattern (`APIClient.shared`)
- Base URL: `http://localhost:8080`
- Async/await Swift concurrency
- Comprehensive error handling
- Logging for debugging

**Methods**:
```swift
func renameFolder(oldName: String, newName: String) async throws
func createFolder(name: String) async throws
func deleteFolder(name: String) async throws
```

**Error Types**:
- `.invalidURL` - Malformed API endpoint
- `.networkError` - Connection issues
- `.invalidResponse` - Server response issues
- `.httpError` - HTTP status code errors (404, 409, 500, etc.)
- `.decodingError` - JSON parsing failures

#### 2. ClipboardManager (`Managers/ClipboardManager.swift`)

**Updated Methods**:

**`createFolder(name:icon:)`**:
1. Creates folder in local `folders` array
2. Saves to UserDefaults
3. Calls `APIClient.shared.createFolder()` asynchronously
4. Shows error if API call fails (doesn't revert - folder already exists locally)

**`updateFolder(_:)`**:
1. Detects if name changed (indicates rename)
2. Updates local `folders` array
3. Saves to UserDefaults
4. If renamed: calls `APIClient.shared.renameFolder(oldName:newName:)` asynchronously
5. **Reverts local change** if API call fails

**`deleteFolder(_:)`**:
1. Removes folder and associated snippets from local arrays
2. Saves to UserDefaults
3. Calls `APIClient.shared.deleteFolder()` asynchronously
4. Shows error if API call fails (doesn't restore - deletion is destructive)

#### 3. AppError (`Models/AppError.swift`)

**New Error Case**:
```swift
case apiError(String)
```

**User-Facing Messages**:
- **Description**: "API Error: {message}"
- **Recovery**: "Make sure the backend server is running on localhost:8080. Try restarting the backend."
- **Failure Reason**: "Unable to communicate with the backend server."

### Backend Components

#### API Endpoints (`backend/api/endpoints.py`)

**Folder Rename Endpoint**:
```python
PUT /api/folders/{folder_name}
Content-Type: application/json

Body: { "new_name": "NewFolderName" }

Responses:
- 200: { "success": true, "message": "Folder renamed" }
- 404: { "detail": "Folder not found or new name exists" }
```

**Folder Create Endpoint**:
```python
POST /api/folders
Content-Type: application/json

Body: { "folder_name": "FolderName" }

Responses:
- 200: { "success": true, "message": "Folder created" }
- 409: { "detail": "Folder already exists" }
```

**Folder Delete Endpoint**:
```python
DELETE /api/folders/{folder_name}

Responses:
- 200: { "success": true, "message": "Folder deleted" }
- 404: { "detail": "Folder not found" }
```

#### Store Layer (`backend/stores/snippet_store.py`)

**Key Methods**:
- `create_folder(folder_name: str) -> bool`
- `rename_folder(old_name: str, new_name: str) -> bool`
- `delete_folder(folder_name: str) -> bool`

**Delegate Notifications**:
- `folder_created` - Notifies observers when folder is created
- `folder_renamed` - Notifies observers when folder is renamed
- `folder_deleted` - Notifies observers when folder is deleted

## Key Design Decisions

### 1. UUID vs Name-Based Identification

**Frontend**: Uses UUIDs for folder identification
- Allows renames without breaking references
- Unique identification across devices
- More robust for concurrent operations

**Backend**: Uses names for folder identification
- Simpler file-based storage
- Human-readable folder structure
- Legacy compatibility

**Integration**: Folder names bridge the two systems
- Frontend tracks old/new names during renames
- API uses name-based endpoints
- Mapping is 1:1 (names must be unique)

### 2. Optimistic UI Updates

**Why**: Responsive user experience
**How**: Update local state immediately, sync asynchronously
**Risk**: State divergence if API fails
**Mitigation**: Revert local changes on critical failures (rename)

### 3. Async Error Handling

**Pattern**:
```swift
Task {
    do {
        try await APIClient.shared.renameFolder(...)
        await MainActor.run {
            // Success logging
        }
    } catch {
        await MainActor.run {
            // Error handling on main thread
            // Update UI state
            // Show error to user
        }
    }
}
```

**Benefits**:
- Non-blocking UI
- Proper concurrency handling
- MainActor for UI updates

## Testing

### Backend Tests

**Location**: `backend/tests/test_snippet_folder.py`

**Test Coverage**:
- ✅ `test_create_folder` - Folder creation
- ✅ `test_rename_folder` - Folder renaming
- ✅ `test_delete_folder` - Folder deletion
- ✅ All 15 folder/snippet tests pass

**Run Tests**:
```bash
cd backend
python3 -m pytest tests/test_snippet_folder.py -v
```

### Frontend Testing

**Manual Test Checklist**:

1. **Rename Folder (Backend Running)**:
   - [ ] Start backend: `cd backend && python3 main.py`
   - [ ] Open SimpleCP frontend
   - [ ] Right-click a folder
   - [ ] Select "Rename Folder..."
   - [ ] Enter new name
   - [ ] Click "Rename"
   - [ ] Verify folder renamed in UI
   - [ ] Check backend logs for sync confirmation
   - [ ] Verify no errors in Console.app

2. **Rename Folder (Backend Stopped)**:
   - [ ] Stop backend server
   - [ ] Try to rename a folder
   - [ ] Verify error message appears
   - [ ] Verify folder name reverts to original
   - [ ] Check Console.app for API error logs

3. **Create/Delete Folder**:
   - [ ] Test folder creation with backend running
   - [ ] Test folder deletion with backend running
   - [ ] Verify sync in backend logs

## Logging

### Frontend Logs

**Location**: Console.app (filter by "SimpleCP" or "com.simplecp.app")

**Log Categories**:
- `📡 API:` - API requests
- `✅` - Successful operations
- `❌ API Error:` - API failures
- `❌ Network error:` - Connection failures
- `✏️` - Folder updates

**Example Logs**:
```
📡 API: Renaming folder 'OldName' to 'NewName'
✅ Folder renamed successfully
✏️ Folder renamed: 'OldName' → 'NewName' (synced with backend)
```

### Backend Logs

**Run Backend with Logging**:
```bash
cd backend
python3 main.py
```

**Expected Output**:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8080
```

## Troubleshooting

### Issue: "Failed to sync folder rename with backend"

**Symptoms**:
- Error dialog appears after renaming
- Folder name reverts to original
- Console shows network errors

**Solutions**:
1. Check backend is running: `ps aux | grep main.py`
2. Start backend: `cd backend && python3 main.py`
3. Verify port 8080 not in use: `lsof -i :8080`
4. Check firewall settings

### Issue: Folder renamed in frontend but not backend

**Symptoms**:
- Frontend shows new name
- Backend still has old name
- No error message

**Diagnosis**:
- Check Console.app for silent failures
- Verify backend received request (check backend logs)
- Test API directly:
  ```bash
  curl -X PUT http://localhost:8080/api/folders/OldName \
       -H "Content-Type: application/json" \
       -d '{"new_name":"NewName"}'
  ```

**Solutions**:
- Restart backend server
- Clear frontend UserDefaults
- Check network connectivity to localhost

### Issue: 404 "Folder not found"

**Cause**: Folder exists in frontend but not backend (state divergence)

**Solutions**:
1. Sync state: Restart both frontend and backend
2. Create folder in backend:
   ```bash
   curl -X POST http://localhost:8080/api/folders \
        -H "Content-Type: application/json" \
        -d '{"folder_name":"MissingFolder"}'
   ```
3. Delete folder from frontend and recreate

## Future Enhancements

### Potential Improvements

1. **Full Sync on Startup**:
   - Fetch all folders from backend on app launch
   - Merge with local UserDefaults
   - Resolve conflicts intelligently

2. **Retry Logic**:
   - Automatic retry for failed API calls
   - Exponential backoff
   - Queue for offline operations

3. **Bidirectional Sync**:
   - Poll backend for changes
   - WebSocket for real-time updates
   - Handle concurrent modifications

4. **Conflict Resolution**:
   - Last-write-wins
   - User-prompted resolution
   - Version vectors

5. **UUID Migration**:
   - Add UUID support to backend
   - Migrate from name-based to UUID-based identification
   - Maintain backward compatibility

6. **Offline Mode**:
   - Queue operations while offline
   - Sync when connection restored
   - Optimistic UI updates with conflict markers

## References

- Frontend README: `/frontend/SimpleCP-macOS/README.md`
- API Documentation: `/docs/API.md`
- Backend Tests: `/backend/tests/test_snippet_folder.py`
- UI/UX Spec: `/docs/UI_UX_SPECIFICATION_v3.md`

## Changelog

### 2025-11-22: Initial Integration
- Created APIClient for backend communication
- Integrated folder rename with backend
- Added API error handling
- Updated ClipboardManager for async sync
- Documented architecture and testing procedures

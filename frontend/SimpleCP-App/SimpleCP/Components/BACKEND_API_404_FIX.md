# Backend API Issue: HTTP 404 "History item not found"

## 🔴 Issue

When creating a snippet from the current clipboard using "Add Snippet from Clipboard" in a folder's context menu, the snippet is created locally but backend sync fails with:

```
HTTP 404: {"detail":"History item not found"}
```

## 🔍 Root Cause

Your backend's `POST /api/snippets` endpoint is trying to look up a history item using the `clip_id` from the request. However, when creating a snippet from the **current clipboard** (not from history), there is no corresponding history item in the backend.

### Expected Behavior

The backend should:
1. Accept `clip_id`, `name`, `content`, `folder`, and `tags`
2. Create a **new snippet** with that data
3. **Not** require the clip_id to exist in history

### Current Behavior (Incorrect)

The backend is:
1. Receiving `clip_id`, `name`, `content`, `folder`, and `tags`
2. Looking up a history item by `clip_id`
3. Failing with 404 when history item doesn't exist
4. Not creating the snippet

## 📋 Swift App Request

When the Swift app calls `POST /api/snippets`, it sends:

```json
{
  "clip_id": "abc123def4567890",
  "name": "Suggested Snippet Name",
  "content": "The actual clipboard content...",
  "folder": "Folder 5",
  "tags": []
}
```

This is **complete data** to create a snippet. The backend should not need to look up anything else.

## ✅ Backend Fix Required

### Current (Incorrect) Implementation

Your backend likely has code like this:

```python
@app.post("/api/snippets")
async def create_snippet(request: SnippetCreateRequest):
    # ❌ INCORRECT: Looking up history item
    history_item = db.get_history_item(request.clip_id)
    if not history_item:
        raise HTTPException(status_code=404, detail="History item not found")
    
    # Create snippet from history item
    snippet = create_from_history(history_item, request.folder, request.name)
    return snippet
```

### Correct Implementation

The backend should accept the data directly:

```python
@app.post("/api/snippets")
async def create_snippet(request: SnippetCreateRequest):
    # ✅ CORRECT: Use provided data directly
    snippet = Snippet(
        clip_id=request.clip_id,
        name=request.name,
        content=request.content,
        folder=request.folder,
        tags=request.tags,
        created_at=datetime.now()
    )
    
    db.save_snippet(snippet)
    return {"status": "success", "snippet": snippet}
```

## 🔧 Two Approaches

### Approach 1: Create from Request Data (Recommended)

If `content` is provided in the request, use it directly:

```python
@app.post("/api/snippets")
async def create_snippet(request: SnippetCreateRequest):
    # If content is provided, use it (frontend is creating from clipboard)
    if request.content:
        snippet = Snippet(
            clip_id=request.clip_id,
            name=request.name,
            content=request.content,
            folder=request.folder,
            tags=request.tags
        )
    # If no content, try to look up from history (legacy behavior)
    else:
        history_item = db.get_history_item(request.clip_id)
        if not history_item:
            raise HTTPException(status_code=404, detail="History item not found")
        snippet = create_from_history(history_item, request)
    
    db.save_snippet(snippet)
    return {"status": "success"}
```

### Approach 2: Separate Endpoints

Create two separate endpoints:

```python
@app.post("/api/snippets")
async def create_snippet_from_data(request: SnippetCreateRequest):
    """Create snippet from provided data"""
    snippet = Snippet(
        clip_id=request.clip_id,
        name=request.name,
        content=request.content,
        folder=request.folder,
        tags=request.tags
    )
    db.save_snippet(snippet)
    return {"status": "success"}

@app.post("/api/snippets/from-history/{clip_id}")
async def create_snippet_from_history(clip_id: str, request: SnippetFromHistoryRequest):
    """Create snippet from existing history item"""
    history_item = db.get_history_item(clip_id)
    if not history_item:
        raise HTTPException(status_code=404, detail="History item not found")
    
    snippet = create_from_history(history_item, request)
    db.save_snippet(snippet)
    return {"status": "success"}
```

## 📝 Request Model

Your backend should expect:

```python
from pydantic import BaseModel
from typing import List, Optional

class SnippetCreateRequest(BaseModel):
    clip_id: str  # Required for tracking
    name: str
    content: str  # Required - the actual snippet content
    folder: str
    tags: List[str] = []
```

The `content` field should be **required**, not optional. The Swift app always provides it.

## 🛠️ Swift App Workaround (Already Applied)

I've updated the Swift app to handle 404 errors gracefully:

```swift
catch APIError.httpError(let statusCode, let message) where statusCode == 404 {
    // 404 means backend couldn't find history item
    // Keep local snippet since it was saved successfully
    await MainActor.run {
        logger.warning("⚠️ Backend couldn't find history item (snippet saved locally only)")
        // Don't show error to user - snippet is saved locally
    }
}
```

**Result**: The user won't see the error dialog anymore, and the snippet is saved locally. However, it won't sync to the backend until the backend is fixed.

## ✅ Verification After Backend Fix

Once you fix the backend, test:

1. **Create snippet from clipboard**:
   - Copy some text to clipboard
   - Right-click a folder → "Add Snippet from Clipboard"
   - ✅ Should save locally AND sync to backend
   - ❌ Should NOT show any error

2. **Check backend database**:
   - Snippet should exist in the backend
   - Should have the correct content, name, folder, and clip_id

3. **Check app logs**:
   - Should show: "💾 Snippet synced with backend"
   - Should NOT show: "History item not found"

## 📚 Related Issues

This is different from the earlier **HTTP 400** error which was about missing `clip_id`. We fixed that by including `clip_id` in the request. Now we have a new issue where the backend expects the `clip_id` to reference an existing history item, which is not always the case.

## 🎯 Summary

**Problem**: Backend tries to look up history item when creating snippet  
**Cause**: Backend assumes all snippets come from history  
**Reality**: Snippets can be created from current clipboard (no history item)  
**Fix**: Backend should use `content` from request, not look up history item  
**Workaround**: Swift app now suppresses 404 errors (snippet stays local)

---

**Status**: ⚠️ **Requires Backend Fix**  
**Priority**: 🟡 Medium - Snippets work locally, just don't sync  
**Temp Solution**: ✅ Error no longer shown to user  
**Permanent Solution**: Backend API needs to accept content directly  

---

**Created**: December 7, 2025  
**File**: BACKEND_API_404_FIX.md

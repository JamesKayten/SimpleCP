# Backend Fix - Snippet Creation 404 Error

## Problem
When creating snippets, backend returns:
```
404 - {"detail":"History item not found"}
```

## Root Cause
Backend is trying to look up `clip_id` in history database. The Swift app already provides all data including content - no lookup needed.

## The Fix

Find your `POST /api/snippets` endpoint and replace it with this:

```python
@app.post("/api/snippets")
async def create_snippet(request: SnippetCreateRequest):
    """Create snippet from provided data - no history lookup needed"""
    
    snippet = Snippet(
        clip_id=request.clip_id,
        name=request.name,
        content=request.content,      # Use this directly - don't look it up!
        folder=request.folder,
        tags=request.tags,
        created_at=datetime.now(),
        modified_at=datetime.now()
    )
    
    db.save_snippet(snippet)
    
    return {"status": "success", "clip_id": snippet.clip_id}
```

## What to Remove

Delete any code that:
- Calls `db.get_history_item(clip_id)`
- Raises `HTTPException(status_code=404, detail="History item not found")`
- Looks up content from anywhere else

## Request Model

Make sure `content` is a required field:

```python
class SnippetCreateRequest(BaseModel):
    clip_id: str
    name: str
    content: str          # Required - not optional!
    folder: str
    tags: List[str] = []
```

## That's It

The Swift app sends everything you need. Just use `request.content` directly.

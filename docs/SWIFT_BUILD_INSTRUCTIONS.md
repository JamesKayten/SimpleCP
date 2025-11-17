# Swift Frontend Build Instructions

## Quick Start

### 1. Ensure Backend is Running

```bash
# Start the Python backend first
cd /home/user/SimpleCP
python3 -m uvicorn api.main:app --reload --host 127.0.0.1 --port 8000
```

Verify backend is healthy:
```bash
curl http://127.0.0.1:8000/api/health
# Should return: {"status":"healthy","history_count":X,"snippet_folders":Y}
```

### 2. Open and Build the Xcode Project

```bash
# Open in Xcode
open SimpleCP.xcodeproj
```

**In Xcode:**
1. Select the "SimpleCP" scheme from the scheme selector
2. Select "My Mac" as the build destination
3. Press `Cmd+B` to build
4. Press `Cmd+R` to run

The app will launch and connect to your Python backend at `http://127.0.0.1:8000`.

## Project Structure Overview

```
SimpleCP.xcodeproj/           # Xcode project file
SimpleCP/                     # All Swift source files
├── App/                      # App entry points (3 files)
├── Models/                   # Data models (4 files)
├── Services/                 # API integration (4 files)
├── Views/                    # UI components (16 files)
│   ├── Components/          # Shared components (4 files)
│   ├── History/             # History column (3 files)
│   ├── Snippets/            # Snippets column (4 files)
│   └── Shared/              # Shared views (2 files)
├── Utils/                   # Utilities (3 files)
└── Resources/               # Assets and config (2 files)
SimpleCP.entitlements        # macOS permissions
```

**Total: 27 Swift files**

## Build Requirements

- **macOS:** 14.0 or later (Sonoma)
- **Xcode:** 15.0 or later
- **Swift:** 5.9 or later
- **Backend:** Python FastAPI server running on port 8000

## API Endpoints Used

The Swift app uses these backend endpoints:

### History
- `GET /api/history` - Load clipboard history
- `GET /api/history/folders` - Load auto-folders
- `DELETE /api/history/{id}` - Delete item
- `POST /api/history/clear` - Clear all

### Snippets
- `GET /api/snippets` - Load all snippets
- `POST /api/snippets` - Create snippet
- `PUT /api/snippets/{folder}/{id}` - Update snippet
- `DELETE /api/snippets/{folder}/{id}` - Delete snippet

### Folders
- `POST /api/folders` - Create folder
- `PUT /api/folders/rename` - Rename folder
- `DELETE /api/folders/{name}` - Delete folder

### Operations
- `POST /api/clipboard/copy` - Copy to clipboard
- `GET /api/search?query={q}` - Search
- `GET /api/health` - Health check

## Testing the Integration

### 1. Basic Connectivity Test

Open the app and check the Settings window (gear icon):
- Should show "Status: healthy"
- Should display history count and snippet folder count

### 2. History Column Test

**Test loading:**
- History items should appear in the left column
- Recent items (1-10) should show at the top
- Auto-folders (11-20, 21-30, etc.) should appear below

**Test actions:**
- Hover over an item to see action buttons
- Click "Copy" button to copy to clipboard
- Click "Save" button to open snippet dialog
- Click "Delete" to remove item

### 3. Snippets Column Test

**Test folder management:**
- Click "+" button to create new folder
- Right-click folder to rename or delete
- Click folder to expand/collapse

**Test snippet creation:**
- Select a history item
- Click "Save as Snippet" button
- Fill in snippet name (auto-suggested)
- Select or create folder
- Add tags (optional)
- Click "Save Snippet"
- Verify snippet appears in folder

**Test snippet actions:**
- Hover over snippet to see actions
- Click "Copy" to copy to clipboard
- Click "Delete" to remove snippet

### 4. Search Test

**Test search functionality:**
- Type in search bar at the top
- Results should show in both columns
- Clear search to return to normal view

### 5. Settings Test

**Test settings window:**
- Click gear icon in top right
- Check backend connection status
- Verify health data is accurate

## Troubleshooting

### Backend Connection Failed

**Error:** "Failed to load history" or "Network error"

**Solutions:**
1. Verify backend is running: `curl http://127.0.0.1:8000/api/health`
2. Check backend logs for errors
3. Restart backend with: `python3 -m uvicorn api.main:app --reload`

### Build Errors in Xcode

**Error:** "Missing package dependencies"

**Solution:** The project uses only system frameworks, no external dependencies.

**Error:** "Code signing issues"

**Solution:**
1. Select the project in Xcode
2. Go to Signing & Capabilities
3. Select your development team
4. Or disable code signing for development

### App Crashes on Launch

**Check:**
1. macOS version is 14.0 or later
2. Xcode is version 15.0 or later
3. Check Xcode console for error messages

### Data Not Showing

**Check:**
1. Backend is running and healthy
2. Backend has data (add test data via API)
3. Network permissions in entitlements file
4. Check browser at `http://127.0.0.1:8000/docs` to verify API

## Performance Notes

### First Launch
- Initial data load may take 1-2 seconds
- Loading indicators will show during fetch

### Subsequent Use
- Data refreshes on demand
- Auto-refresh can be triggered with Refresh button
- Search is debounced for performance

## Development Tips

### Hot Reload
- Xcode supports SwiftUI previews for faster iteration
- Press `Cmd+R` to rebuild and restart the app

### Debugging
- Use Xcode's debugger and breakpoints
- Check Console for network errors
- Use Network Inspector to monitor API calls

### Testing API Calls
- Settings window shows connection status
- Each failed API call logs to console
- Use backend's `/docs` endpoint to test API directly

## Next Steps

After verifying the app works:

1. **Visual Polish** - Customize colors, fonts, spacing
2. **Advanced Features** - Add more keyboard shortcuts
3. **Menu Bar** - Enhance native macOS integration
4. **Preferences** - Add user configurable settings
5. **Testing** - Add unit and integration tests

## File Locations

- **Xcode Project:** `/home/user/SimpleCP/SimpleCP.xcodeproj`
- **Swift Source:** `/home/user/SimpleCP/SimpleCP/`
- **Backend API:** `http://127.0.0.1:8000`
- **API Documentation:** `http://127.0.0.1:8000/docs`

## Support

If you encounter issues:

1. Check backend logs for API errors
2. Check Xcode console for Swift errors
3. Verify all endpoints with curl or Postman
4. Review SWIFT_README.md for architecture details

---

**Status:** ✅ Complete and ready for testing
**Last Updated:** 2024-11-17

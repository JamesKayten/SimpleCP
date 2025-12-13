# XC Swift File Refactoring Instructions

## TCC File Size Compliance

The following Swift files exceed the 300-line limit and need refactoring:

| File | Current Lines | Target | Overage |
|------|--------------|--------|---------|
| `RecentClipsColumn.swift` | 998 | 300 | -698 |
| `BackendService.swift` | 730 | 300 | -430 |
| `MenuBarManager.swift` | 516 | 300 | -216 |
| `SettingsViews.swift` | 497 | 300 | -197 |
| `FolderView.swift` | 476 | 300 | -176 |
| `ClipboardManager.swift` | 470 | 300 | -170 |
| `SavedSnippetsColumn.swift` | 435 | 300 | -135 |
| `SaveSnippetWindowManager.swift` | 356 | 300 | -56 |
| `ClipboardManager+Snippets.swift` | 337 | 300 | -37 |

## Refactoring Strategy

### 1. RecentClipsColumn.swift (998 → 300 lines)

**Extract to separate files:**
- `RecentClipsColumn+Views.swift` - Individual clip row views
- `RecentClipsColumn+Actions.swift` - Copy/paste/delete action handlers
- `RecentClipsColumn+Search.swift` - Search filtering logic
- `ClipRowView.swift` - Single clip row component

### 2. BackendService.swift (730 → 300 lines)

**Extract to separate files:**
- `BackendService+History.swift` - History-related API calls
- `BackendService+Snippets.swift` - Snippet CRUD operations
- `BackendService+Folders.swift` - Folder management APIs
- `BackendService+Types.swift` - Response/request type definitions

### 3. MenuBarManager.swift (516 → 300 lines)

**Extract to separate files:**
- `MenuBarManager+Setup.swift` - Menu construction code
- `MenuBarManager+Actions.swift` - Menu action handlers
- `MenuItems.swift` - Custom menu item views

### 4. SettingsViews.swift (497 → 300 lines)

**Extract to separate files:**
- `GeneralSettingsView.swift` - General settings tab
- `ShortcutsSettingsView.swift` - Keyboard shortcuts tab
- `AboutSettingsView.swift` - About/info tab
- `SettingsRow.swift` - Reusable settings row component

### 5. FolderView.swift (476 → 300 lines)

**Extract to separate files:**
- `FolderView+List.swift` - Folder list rendering
- `FolderView+Actions.swift` - Create/rename/delete actions
- `FolderRow.swift` - Single folder row component

### 6. ClipboardManager.swift (470 → 300 lines)

**Extract to separate files:**
- `ClipboardManager+Monitoring.swift` - Clipboard monitoring loop
- `ClipboardManager+State.swift` - State management helpers
- Already has `+Snippets` extension, continue pattern

### 7. SavedSnippetsColumn.swift (435 → 300 lines)

**Extract to separate files:**
- `SavedSnippetsColumn+Views.swift` - Snippet row views
- `SnippetRowView.swift` - Single snippet row component
- `SavedSnippetsColumn+Actions.swift` - Edit/delete handlers

### 8. SaveSnippetWindowManager.swift (356 → 300 lines)

**Extract:**
- `SaveSnippetForm.swift` - Form UI components
- Keep window management in main file

### 9. ClipboardManager+Snippets.swift (337 → 300 lines)

**Consolidate/simplify:**
- Remove verbose comments
- Combine similar methods
- Consider if some logic belongs in `BackendService`

## Refactoring Patterns to Follow

1. **Use Extensions** - Swift extensions (`+Name.swift`) for logical grouping
2. **Extract Views** - Each complex view becomes its own file
3. **Separate Business Logic** - Keep views thin, extract logic to managers
4. **Remove Verbose Comments** - Self-documenting code > lengthy comments
5. **Consolidate Similar Code** - DRY principle for repeated patterns

## Testing After Refactoring

After each file refactoring:
1. Build the project (`Cmd+B`)
2. Run the app to verify functionality
3. Test the specific feature affected

## Python Refactoring Complete

All Python backend files have been refactored to under 250 lines:
- `daemon.py`: 303 → 121 lines
- `monitoring/__init__.py`: 285 → 123 lines
- `api/endpoints.py`: 262 → 164 lines
- `clipboard_manager.py`: 253 → 249 lines
- All test files: under 250 lines

New modules created:
- `backend/utils/process.py` - Port/PID utilities extracted from daemon
- `backend/monitoring/trackers.py` - Performance/usage tracking classes

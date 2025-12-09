# Multi-Copy / Split Paste Feature Implementation Plan

**Priority:** Medium  
**Status:** Proposed  
**Date Created:** December 9, 2025

---

## Overview

Allow users to copy a multi-line list and have each line automatically split into separate clipboard items.

### Use Case
- Copy 50 test samples at once
- Each line becomes its own clip in history
- Useful for bulk importing snippets

---

## Implementation Approach

### Recommended: Context Menu + Import Dialog

Given the existing UI patterns (context menus on clip items, modal dialogs for snippets), the recommended approach combines:
- **Auto-detection** of multi-line content
- **Context menu option** for manual triggering
- **Preview dialog** before confirming the split

**User Flow:**
1. User copies multi-line text normally
2. App detects it's multi-line (automatic detection)
3. Shows a subtle notification/button: "Split into 5 clips?"
4. Or add a menu item: "Import Clipboard as Multiple Clips..."
5. Shows preview dialog with split results before confirming

---

## Backend Implementation

### New Endpoint in `backend/main.py`

```python
from pydantic import BaseModel
from typing import List

class BulkClipsRequest(BaseModel):
    contents: List[str]
    delimiter: str = "\n"  # newline, comma, tab, custom

@app.post("/api/clips/bulk")
async def add_bulk_clips(request: BulkClipsRequest):
    """Add multiple clips at once from split content"""
    clips_added = []
    for content in request.contents:
        stripped = content.strip()
        if stripped:  # Only add non-empty clips
            clip = create_clip(stripped)
            if clip:
                clips_added.append(clip)
    
    return {
        "success": True, 
        "count": len(clips_added), 
        "clips": clips_added
    }
```

**Technical Notes:**
- Endpoint: `POST /api/clips/bulk`
- Accepts array of content strings
- Configurable delimiter (newline, comma, tab, semicolon, custom)
- Returns count of clips created
- Filters out empty lines automatically

---

## Frontend Implementation

### 1. ClipboardManager Extension

Create `ClipboardManager+BulkImport.swift`:

```swift
import Foundation

extension ClipboardManager {
    /// Split clipboard content into multiple clips
    func splitAndAddClips(_ content: String, delimiter: String = "\n") async throws {
        let lines = content.components(separatedBy: delimiter)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { 
            throw BulkImportError.noValidContent
        }
        
        let url = URL(string: "http://localhost:\(backendPort)/api/clips/bulk")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["contents": lines, "delimiter": delimiter]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BulkImportError.serverError
        }
        
        let result = try JSONDecoder().decode(BulkClipsResponse.self, from: data)
        
        // Refresh history to show new clips
        await fetchHistory()
        
        print("✅ Split \(result.count) clips successfully")
    }
    
    /// Check if content is suitable for splitting
    func shouldSuggestSplit(for content: String) -> Bool {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Suggest split if:
        // - At least 5 lines
        // - No more than 100 lines (avoid overwhelming)
        // - Each line is reasonably short (not a paragraph dump)
        return lines.count >= 5 && 
               lines.count <= 100 &&
               lines.allSatisfy { $0.count < 500 }
    }
}

struct BulkClipsResponse: Codable {
    let success: Bool
    let count: Int
}

enum BulkImportError: LocalizedError {
    case noValidContent
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .noValidContent:
            return "No valid content to split"
        case .serverError:
            return "Failed to add clips to history"
        }
    }
}
```

### 2. Split Paste Window Manager

Create `SplitPasteWindowManager.swift`:

```swift
import SwiftUI
import AppKit

@MainActor
class SplitPasteWindowManager: ObservableObject {
    static let shared = SplitPasteWindowManager()
    private var window: NSWindow?
    
    private init() {}
    
    func showDialog(content: String, clipboardManager: ClipboardManager) {
        // Close existing window if any
        closeDialog()
        
        let dialogView = SplitPasteDialog(
            content: content,
            clipboardManager: clipboardManager,
            onConfirm: { delimiter in
                Task {
                    do {
                        try await clipboardManager.splitAndAddClips(content, delimiter: delimiter)
                        self.closeDialog()
                    } catch {
                        print("❌ Failed to split clips: \(error)")
                    }
                }
            },
            onCancel: { 
                self.closeDialog() 
            }
        )
        
        let hostingController = NSHostingController(rootView: dialogView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Split Clipboard into Multiple Clips"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        self.window = window
    }
    
    func closeDialog() {
        window?.close()
        window = nil
    }
}

struct SplitPasteDialog: View {
    let content: String
    let clipboardManager: ClipboardManager
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var delimiter: String = "\n"
    @State private var previewLines: [String] = []
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "scissors")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Split Clipboard into Clips")
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                Spacer()
            }
            
            Divider()
            
            // Delimiter picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Split by:")
                    .font(fontPrefs.interfaceFont(weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $delimiter) {
                    Text("New Line").tag("\n")
                    Text("Comma").tag(",")
                    Text("Tab").tag("\t")
                    Text("Semicolon").tag(";")
                }
                .pickerStyle(.segmented)
                .onChange(of: delimiter) { _ in updatePreview() }
            }
            
            // Preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Preview:")
                        .font(fontPrefs.interfaceFont(weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(previewLines.count) clips")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(previewLines.prefix(20).enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(fontPrefs.clipContentFont())
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .trailing)
                                
                                Text(line)
                                    .font(fontPrefs.clipContentFont())
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        if previewLines.count > 20 {
                            HStack {
                                Text("...")
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .trailing)
                                Text("and \(previewLines.count - 20) more clips")
                                    .foregroundColor(.secondary)
                            }
                            .font(fontPrefs.interfaceFont())
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 250)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
            
            // Warning for large splits
            if previewLines.count > 50 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This will create \(previewLines.count) clips. Consider splitting into smaller batches.")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Empty content warning
            if previewLines.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("No clips would be created with this delimiter.")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Split into \(previewLines.count) Clips") {
                    onConfirm(delimiter)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(previewLines.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 550)
        .onAppear { updatePreview() }
    }
    
    private func updatePreview() {
        previewLines = content.components(separatedBy: delimiter)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    SplitPasteDialog(
        content: "Line 1\nLine 2\nLine 3\nLine 4\nLine 5",
        clipboardManager: ClipboardManager(),
        onConfirm: { _ in },
        onCancel: { }
    )
}
```

### 3. UI Integration in RecentClipsColumn

Add to the header context menu in `RecentClipsColumn.swift` (around line 48):

```swift
.contextMenu {
    Button(action: {
        SaveSnippetWindowManager.shared.showDialog(
            content: clipboardManager.currentClipboard,
            clipboardManager: clipboardManager,
            onDismiss: {}
        )
    }) {
        Label("Save Current Clipboard as Snippet", systemImage: "square.and.arrow.down")
    }
    
    // NEW: Split paste option
    Button(action: {
        SplitPasteWindowManager.shared.showDialog(
            content: clipboardManager.currentClipboard,
            clipboardManager: clipboardManager
        )
    }) {
        Label("Split Clipboard into Multiple Clips...", systemImage: "scissors")
    }
    .disabled(clipboardManager.currentClipboard.isEmpty)
    
    Divider()
    
    Button(action: {
        // Select all clips
        selectedClipIds = Set(recentClips.map { $0.id })
    }) {
        Label("Select All Clips", systemImage: "checkmark.circle")
    }
    
    // ... rest of context menu
}
```

### 4. Optional: Auto-Detection Notification

Add smart detection hint in `ClipboardManager.swift`:

```swift
func handleNewClipboard(_ content: String) {
    // Existing clipboard handling logic...
    
    // Check if we should suggest splitting
    if shouldSuggestSplit(for: content) {
        let lineCount = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        
        // Show notification (could use NSUserNotification or banner in UI)
        print("💡 Hint: This clipboard has \(lineCount) lines. You can split it into separate clips!")
    }
}
```

---

## Implementation Timeline

### Phase 1: Backend & Core Logic (2-3 hours)
- [ ] Add `/api/clips/bulk` endpoint to `backend/main.py`
- [ ] Create `ClipboardManager+BulkImport.swift`
- [ ] Test API endpoint independently

### Phase 2: UI Dialog (3-4 hours)
- [ ] Create `SplitPasteWindowManager.swift`
- [ ] Implement `SplitPasteDialog` with preview
- [ ] Add delimiter selection (newline, comma, tab, semicolon)
- [ ] Test dialog independently

### Phase 3: Integration (1-2 hours)
- [ ] Add menu item to `RecentClipsColumn` context menu
- [ ] Wire up dialog to clipboard manager
- [ ] Test full flow: context menu → dialog → split → history refresh

### Phase 4: Polish & Optional Features (1-2 hours)
- [ ] Add auto-detection with suggestions
- [ ] Add keyboard shortcuts
- [ ] Add analytics/logging
- [ ] Handle edge cases (very large splits, empty lines, etc.)

**Total Estimated Time:** 7-11 hours

---

## Technical Considerations

### Delimiter Options
- **New Line** (`\n`): Most common use case
- **Comma** (`,`): For CSV-like data
- **Tab** (`\t`): For TSV data
- **Semicolon** (`;`): Alternative CSV format
- **Custom** (future): Allow user-defined delimiter

### Edge Cases to Handle
1. **Empty lines**: Filter out automatically
2. **Very long lines**: Warn if any line > 1000 characters
3. **Too many splits**: Warn if > 50 clips will be created
4. **Duplicate content**: Allow duplicates (user might want them)
5. **Special characters**: Preserve as-is, don't strip

### Performance Considerations
- Limit to 100 clips per split to avoid overwhelming the UI
- Use `LazyVStack` in preview for large lists
- Show only first 20 items in preview, indicate "and X more"
- Process splits asynchronously to avoid blocking UI

### User Experience
- **Preview before commit**: Critical for user confidence
- **Clear feedback**: Show exact count of clips that will be created
- **Easy to cancel**: Escape key closes dialog
- **Undo support**: Consider adding bulk delete/undo for recently split clips

---

## Testing Checklist

### Unit Tests
- [ ] Split logic with different delimiters
- [ ] Empty content handling
- [ ] Single-line content (should not split)
- [ ] Special characters in content
- [ ] Very long content

### Integration Tests
- [ ] Backend endpoint receives and processes bulk clips
- [ ] Frontend successfully calls backend
- [ ] History refreshes after split
- [ ] Dialog closes after successful split

### UI Tests
- [ ] Dialog opens from context menu
- [ ] Delimiter picker changes preview
- [ ] Preview updates correctly
- [ ] Cancel button works
- [ ] Confirm button disabled when no clips
- [ ] Keyboard shortcuts work (Escape, Return)

### Edge Case Tests
- [ ] 1,000+ line split (should warn)
- [ ] Empty clipboard (button disabled)
- [ ] Single line (creates 1 clip)
- [ ] All empty lines after trimming
- [ ] Mixed content (some empty, some not)

---

## Future Enhancements

### Advanced Splitting
- **Custom delimiter**: Let user type any delimiter
- **Regex splitting**: Split by regex pattern
- **Smart splitting**: Detect content type (CSV, JSON, code blocks)
- **Trim options**: Checkbox to preserve whitespace vs. trim

### Bulk Operations
- **Split and tag**: Assign tags to all split clips
- **Split and save as snippets**: Create snippet folder from split
- **Split and organize**: Auto-categorize clips

### UI Improvements
- **Drag & drop**: Drop text file to split
- **Import from file**: Browse for text file to split
- **Export format**: Export history as split text

---

## Related Files

- `ClipboardManager.swift` - Main clipboard logic
- `RecentClipsColumn.swift` - Where context menu is added
- `SaveSnippetWindowManager.swift` - Similar modal pattern to follow
- `backend/main.py` - Backend API endpoints
- `ContentView.swift` - Main app view

---

## Status

**Current State:** Documented, ready for implementation  
**Next Step:** Begin Phase 1 - Backend endpoint implementation  
**Blocker:** None  
**Dependencies:** Existing clipboard management system

---

**Last Updated:** December 9, 2025  
**Document Version:** 1.0  
**Author:** Implementation plan based on feature backlog

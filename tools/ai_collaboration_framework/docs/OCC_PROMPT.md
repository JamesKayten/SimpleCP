# OCC Swift Implementation Prompt - SimpleCP Menu Bar App

## Context
You are implementing a macOS menu bar clipboard manager app called SimpleCP using SwiftUI. The project has a detailed UX specification and existing basic Swift files that need to be completely restructured to match the specification.

## Project Location
**Repository**: `/Volumes/User_Smallfavor/Users/Smallfavor/Documents/SimpleCP/`
**Xcode Project**: `/Volumes/User_Smallfavor/Users/Smallfavor/Documents/SimpleCP/SimpleCP-macOS/SimpleCP.xcodeproj`
**UX Specification**: `/Volumes/User_Smallfavor/Users/Smallfavor/Documents/SimpleCP/docs/UI_UX_SPECIFICATION_v3.md`

## Key UX Requirements Summary
- **Window**: 600x400 MenuBarExtra with .window style
- **Layout**: Two-column design (Recent Clips | Saved Snippets)
- **Top Bar**: Combined search/control bar with 🔍 search field + ➕📁📋⚙️ buttons
- **Left Column**: Numbered recent clips (1-10) with quick save [💾] buttons
- **Right Column**: Expandable snippet folders with drag & drop support
- **Core Feature**: Complete "Save as Snippet" workflow with smart name suggestions

## Current State Issues
The existing Swift files are basic templates that need complete restructuring:
- Uses AppDelegate instead of MenuBarExtra
- Single column instead of two-column layout
- Missing search/control bar
- No snippet management system
- No settings implementation

## EVENING IMPLEMENTATION TASKS - Complete Without Stopping

### PHASE 1: Core App Structure (CRITICAL - Do First)

#### Task 1.1: Fix App.swift - Replace AppDelegate with MenuBarExtra
**File**: `SimpleCP/App.swift`
**Action**: REPLACE ENTIRE FILE
```swift
import SwiftUI

@main
struct SimpleCPApp: App {
    var body: some Scene {
        MenuBarExtra("SimpleCP", systemImage: "doc.on.clipboard") {
            ContentView()
                .frame(width: 600, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
```

#### Task 1.2: Rebuild ContentView for Two-Column Layout
**File**: `SimpleCP/ContentView.swift`
**Action**: REPLACE ENTIRE FILE
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Combined Search/Control Bar
            SearchControlBar(searchText: $searchText)
                .environmentObject(clipboardManager)

            Divider()

            // Two-Column Content
            HStack(spacing: 0) {
                RecentClipsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity)
                    .environmentObject(clipboardManager)

                Divider()

                SavedSnippetsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity)
                    .environmentObject(clipboardManager)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
}
```

### PHASE 2: Create Essential View Components

#### Task 2.1: Create SearchControlBar Component
**File**: `SimpleCP/Views/SearchControlBar.swift` (NEW FILE)
```swift
import SwiftUI

struct SearchControlBar: View {
    @Binding var searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showingSettings = false
    @State private var showingSaveDialog = false

    var body: some View {
        HStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clips and snippets...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            // Compact control buttons
            Button(action: { showingSaveDialog.toggle() }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Create new snippet")

            Button(action: manageFolders) {
                Image(systemName: "folder")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Manage folders")

            Button(action: clearHistory) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Clear history")

            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Settings")
        }
        .padding(12)
        .sheet(isPresented: $showingSettings) {
            SettingsWindow()
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveSnippetDialog(content: NSPasteboard.general.string(forType: .string) ?? "")
        }
    }

    private func manageFolders() {
        // TODO: Implement folder management
        print("Manage folders tapped")
    }

    private func clearHistory() {
        clipboardManager.clearAll()
    }
}
```

#### Task 2.2: Create RecentClipsColumn Component
**File**: `SimpleCP/Views/RecentClipsColumn.swift` (NEW FILE)
```swift
import SwiftUI

struct RecentClipsColumn: View {
    let searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var hoveredItem: UUID?

    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(clipboardManager.items.prefix(10))
        } else {
            return clipboardManager.items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText)
            }.prefix(10).map { $0 }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Text("📋 RECENT CLIPS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Recent clips list
            if filteredItems.isEmpty {
                VStack {
                    Image(systemName: "clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard items yet" : "No items match your search")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                            RecentClipRow(
                                item: item,
                                index: index + 1,
                                isHovered: hoveredItem == item.id
                            )
                            .onHover { hovering in
                                hoveredItem = hovering ? item.id : nil
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // History folder groups for 11-50
            if clipboardManager.items.count > 10 {
                Divider()
                VStack(spacing: 2) {
                    ForEach(1..<5) { group in
                        let startIndex = group * 10 + 1
                        let endIndex = (group + 1) * 10
                        let itemCount = max(0, min(clipboardManager.items.count - startIndex + 1, 10))

                        if itemCount > 0 {
                            HistoryGroupRow(
                                startIndex: startIndex,
                                endIndex: endIndex,
                                itemCount: itemCount
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
}

struct RecentClipRow: View {
    let item: ClipboardItem
    let index: Int
    let isHovered: Bool
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showingSaveDialog = false

    var body: some View {
        HStack {
            // Index number
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                // Content preview
                Text(item.content)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Timestamp
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Quick save button (show on hover)
            if isHovered {
                Button(action: { showingSaveDialog.toggle() }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Save as snippet")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            clipboardManager.copyToClipboard(item.content)
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveSnippetDialog(content: item.content)
        }
    }
}

struct HistoryGroupRow: View {
    let startIndex: Int
    let endIndex: Int
    let itemCount: Int

    var body: some View {
        HStack {
            Text("📁 \(startIndex) - \(endIndex)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("(\(itemCount) items)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .onTapGesture {
            // TODO: Expand to show items in this range
            print("Tapped history group \(startIndex)-\(endIndex)")
        }
    }
}
```

#### Task 2.3: Create SavedSnippetsColumn Component
**File**: `SimpleCP/Views/SavedSnippetsColumn.swift` (NEW FILE)
```swift
import SwiftUI

struct SavedSnippetsColumn: View {
    let searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Text("📁 SAVED SNIPPETS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Snippet folders
            if clipboardManager.snippetFolders.isEmpty {
                VStack {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No snippet folders yet")
                        .foregroundColor(.secondary)
                    Text("Click ➕ to create your first folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(clipboardManager.snippetFolders) { folder in
                            SnippetFolderView(folder: folder, searchText: searchText)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct SnippetFolderView: View {
    @ObservedObject var folder: SnippetFolder
    let searchText: String
    @EnvironmentObject var clipboardManager: ClipboardManager

    private var filteredSnippets: [SavedSnippet] {
        if searchText.isEmpty {
            return folder.snippets
        } else {
            return folder.snippets.filter { snippet in
                snippet.name.localizedCaseInsensitiveContains(searchText) ||
                snippet.content.localizedCaseInsensitiveContains(searchText) ||
                snippet.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Folder header
            HStack {
                Button(action: { folder.isExpanded.toggle() }) {
                    HStack {
                        Text(folder.icon)
                        Text(folder.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(folder.isExpanded ? "▼" : "▲")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                if !folder.isExpanded {
                    Text("(\(folder.snippets.count) snippets)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            // Expanded folder contents
            if folder.isExpanded {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredSnippets) { snippet in
                        SnippetRow(snippet: snippet)
                    }

                    // Quick add area
                    HStack {
                        Text("➕ Add snippet here...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .onTapGesture {
                        // TODO: Quick add current clipboard to this folder
                        print("Quick add to folder \(folder.name)")
                    }
                }
            }
        }
    }
}

struct SnippetRow: View {
    let snippet: SavedSnippet
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        HStack {
            Text("├── \(snippet.name)")
                .font(.caption)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
        .onTapGesture {
            clipboardManager.copyToClipboard(snippet.content)
        }
        .contextMenu {
            Button("Copy to Clipboard") {
                clipboardManager.copyToClipboard(snippet.content)
            }
            Button("Edit...") {
                // TODO: Edit snippet
            }
            Button("Delete") {
                // TODO: Delete snippet
            }
        }
    }
}
```

### PHASE 3: Update ClipboardManager for Snippet Support

#### Task 3.1: Add Snippet Models and Methods to ClipboardManager
**File**: `SimpleCP/ClipboardManager.swift`
**Action**: ADD these structures and methods to the existing class

```swift
// ADD these structures before the ClipboardManager class
struct SnippetFolder: Identifiable, ObservableObject {
    let id = UUID()
    @Published var name: String
    @Published var icon: String
    @Published var snippets: [SavedSnippet]
    @Published var isExpanded: Bool = true

    init(name: String, icon: String = "📁") {
        self.name = name
        self.icon = icon
        self.snippets = []
    }
}

struct SavedSnippet: Identifiable, Codable {
    let id = UUID()
    var name: String
    var content: String
    var tags: [String]
    var folderID: UUID
    var createdAt: Date

    init(name: String, content: String, tags: [String] = [], folderID: UUID) {
        self.name = name
        self.content = content
        self.tags = tags
        self.folderID = folderID
        self.createdAt = Date()
    }
}

// ADD to the ClipboardManager class:
@Published var snippetFolders: [SnippetFolder] = []

init() {
    startMonitoring()
    loadItems()
    loadSnippetFolders()
    createDefaultFolders()
}

// MARK: - Snippet Management Methods
func createFolder(name: String, icon: String = "📁") -> SnippetFolder {
    let folder = SnippetFolder(name: name, icon: icon)
    DispatchQueue.main.async {
        self.snippetFolders.append(folder)
        self.saveSnippetFolders()
    }
    return folder
}

func saveAsSnippet(content: String, name: String, folderID: UUID, tags: [String] = []) {
    guard let folderIndex = snippetFolders.firstIndex(where: { $0.id == folderID }) else { return }

    let snippet = SavedSnippet(name: name, content: content, tags: tags, folderID: folderID)

    DispatchQueue.main.async {
        self.snippetFolders[folderIndex].snippets.append(snippet)
        self.saveSnippetFolders()
    }

    // Send to API
    Task {
        await apiService.saveSnippet(snippet, folderName: snippetFolders[folderIndex].name)
    }
}

func deleteFolder(id: UUID) {
    DispatchQueue.main.async {
        self.snippetFolders.removeAll { $0.id == id }
        self.saveSnippetFolders()
    }
}

func deleteSnippet(snippetID: UUID) {
    DispatchQueue.main.async {
        for folderIndex in self.snippetFolders.indices {
            self.snippetFolders[folderIndex].snippets.removeAll { $0.id == snippetID }
        }
        self.saveSnippetFolders()
    }
}

// MARK: - Persistence
private func saveSnippetFolders() {
    // Convert folders to saveable format (avoid @Published properties)
    let saveableFolders = snippetFolders.map { folder in
        [
            "id": folder.id.uuidString,
            "name": folder.name,
            "icon": folder.icon,
            "isExpanded": folder.isExpanded,
            "snippets": folder.snippets.map { snippet in
                [
                    "id": snippet.id.uuidString,
                    "name": snippet.name,
                    "content": snippet.content,
                    "tags": snippet.tags,
                    "folderID": snippet.folderID.uuidString,
                    "createdAt": snippet.createdAt.timeIntervalSince1970
                ]
            }
        ]
    }

    if let data = try? JSONSerialization.data(withJSONObject: saveableFolders) {
        UserDefaults.standard.set(data, forKey: "snippet_folders")
    }
}

private func loadSnippetFolders() {
    guard let data = UserDefaults.standard.data(forKey: "snippet_folders"),
          let foldersData = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

    DispatchQueue.main.async {
        self.snippetFolders = foldersData.compactMap { folderData in
            guard let idString = folderData["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = folderData["name"] as? String,
                  let icon = folderData["icon"] as? String,
                  let isExpanded = folderData["isExpanded"] as? Bool,
                  let snippetsData = folderData["snippets"] as? [[String: Any]] else { return nil }

            let folder = SnippetFolder(name: name, icon: icon)
            folder.isExpanded = isExpanded

            folder.snippets = snippetsData.compactMap { snippetData in
                guard let idString = snippetData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = snippetData["name"] as? String,
                      let content = snippetData["content"] as? String,
                      let tags = snippetData["tags"] as? [String],
                      let folderIDString = snippetData["folderID"] as? String,
                      let folderID = UUID(uuidString: folderIDString),
                      let createdAtInterval = snippetData["createdAt"] as? TimeInterval else { return nil }

                var snippet = SavedSnippet(name: name, content: content, tags: tags, folderID: folderID)
                snippet.id = id
                snippet.createdAt = Date(timeIntervalSince1970: createdAtInterval)
                return snippet
            }

            return folder
        }
    }
}

private func createDefaultFolders() {
    guard snippetFolders.isEmpty else { return }

    let defaultFolders = [
        ("Email Templates", "📧"),
        ("Code Snippets", "💻"),
        ("Common Text", "📝")
    ]

    for (name, icon) in defaultFolders {
        _ = createFolder(name: name, icon: icon)
    }
}
```

### PHASE 4: Create Save Snippet Dialog

#### Task 4.1: Create Save Snippet Dialog
**File**: `SimpleCP/Views/SaveSnippetDialog.swift` (NEW FILE)
```swift
import SwiftUI

struct SaveSnippetDialog: View {
    let content: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var clipboardManager: ClipboardManager

    @State private var snippetName: String = ""
    @State private var selectedFolder: SnippetFolder?
    @State private var createNewFolder = false
    @State private var newFolderName = ""
    @State private var newFolderIcon = "📁"
    @State private var tags = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Save as Snippet")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("✕") { dismiss() }
                    .buttonStyle(PlainButtonStyle())
            }

            // Content Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Content Preview:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ScrollView {
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .frame(height: 80)
            }

            // Snippet Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Snippet Name:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter snippet name...", text: $snippetName)
                    .textFieldStyle(.roundedBorder)
            }

            // Folder Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Save to Folder:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if createNewFolder {
                    HStack {
                        TextField("Folder icon", text: $newFolderIcon)
                            .frame(width: 40)
                        TextField("New folder name", text: $newFolderName)
                        Button("Cancel") {
                            createNewFolder = false
                            newFolderName = ""
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        Picker("Folder", selection: $selectedFolder) {
                            ForEach(clipboardManager.snippetFolders, id: \.id) { folder in
                                Text("\(folder.icon) \(folder.name)")
                                    .tag(folder as SnippetFolder?)
                            }
                        }
                        .pickerStyle(.menu)

                        Button("New Folder") {
                            createNewFolder = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Toggle("Create new folder", isOn: $createNewFolder)
                    .controlSize(.small)
            }

            // Tags
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (optional):")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("#email #template #meeting", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }

            // Buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save Snippet") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .disabled(snippetName.isEmpty || (selectedFolder == nil && !createNewFolder))
            }
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .onAppear {
            setupDefaults()
        }
    }

    private func setupDefaults() {
        // Auto-suggest snippet name based on content
        snippetName = generateSnippetName(from: content)

        // Select first folder by default
        selectedFolder = clipboardManager.snippetFolders.first
    }

    private func generateSnippetName(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first ?? ""

        // Extract meaningful name from first line
        if firstLine.count > 3 && firstLine.count < 50 {
            return firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback to content type detection
        if content.contains("@") && content.contains(".com") {
            return "Email Template"
        } else if content.contains("def ") || content.contains("function ") {
            return "Code Snippet"
        } else if content.hasPrefix("http") {
            return "URL Link"
        } else {
            return "Text Snippet"
        }
    }

    private func saveSnippet() {
        let targetFolder: SnippetFolder

        if createNewFolder {
            targetFolder = clipboardManager.createFolder(name: newFolderName, icon: newFolderIcon)
        } else {
            guard let folder = selectedFolder else { return }
            targetFolder = folder
        }

        let tagList = tags.components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }

        clipboardManager.saveAsSnippet(
            content: content,
            name: snippetName,
            folderID: targetFolder.id,
            tags: tagList
        )

        dismiss()
    }
}
```

### PHASE 5: Create Settings Window

#### Task 5.1: Create Settings Window
**File**: `SimpleCP/Views/SettingsWindow.swift` (NEW FILE)
```swift
import SwiftUI

struct SettingsWindow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SimpleCP Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("✕") { dismiss() }
                    .buttonStyle(PlainButtonStyle())
            }
            .padding()

            Divider()

            // Tab Selection
            HStack(spacing: 20) {
                ForEach(Array(["🔧 General", "🎨 Appearance", "📋 Clips", "📁 Snippets"].enumerated()), id: \.offset) { index, title in
                    Button(title) {
                        selectedTab = index
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                    .fontWeight(selectedTab == index ? .semibold : .regular)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    GeneralSettingsTab()
                case 1:
                    AppearanceSettingsTab()
                case 2:
                    ClipsSettingsTab()
                case 3:
                    SnippetsSettingsTab()
                default:
                    GeneralSettingsTab()
                }
            }
            .padding()

            Spacer()

            // Footer Buttons
            HStack {
                Button("Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }

    private func resetToDefaults() {
        // TODO: Reset all settings to defaults
        print("Reset to defaults")
    }

    private func saveSettings() {
        // TODO: Save settings
        print("Settings saved")
    }
}

struct GeneralSettingsTab: View {
    @State private var launchAtLogin = true
    @State private var startMinimized = false
    @State private var windowPosition = 0 // 0: Center, 1: Remember
    @State private var windowSize = 1 // 0: Compact, 1: Normal, 2: Large

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GENERAL SETTINGS")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Startup:")
                    .fontWeight(.medium)

                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Start minimized", isOn: $startMinimized)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Window:")
                    .fontWeight(.medium)

                HStack {
                    Text("Position:")
                    Picker("Position", selection: $windowPosition) {
                        Text("Center").tag(0)
                        Text("Remember").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Size:")
                    Picker("Size", selection: $windowSize) {
                        Text("Compact").tag(0)
                        Text("Normal").tag(1)
                        Text("Large").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcuts:")
                    .fontWeight(.medium)

                HStack {
                    Text("Open SimpleCP:")
                    TextField("⌘⌥V", text: .constant("⌘⌥V"))
                        .frame(width: 100)
                        .disabled(true)
                    Button("Set") {
                        // TODO: Set shortcut
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    Text("Quick search:")
                    TextField("⌘⌥F", text: .constant("⌘⌥F"))
                        .frame(width: 100)
                        .disabled(true)
                    Button("Set") {
                        // TODO: Set shortcut
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppearanceSettingsTab: View {
    @State private var theme = 0 // 0: Auto, 1: Light, 2: Dark
    @State private var windowOpacity = 0.9
    @State private var showFolderIcons = true
    @State private var animateFolders = true
    @State private var showSnippetPreviews = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("APPEARANCE SETTINGS")
                .font(.headline)

            HStack {
                Text("Theme:")
                Picker("Theme", selection: $theme) {
                    Text("Auto").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                Spacer()
            }

            HStack {
                Text("Window opacity:")
                Slider(value: $windowOpacity, in: 0.5...1.0, step: 0.1)
                Text("\(Int(windowOpacity * 100))%")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Interface:")
                    .fontWeight(.medium)

                Toggle("Show folder icons", isOn: $showFolderIcons)
                Toggle("Animate folder expand/collapse", isOn: $animateFolders)
                Toggle("Show snippet previews on hover", isOn: $showSnippetPreviews)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClipsSettingsTab: View {
    @State private var maxHistory = 100
    @State private var autoCategories = true
    @State private var ignorePasswords = true
    @State private var ignoreImages = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CLIPBOARD SETTINGS")
                .font(.headline)

            HStack {
                Text("Maximum history items:")
                TextField("100", value: $maxHistory, format: .number)
                    .frame(width: 60)
                Stepper("", value: $maxHistory, in: 10...1000, step: 10)
                    .labelsHidden()
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Automatic Features:")
                    .fontWeight(.medium)

                Toggle("Auto-categorize clips", isOn: $autoCategories)
                Toggle("Ignore password fields", isOn: $ignorePasswords)
                Toggle("Ignore image content", isOn: $ignoreImages)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SnippetsSettingsTab: View {
    @State private var autoNameSuggestions = true
    @State private var defaultFolder = 0
    @State private var tagSuggestions = true
    @State private var folderSync = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SNIPPET SETTINGS")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Features:")
                    .fontWeight(.medium)

                Toggle("Auto-suggest snippet names", isOn: $autoNameSuggestions)
                Toggle("Auto-suggest tags", isOn: $tagSuggestions)
            }

            HStack {
                Text("Default folder for new snippets:")
                Picker("Default Folder", selection: $defaultFolder) {
                    Text("Ask each time").tag(0)
                    Text("Common Text").tag(1)
                    Text("Last used").tag(2)
                }
                .pickerStyle(.menu)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sync & Backup:")
                    .fontWeight(.medium)

                Toggle("Sync folders across devices", isOn: $folderSync)
                    .disabled(true) // TODO: Implement sync

                HStack {
                    Button("Export Snippets...") {
                        // TODO: Export functionality
                    }
                    .buttonStyle(.bordered)

                    Button("Import Snippets...") {
                        // TODO: Import functionality
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

### PHASE 6: Update Project Structure

#### Task 6.1: Create Views Directory Structure
Create these directories in the Xcode project:
```
SimpleCP/Views/
SimpleCP/Services/ (move existing files here)
SimpleCP/Models/ (create for future model files)
```

#### Task 6.2: Update Xcode Project File References
Add all the new Swift files to the Xcode project:
- Views/SearchControlBar.swift
- Views/RecentClipsColumn.swift
- Views/SavedSnippetsColumn.swift
- Views/SaveSnippetDialog.swift
- Views/SettingsWindow.swift

### PHASE 7: Test and Build

#### Task 7.1: Build and Test the Application
1. Build the project in Xcode
2. Fix any compilation errors
3. Test the basic functionality:
   - Menu bar icon appears
   - Window opens with correct size (600x400)
   - Two-column layout displays
   - Search bar and buttons appear
   - Settings dialog can open

#### Task 7.2: Create Test Snippet Folders
Add code to create some sample snippet folders and snippets for testing the UI.

---

## COMPLETION CRITERIA

You should complete ALL of these phases this evening without stopping. The goal is to have a fully functional menu bar app that:

✅ Uses MenuBarExtra with proper window size
✅ Shows two-column layout with search/control bar
✅ Has working snippet folder management
✅ Can save new snippets with the dialog workflow
✅ Has a complete settings window with all tabs
✅ Builds and runs without errors

## RESOURCES

- **UX Specification**: Read the full details in `UI_UX_SPECIFICATION_v3.md`
- **Existing Backend**: Keep compatibility with existing Python API endpoints
- **Current Swift Files**: Can be completely replaced - they're just basic templates

## NOTES

- Focus on functionality over visual polish initially
- Make sure MenuBarExtra works correctly - this is critical
- The snippet management system is the core feature that differentiates this app
- Test frequently as you build each component
- Use placeholder implementations for complex features like drag & drop initially

## START WITH PHASE 1 IMMEDIATELY

Begin with fixing the App.swift file to use MenuBarExtra, then rebuild ContentView, then proceed through all phases systematically. Do not stop until all phases are complete.
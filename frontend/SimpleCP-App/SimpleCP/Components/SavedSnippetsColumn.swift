//
//  SavedSnippetsColumn.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct SavedSnippetsColumn: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    @Binding var selectedFolderId: UUID?

    @State private var hoveredSnippetId: UUID?
    @State private var editingSnippetId: UUID?
    @Environment(\.fontPreferences) private var fontPrefs

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return clipboardManager.snippets
        }
        // Filter snippets based on search text
        return clipboardManager.snippets.filter { snippet in
            snippet.name.localizedCaseInsensitiveContains(searchText) ||
            snippet.content.localizedCaseInsensitiveContains(searchText) ||
            snippet.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var sortedFolders: [SnippetFolder] {
        clipboardManager.folders.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.secondary)
                Text("SNIPPETS")
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .contextMenu {
                Button(action: {
                    createAutoNamedFolder()
                }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                
                Divider()
                
                Button(action: {
                    exportSnippets()
                }) {
                    Label("Export All Snippets...", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    importSnippets()
                }) {
                    Label("Import Snippets...", systemImage: "square.and.arrow.down")
                }
                
                Divider()
                
                Button(action: {
                    deleteEmptyFolders()
                }) {
                    Label("Delete Empty Folders", systemImage: "trash")
                }
                
                Divider()
                
                Text("\(clipboardManager.snippets.count) snippets in \(clipboardManager.folders.count) folders")
                    .foregroundColor(.secondary)
            }

            Divider()

            // Folders List - Optimized for mouse wheel scrolling
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedFolders) { folder in
                        let folderSnippets = getSnippets(for: folder.id)
                        // Show folder if it has snippets OR if not searching (show empty folders when not searching)
                        if !folderSnippets.isEmpty || searchText.isEmpty {
                            FolderView(
                                folder: folder,
                                snippets: folderSnippets,
                                searchText: searchText,
                                isSelected: selectedFolderId == folder.id,
                                hoveredSnippetId: $hoveredSnippetId,
                                editingSnippetId: $editingSnippetId,
                                onSelect: {
                                    selectedFolderId = folder.id
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func getSnippets(for folderId: UUID) -> [Snippet] {
        let folderSnippets = clipboardManager.getSnippets(for: folderId)
        if searchText.isEmpty {
            return folderSnippets
        }
        return folderSnippets.filter { snippet in
            filteredSnippets.contains(where: { $0.id == snippet.id })
        }
    }
    
    // MARK: - Folder Management Functions
    
    private func createAutoNamedFolder() {
        // Generate a unique folder name
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"

        // Find the next available folder name
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }

        // Create the folder immediately without any dialog
        _ = clipboardManager.createFolder(name: proposedName)
        print("✅ Auto-created folder: \(proposedName)")
    }
    
    private func deleteEmptyFolders() {
        let emptyFolders = clipboardManager.folders.filter { folder in
            clipboardManager.getSnippets(for: folder.id).isEmpty
        }
        
        if emptyFolders.isEmpty {
            let alert = NSAlert()
            alert.messageText = "No Empty Folders"
            alert.informativeText = "There are no empty folders to delete."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Delete Empty Folders"
        alert.informativeText = "Are you sure you want to delete \(emptyFolders.count) empty folder(s)?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            for folder in emptyFolders {
                clipboardManager.deleteFolder(folder)
            }
            print("✅ Deleted \(emptyFolders.count) empty folder(s)")
        }
    }
    
    // MARK: - Export/Import Functions
    
    private func exportSnippets() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SimpleCP-Snippets-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        panel.message = "Export all snippets and folders to a JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            let data = ExportData(
                snippets: clipboardManager.snippets,
                folders: clipboardManager.folders
            )

            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let encoded = try encoder.encode(data)
                try encoded.write(to: url)
                print("✅ Exported \(clipboardManager.snippets.count) snippets to \(url.lastPathComponent)")
            } catch {
                print("❌ Export failed: \(error.localizedDescription)")
                showExportError(error)
            }
        }
    }
    
    private func importSnippets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Import snippets and folders from a JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(ExportData.self, from: data)
                
                var foldersAdded = 0
                var snippetsAdded = 0
                
                // Merge imported folders
                for folder in decoded.folders {
                    if !clipboardManager.folders.contains(where: { $0.id == folder.id }) {
                        clipboardManager.folders.append(folder)
                        foldersAdded += 1
                    }
                }
                
                // Merge imported snippets
                for snippet in decoded.snippets {
                    if !clipboardManager.snippets.contains(where: { $0.id == snippet.id }) {
                        clipboardManager.snippets.append(snippet)
                        snippetsAdded += 1
                    }
                }
                
                print("✅ Imported \(snippetsAdded) snippets and \(foldersAdded) folders")
                showImportSuccess(snippetsAdded: snippetsAdded, foldersAdded: foldersAdded)
            } catch {
                print("❌ Import failed: \(error.localizedDescription)")
                showImportError(error)
            }
        }
    }
    
    private func showExportError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Export Failed"
        alert.informativeText = "Could not export snippets: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showImportError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Import Failed"
        alert.informativeText = "Could not import snippets: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showImportSuccess(snippetsAdded: Int, foldersAdded: Int) {
        let alert = NSAlert()
        alert.messageText = "Import Successful"
        alert.informativeText = "Added \(snippetsAdded) snippets and \(foldersAdded) folders"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Snippet Item Row

struct SnippetItemRow: View {
    let snippet: Snippet
    let isHovered: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showPopover = false
    @State private var hoverTimer: Timer?
    @State private var localHover = false
    @Environment(\.fontPreferences) private var fontPrefs
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false

    var body: some View {
        HStack(spacing: 8) {
            // Favorite indicator
            if snippet.isFavorite {
                Image(systemName: "star.fill")
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.yellow)
                    .fixedSize()
            }

            // Snippet name
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(fontPrefs.clipContentFont())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !snippet.tags.isEmpty {
                    Text(snippet.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // Actions (shown on hover)
            if isHovered || localHover {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(fontPrefs.interfaceFont())
                    }
                    .buttonStyle(.plain)
                    .help("Edit")
                }
                .foregroundColor(.secondary)
                .fixedSize()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill((isHovered || localHover) ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder((isHovered || localHover) ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            SnippetContentPopover(snippet: snippet)
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(_):
                localHover = true
                // Show popover after a delay if enabled
                if showSnippetPreviews {
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        showPopover = true
                    }
                }
            case .ended:
                localHover = false
                // Cancel timer and hide popover
                hoverTimer?.invalidate()
                hoverTimer = nil
                showPopover = false
            }
        }
    }
}

// MARK: - Snippet Content Popover

struct SnippetContentPopover: View {
    let snippet: Snippet
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                if snippet.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(fontPrefs.interfaceFont())
                }
                Text(snippet.name)
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(snippet.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
            }
            
            // Tags
            if !snippet.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(snippet.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(fontPrefs.interfaceFont())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            // Full content
            ScrollView {
                Text(snippet.content)
                    .font(fontPrefs.clipContentFont())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 400, maxHeight: 300)
            
            // Footer with character count
            HStack {
                Text("\(snippet.content.count) characters")
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
                Spacer()
                if snippet.content.components(separatedBy: .newlines).count > 1 {
                    Text("\(snippet.content.components(separatedBy: .newlines).count) lines")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 300)
    }
}

// MARK: - Preview

#Preview {
    SavedSnippetsColumn(searchText: "", selectedFolderId: .constant(nil))
        .environmentObject(ClipboardManager())
        .frame(width: 300, height: 400)
}

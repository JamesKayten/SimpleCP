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

    @State private var hoveredSnippetId: UUID?
    @State private var editingSnippetId: UUID?
    @State private var editingSnippet: Snippet?
    @State private var renamingFolder: SnippetFolder?

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return clipboardManager.snippets
        }
        let (_, snippets) = clipboardManager.search(query: searchText)
        return snippets
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
                Text("SAVED SNIPPETS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()

                // New Folder Button
                Button(action: {
                    createAutoNamedFolder()
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Create New Folder")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Folders List - Optimized for mouse wheel scrolling
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedFolders) { folder in
                        FolderView(
                            folder: folder,
                            snippets: getSnippets(for: folder.id),
                            searchText: searchText,
                            hoveredSnippetId: $hoveredSnippetId,
                            editingSnippetId: $editingSnippetId,
                            editingSnippet: $editingSnippet,
                            renamingFolder: $renamingFolder
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .focusable()
        }
        .sheet(item: $editingSnippet) { snippet in
            EditSnippetDialog(snippet: snippet)
                .environmentObject(clipboardManager)
        }
        .sheet(item: $renamingFolder) { folder in
            RenameFolderDialog(folder: folder, newName: .constant(""))
                .environmentObject(clipboardManager)
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

    private func createAutoNamedFolder() {
        // Generate a unique folder name
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"

        // Find the next available folder name
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }

        // Create the folder immediately - it will appear at the top
        clipboardManager.createFolder(name: proposedName, icon: "📁", order: 0)
        print("✅ Created folder: \(proposedName)")
    }
}

// MARK: - Folder View

struct FolderView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let folder: SnippetFolder
    let snippets: [Snippet]
    let searchText: String

    @Binding var hoveredSnippetId: UUID?
    @Binding var editingSnippetId: UUID?
    @Binding var editingSnippet: Snippet?
    @Binding var renamingFolder: SnippetFolder?

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder Header
            HStack(spacing: 6) {
                Text(folder.icon)
                    .font(.system(size: 14))

                Text(folder.name)
                    .font(.system(size: 12, weight: .medium))

                Spacer()

                // Expand/Collapse indicator
                Image(systemName: folder.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                if !folder.isExpanded {
                    Text("(\(snippets.count))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                clipboardManager.toggleFolderExpansion(folder.id)
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .contextMenu {
                Button("Rename Folder...") {
                    renamingFolder = folder
                }
                Button("Change Icon...") {
                    changeIcon()
                }
                Divider()
                Button("Delete Folder") {
                    deleteFolder()
                }
            }

            // Snippets in folder (when expanded)
            if folder.isExpanded {
                ForEach(snippets) { snippet in
                    SnippetItemRow(
                        snippet: snippet,
                        isHovered: hoveredSnippetId == snippet.id,
                        onCopy: {
                            clipboardManager.copyToClipboard(snippet.content)
                        },
                        onEdit: {
                            editingSnippet = snippet
                        },
                        onDelete: {
                            clipboardManager.deleteSnippet(snippet)
                        }
                    )
                    .onHover { isHovered in
                        hoveredSnippetId = isHovered ? snippet.id : nil
                    }
                    .contextMenu {
                        Button("Copy to Clipboard") {
                            clipboardManager.copyToClipboard(snippet.content)
                        }
                        Button("Edit...") {
                            editingSnippet = snippet
                        }
                        Button("Duplicate") {
                            duplicateSnippet(snippet)
                        }
                        Divider()
                        Button("Delete") {
                            clipboardManager.deleteSnippet(snippet)
                        }
                    }
                }

                // Quick add snippet divider
                if !snippets.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }

                // Quick add button
                Button(action: {
                    addSnippetToFolder()
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.secondary)
                        Text("Add snippet here...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }


    private func changeIcon() {
        let alert = NSAlert()
        alert.messageText = "Change Folder Icon"
        alert.informativeText = "Enter a new icon (emoji) for '\(folder.name)':"
        alert.addButton(withTitle: "Change")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = folder.icon
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let newIcon = textField.stringValue
            if !newIcon.isEmpty {
                var updatedFolder = folder
                updatedFolder.changeIcon(to: newIcon)
                clipboardManager.updateFolder(updatedFolder)
            }
        }
    }

    private func deleteFolder() {
        let alert = NSAlert()
        alert.messageText = "Delete Folder"
        alert.informativeText = "Are you sure you want to delete '\(folder.name)' and all its snippets?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            clipboardManager.deleteFolder(folder)
        }
    }

    private func addSnippetToFolder() {
        let content = clipboardManager.currentClipboard
        let suggestedName = clipboardManager.suggestSnippetName(for: content)
        clipboardManager.saveAsSnippet(name: suggestedName, content: content, folderId: folder.id)
    }

    private func duplicateSnippet(_ snippet: Snippet) {
        var newSnippet = snippet
        newSnippet = Snippet(
            name: snippet.name + " (Copy)",
            content: snippet.content,
            tags: snippet.tags,
            folderId: snippet.folderId
        )
        clipboardManager.saveAsSnippet(
            name: newSnippet.name,
            content: newSnippet.content,
            folderId: newSnippet.folderId,
            tags: newSnippet.tags
        )
    }
}

// MARK: - Snippet Item Row

struct SnippetItemRow: View {
    let snippet: Snippet
    let isHovered: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Favorite indicator
            if snippet.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            }

            // Snippet name
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                if !snippet.tags.isEmpty {
                    Text(snippet.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions (shown on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Edit")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
    }
}

// MARK: - Edit Snippet Dialog

struct EditSnippetDialog: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.dismiss) private var dismiss

    @State private var snippet: Snippet
    @State private var editedName: String
    @State private var editedContent: String
    @State private var editedTags: String

    init(snippet: Snippet) {
        _snippet = State(initialValue: snippet)
        _editedName = State(initialValue: snippet.name)
        _editedContent = State(initialValue: snippet.content)
        _editedTags = State(initialValue: snippet.tags.joined(separator: ", "))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Snippet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name:")
                    .font(.subheadline)
                TextField("Snippet name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content:")
                    .font(.subheadline)
                TextEditor(text: $editedContent)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (comma-separated):")
                    .font(.subheadline)
                TextField("tag1, tag2, tag3", text: $editedTags)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func saveChanges() {
        var updatedSnippet = snippet
        updatedSnippet.name = editedName
        updatedSnippet.update(content: editedContent)
        updatedSnippet.tags = editedTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        clipboardManager.updateSnippet(updatedSnippet)
        dismiss()
    }
}

// MARK: - Rename Folder Dialog

struct RenameFolderDialog: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.dismiss) private var dismiss

    let folder: SnippetFolder
    @State private var newName: String

    init(folder: SnippetFolder, newName: Binding<String>) {
        self.folder = folder
        self._newName = State(initialValue: folder.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Folder")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("New name for '\(folder.name)':")
                    .font(.subheadline)
                TextField("Folder name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        // Pre-select the text for easy editing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let window = NSApplication.shared.keyWindow,
                               let textField = window.firstResponder as? NSTextField {
                                textField.selectText(nil)
                            }
                        }
                    }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    renameFolder()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func renameFolder() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var updatedFolder = folder
        updatedFolder.rename(to: trimmedName)
        clipboardManager.updateFolder(updatedFolder)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SavedSnippetsColumn(searchText: "")
        .environmentObject(ClipboardManager())
        .frame(width: 300, height: 400)
}

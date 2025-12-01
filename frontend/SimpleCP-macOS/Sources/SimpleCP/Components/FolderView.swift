//
//  FolderView.swift
//  SimpleCP
//
//  Folder view component for SavedSnippetsColumn
//

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let folder: SnippetFolder
    let snippets: [Snippet]
    let searchText: String
    let isSelected: Bool

    @Binding var hoveredSnippetId: UUID?
    @Binding var editingSnippetId: UUID?
    @Binding var editingSnippet: Snippet?
    @Binding var renamingFolder: SnippetFolder?
    @Binding var newFolderName: String

    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder Header
            HStack(spacing: 6) {
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3)
                }

                Text(folder.icon)
                    .font(.system(size: 14))

                Text(folder.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))

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
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Single click: select folder and toggle expansion
                print("🔵 FOLDER CLICKED: '\(folder.name)' (ID: \(folder.id))")
                onSelect()
                clipboardManager.toggleFolderExpansion(folder.id)
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .contextMenu {
                Button("Rename Folder...") {
                    newFolderName = folder.name
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

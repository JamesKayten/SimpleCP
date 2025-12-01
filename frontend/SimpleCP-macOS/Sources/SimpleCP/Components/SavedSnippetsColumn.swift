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
    @State private var editingSnippet: Snippet?
    @State private var renamingFolder: SnippetFolder?
    @State private var newFolderName: String = ""

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
                            isSelected: selectedFolderId == folder.id,
                            hoveredSnippetId: $hoveredSnippetId,
                            editingSnippetId: $editingSnippetId,
                            editingSnippet: $editingSnippet,
                            renamingFolder: $renamingFolder,
                            newFolderName: $newFolderName,
                            onSelect: {
                                selectedFolderId = folder.id
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(item: $editingSnippet) { snippet in
            EditSnippetDialog(snippet: snippet)
                .environmentObject(clipboardManager)
        }
        .sheet(item: $renamingFolder) { folder in
            RenameFolderDialog(folder: folder, newName: $newFolderName)
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

// MARK: - Preview

#Preview {
    SavedSnippetsColumn(searchText: "", selectedFolderId: .constant(nil))
        .environmentObject(ClipboardManager())
        .frame(width: 300, height: 400)
}

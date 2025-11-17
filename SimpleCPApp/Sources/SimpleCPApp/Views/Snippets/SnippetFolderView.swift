//
//  SnippetFolderView.swift
//  SimpleCPApp
//
//  Expandable folder containing snippets
//

import SwiftUI

struct SnippetFolderView: View {
    @EnvironmentObject var appState: AppState
    let folder: SnippetFolder

    @State private var showingRenameDialog = false
    @State private var newFolderName = ""

    private var isExpanded: Bool {
        appState.snippetFolders.first(where: { $0.id == folder.id })?.isExpanded ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            Button(action: {
                withAnimation {
                    appState.toggleFolderExpansion(folder: folder)
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "folder.fill.badge.minus" : "folder.fill.badge.plus")
                        .foregroundColor(.accentColor)

                    Text(folder.name)
                        .font(.headline)

                    Text("(\(folder.items.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Rename Folder...") {
                    newFolderName = folder.name
                    showingRenameDialog = true
                }

                Divider()

                Button("Delete Folder", role: .destructive) {
                    Task {
                        await appState.deleteFolder(name: folder.name)
                    }
                }
            }

            // Folder contents (when expanded)
            if isExpanded {
                ForEach(folder.items) { item in
                    SnippetItemView(item: item, folderName: folder.name)
                        .padding(.leading, 20)
                }

                // Quick add hint
                if folder.items.isEmpty {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.secondary)
                        Text("No snippets in this folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 32)
                    .padding(.vertical, 8)
                }
            }

            Divider()
        }
        .alert("Rename Folder", isPresented: $showingRenameDialog) {
            TextField("New Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                Task {
                    await appState.renameFolder(oldName: folder.name, newName: newFolderName)
                }
            }
        }
    }
}

#Preview {
    SnippetFolderView(
        folder: SnippetFolder(
            name: "Email Templates",
            items: []
        )
    )
    .environmentObject(AppState())
    .frame(width: 400)
}

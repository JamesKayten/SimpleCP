import SwiftUI

// Expandable snippet folder
struct SnippetFolderView: View {
    let folder: SnippetFolder
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var snippetService: SnippetService?
    @State private var isHovered = false
    @State private var showingRenameDialog = false
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Folder header
            HStack {
                Button(action: {
                    appState.toggleFolder(name: folder.name)
                }) {
                    HStack {
                        Image(systemName: folder.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)

                        Image(systemName: "folder.fill")
                            .foregroundColor(.accentColor)

                        Text(folder.name)
                            .font(.body)
                            .fontWeight(.medium)

                        Spacer()

                        Text("\(folder.items.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Action buttons (visible on hover)
                if isHovered {
                    HStack(spacing: 4) {
                        Button(action: {
                            newName = folder.name
                            showingRenameDialog = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        .help("Rename folder")

                        Button(action: {
                            Task {
                                await snippetService?.deleteFolder(name: folder.name)
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        .help("Delete folder")
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .onHover { hovering in
                isHovered = hovering
            }

            // Expanded items
            if folder.isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(folder.items) { item in
                        SnippetItemView(item: item, folderName: folder.name)
                            .padding(.leading, 24)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingRenameDialog) {
            renameDialog
        }
        .onAppear {
            snippetService = SnippetService(apiClient: apiClient, appState: appState)
        }
    }

    // Rename dialog
    private var renameDialog: some View {
        VStack(spacing: 16) {
            Text("Rename Folder")
                .font(.headline)

            TextField("New Name", text: $newName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingRenameDialog = false
                }

                Button("Rename") {
                    Task {
                        await snippetService?.renameFolder(oldName: folder.name, newName: newName)
                        showingRenameDialog = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.isEmpty || newName == folder.name)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

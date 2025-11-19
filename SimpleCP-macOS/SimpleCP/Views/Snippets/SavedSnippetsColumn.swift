import SwiftUI

struct SavedSnippetsColumn: View {
    @EnvironmentObject var appState: AppState
    let searchText: String

    var filteredFolders: [SnippetFolder] {
        if searchText.isEmpty {
            return appState.snippetFolders
        }
        return appState.snippetFolders.compactMap { folder in
            let filteredSnippets = folder.snippets.filter { snippet in
                snippet.snippetName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                snippet.content.localizedCaseInsensitiveContains(searchText)
            }
            guard !filteredSnippets.isEmpty else { return nil }
            return SnippetFolder(
                name: folder.name,
                icon: folder.icon,
                isExpanded: folder.isExpanded,
                snippets: filteredSnippets
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: "folder.fill")
                Text("SAVED SNIPPETS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            // Snippets List
            ScrollView {
                LazyVStack(spacing: 4) {
                    if filteredFolders.isEmpty {
                        Text("No snippets yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredFolders) { folder in
                            SnippetFolderView(folder: folder)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct SnippetFolderView: View {
    @EnvironmentObject var appState: AppState
    @State var folder: SnippetFolder

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            HStack {
                Image(systemName: folder.icon)
                    .foregroundColor(.accentColor)
                Text(folder.name)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                if !folder.isExpanded {
                    Text("(\(folder.snippets.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Image(systemName: folder.isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                folder.isExpanded.toggle()
                appState.toggleFolder(folder.name)
            }
            .contextMenu {
                Button("Rename Folder...") {
                    appState.renameFolder(folder.name)
                }
                Button("Change Icon...") {
                    appState.changeFolderIcon(folder.name)
                }
                Divider()
                Button("Delete Folder", role: .destructive) {
                    appState.deleteFolder(folder.name)
                }
            }

            // Folder contents (when expanded)
            if folder.isExpanded {
                ForEach(folder.snippets) { snippet in
                    SnippetItemView(snippet: snippet, folderName: folder.name)
                }

                // Quick add option
                Button(action: {
                    appState.selectedFolderForQuickAdd = folder.name
                    appState.showCreateSnippet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add snippet here...")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 28)
                .padding(.vertical, 4)
            }
        }
    }
}

struct SnippetItemView: View {
    @EnvironmentObject var appState: AppState
    let snippet: ClipboardItem
    let folderName: String
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text("├──")
                .foregroundColor(.secondary)
                .font(.system(.caption, design: .monospaced))

            Text(snippet.snippetName ?? snippet.displayString)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 28)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            copyToClipboard(snippet)
        }
        .contextMenu {
            Button("Copy to Clipboard") {
                copyToClipboard(snippet)
            }
            Button("Edit Content...") {
                appState.editSnippet(snippet, in: folderName)
            }
            Button("Rename...") {
                appState.renameSnippet(snippet, in: folderName)
            }
            Button("Duplicate") {
                appState.duplicateSnippet(snippet, in: folderName)
            }
            Divider()
            Menu("Move to Folder") {
                ForEach(appState.snippetFolders.filter { $0.name != folderName }) { folder in
                    Button(folder.name) {
                        appState.moveSnippet(snippet, from: folderName, to: folder.name)
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                appState.deleteSnippet(snippet, from: folderName)
            }
        }
    }

    private func copyToClipboard(_ clip: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(clip.content, forType: .string)
    }
}

#Preview {
    SavedSnippetsColumn(searchText: "")
        .environmentObject(AppState.preview)
        .frame(width: 300, height: 400)
}

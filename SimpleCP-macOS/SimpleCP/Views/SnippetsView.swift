import SwiftUI

struct SnippetsView: View {
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        VStack {
            if clipboardService.snippetFolders.isEmpty {
                EmptySnippetsView()
            } else {
                SnippetFolderList()
            }
        }
        .navigationTitle("Snippets")
        .toolbar {
            ToolbarItem {
                Button("New Folder") {
                    // TODO: Show new folder dialog
                }
            }
        }
    }
}

struct EmptySnippetsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Snippets Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Save frequently used text from your clipboard history")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SnippetFolderList: View {
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        List(clipboardService.snippetFolders) { folder in
            SnippetFolderRow(folder: folder)
        }
        .refreshable {
            await clipboardService.fetchSnippets()
        }
    }
}

struct SnippetFolderRow: View {
    let folder: SnippetFolder

    var body: some View {
        DisclosureGroup {
            ForEach(folder.snippets) { snippet in
                SnippetItemRow(snippet: snippet)
                    .padding(.leading, 16)
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)

                Text(folder.folderName)
                    .font(.headline)

                Spacer()

                Text("\(folder.snippets.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SnippetItemRow: View {
    let snippet: ClipboardItem
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let name = snippet.name {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(snippet.preview)
                .lineLimit(2)
                .font(.body)
                .foregroundColor(.secondary)

            if !snippet.tags.isEmpty {
                HStack {
                    ForEach(snippet.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await clipboardService.copyItem(snippet)
            }
        }
        .contextMenu {
            Button("Copy") {
                Task {
                    await clipboardService.copyItem(snippet)
                }
            }
            Button("Edit") {
                // TODO: Show edit snippet dialog
            }
            Button("Delete", role: .destructive) {
                // TODO: Confirm and delete snippet
            }
        }
    }
}

#Preview {
    SnippetsView()
        .environmentObject(ClipboardService())
}
import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardService = ClipboardService()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Combined Search/Control Bar
            VStack(spacing: 8) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clips and snippets...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Control Bar
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Create Folder")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Manage Folders")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    Button(action: clearHistory) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear History")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Two-Column Content
            HStack(spacing: 0) {
                // Left Column - Recent Clips
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("RECENT CLIPS")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))

                    // Content
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(clipboardService.historyItems.enumerated()), id: \.element.id) { index, item in
                                RecentClipRow(number: index + 1, item: item)
                                    .onTapGesture {
                                        Task {
                                            await clipboardService.copyItem(item)
                                        }
                                    }
                            }

                            // History folder ranges
                            if clipboardService.historyItems.count >= 10 {
                                HistoryFolderRanges()
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right Column - Saved Snippets
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "folder")
                        Text("SAVED SNIPPETS")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))

                    // Content
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(clipboardService.snippetFolders) { folder in
                                SnippetFolderRow(folder: folder)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .environmentObject(clipboardService)
        .onAppear {
            refreshData()
        }
    }

    private func refreshData() {
        Task {
            await clipboardService.fetchHistory()
            await clipboardService.fetchSnippets()
        }
    }

    private func clearHistory() {
        // TODO: Implement clear history
    }
}

struct RecentClipRow: View {
    let number: Int
    let item: ClipboardItem
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)

            Text(item.preview)
                .font(.system(.body, design: .default))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            // Add hover effect
        }
        .contextMenu {
            Button("Copy") {
                Task { await clipboardService.copyItem(item) }
            }
            Button("Save as Snippet") {
                // TODO: Save as snippet
            }
        }
    }
}

struct HistoryFolderRanges: View {
    var body: some View {
        VStack(spacing: 2) {
            Divider()
                .padding(.vertical, 4)

            ForEach([(11, 20), (21, 30), (31, 40), (41, 50)], id: \.0) { range in
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                    Text("\(range.0) - \(range.1)")
                        .font(.body)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: Show range items
                }
            }
        }
    }
}

struct SnippetFolderRow: View {
    let folder: SnippetFolder
    @State private var isExpanded = true
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        VStack(spacing: 0) {
            // Folder header
            HStack(spacing: 8) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)

                Text(folder.folderName)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text("\(folder.snippets.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            .contextMenu {
                Button("New Snippet") {
                    // TODO: Create new snippet
                }
                Button("Rename Folder") {
                    // TODO: Rename folder
                }
                Divider()
                Button("Delete Folder", role: .destructive) {
                    Task {
                        await deleteFolder()
                    }
                }
            }

            // Snippet items
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(folder.snippets) { snippet in
                        SnippetRow(snippet: snippet, folderName: folder.folderName)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    private func deleteFolder() async {
        // TODO: Implement folder deletion
    }
}

struct SnippetRow: View {
    let snippet: ClipboardItem
    let folderName: String
    @State private var isHovering = false
    @EnvironmentObject var clipboardService: ClipboardService

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                if let name = snippet.name {
                    Text(name)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                Text(snippet.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            if !snippet.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(snippet.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(3)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            Task {
                await clipboardService.copyItem(snippet)
            }
        }
        .contextMenu {
            Button("Copy") {
                Task { await clipboardService.copyItem(snippet) }
            }
            Button("Edit") {
                // TODO: Edit snippet
            }
            Divider()
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSnippet()
                }
            }
        }
    }

    private func deleteSnippet() async {
        // TODO: Implement snippet deletion
    }
}

#Preview {
    ContentView()
}
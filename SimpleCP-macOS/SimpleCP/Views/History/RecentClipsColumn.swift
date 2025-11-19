import SwiftUI

struct RecentClipsColumn: View {
    @EnvironmentObject var appState: AppState
    let searchText: String

    var filteredClips: [ClipboardItem] {
        if searchText.isEmpty {
            return appState.recentClips
        }
        return appState.recentClips.filter { clip in
            clip.content.localizedCaseInsensitiveContains(searchText) ||
            (clip.snippetName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                Text("RECENT CLIPS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            // Clips List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredClips.prefix(10).enumerated()), id: \.element.id) { index, clip in
                        ClipItemView(clip: clip, index: index + 1)
                    }

                    // Auto-generated folders for older items
                    if filteredClips.count > 10 {
                        Divider()
                            .padding(.vertical, 4)

                        ForEach(historyFolderRanges, id: \.self) { range in
                            HistoryFolderRow(range: range, totalClips: filteredClips.count)
                        }
                    }
                }
            }
        }
    }

    var historyFolderRanges: [String] {
        var ranges: [String] = []
        let total = filteredClips.count
        var start = 11

        while start <= total {
            let end = min(start + 9, total)
            ranges.append("\(start) - \(end)")
            start = end + 1
        }

        return ranges
    }
}

struct ClipItemView: View {
    @EnvironmentObject var appState: AppState
    let clip: ClipboardItem
    let index: Int
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index).")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(clip.displayString)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHovering {
                Button(action: {
                    appState.selectedClipForSnippet = clip
                    appState.showCreateSnippet = true
                }) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Save as Snippet")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            copyToClipboard(clip)
        }
        .contextMenu {
            Button("Copy") {
                copyToClipboard(clip)
            }
            Button("Save as Snippet...") {
                appState.selectedClipForSnippet = clip
                appState.showCreateSnippet = true
            }
            Divider()
            Button("Remove from History", role: .destructive) {
                appState.removeClip(clip)
            }
        }
    }

    private func copyToClipboard(_ clip: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(clip.content, forType: .string)
    }
}

struct HistoryFolderRow: View {
    let range: String
    let totalClips: Int
    @State private var isExpanded = false

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.secondary)
            Text(range)
                .font(.body)
            Spacer()
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

#Preview {
    RecentClipsColumn(searchText: "")
        .environmentObject(AppState.preview)
        .frame(width: 300, height: 400)
}

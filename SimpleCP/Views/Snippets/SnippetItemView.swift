import SwiftUI

// Individual snippet item
struct SnippetItemView: View {
    let item: ClipboardItem
    let folderName: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?
    @State private var snippetService: SnippetService?
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Snippet icon
            Image(systemName: "doc.text.fill")
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Snippet name
                if let name = item.snippetName {
                    Text(name)
                        .font(.body)
                        .fontWeight(.medium)
                } else {
                    Text(item.displayString)
                        .font(.body)
                        .lineLimit(1)
                }

                // Preview
                Text(item.displayString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Tags
                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            // Action buttons (visible on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {
                        Task {
                            await clipboardService?.copyToClipboard(item)
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")

                    Button(action: {
                        Task {
                            await snippetService?.deleteSnippet(folderId: folderName, itemId: item.clipId)
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete snippet")
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            appState.selectedSnippetItem = item
        }
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
            snippetService = SnippetService(apiClient: apiClient, appState: appState)
        }
    }

    private var isSelected: Bool {
        appState.selectedSnippetItem?.clipId == item.clipId
    }
}

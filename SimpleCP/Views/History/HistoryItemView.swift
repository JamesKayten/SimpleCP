import SwiftUI

// Individual history item
struct HistoryItemView: View {
    let item: ClipboardItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Content type icon
            Image(systemName: contentIcon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Display string (truncated)
                Text(item.displayString)
                    .lineLimit(2)
                    .font(.system(.body, design: .default))

                // Metadata
                HStack {
                    Text(DateUtils.formatRelativeTime(item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let sourceApp = item.sourceApp {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(sourceApp)
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        appState.showSaveDialog(for: item)
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("Save as snippet")

                    Button(action: {
                        Task {
                            await clipboardService?.deleteHistoryItem(item)
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete")
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
            appState.selectedHistoryItem = item
        }
        .padding(.horizontal)
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
        }
    }

    private var isSelected: Bool {
        appState.selectedHistoryItem?.clipId == item.clipId
    }

    private var contentIcon: String {
        switch item.contentType {
        case "text":
            return "doc.text"
        case "image":
            return "photo"
        case "url":
            return "link"
        default:
            return "doc"
        }
    }
}

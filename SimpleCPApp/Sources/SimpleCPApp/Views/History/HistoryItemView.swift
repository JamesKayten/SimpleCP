//
//  HistoryItemView.swift
//  SimpleCPApp
//
//  Individual history item with context menu
//

import SwiftUI

struct HistoryItemView: View {
    @EnvironmentObject var appState: AppState
    let item: ClipboardItem
    let index: Int

    @State private var isHovered = false
    @State private var showingSaveDialog = false

    var body: some View {
        HStack(spacing: 12) {
            // Index number
            Text("\(index).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                // Content preview
                Text(item.truncatedContent)
                    .lineLimit(2)
                    .font(.system(.body, design: .monospaced))

                // Metadata
                HStack(spacing: 8) {
                    Image(systemName: item.typeIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(item.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let app = item.sourceApp {
                        Text("• \(app)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Quick actions (shown on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {
                        Task {
                            await appState.copyToClipboard(item: item)
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Copy to Clipboard")

                    Button(action: {
                        showingSaveDialog = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("Save as Snippet")
                }
            }
        }
        .padding(12)
        .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            Task {
                await appState.copyToClipboard(item: item)
            }
        }
        .contextMenu {
            Button("Copy Again") {
                Task {
                    await appState.copyToClipboard(item: item)
                }
            }

            Button("Save as Snippet...") {
                showingSaveDialog = true
            }

            Divider()

            Button("Remove from History", role: .destructive) {
                Task {
                    await appState.deleteHistoryItem(item)
                }
            }
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveSnippetDialog(prefillItem: item)
                .environmentObject(appState)
        }
    }
}

#Preview {
    HistoryItemView(
        item: ClipboardItem(
            clipId: "1",
            content: "Sample clipboard content for testing",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            contentType: "text",
            displayString: "Sample clipboard content",
            sourceApp: "Safari",
            itemType: "history",
            hasName: false,
            snippetName: nil,
            folderPath: nil,
            tags: []
        ),
        index: 1
    )
    .environmentObject(AppState())
    .frame(width: 400)
}

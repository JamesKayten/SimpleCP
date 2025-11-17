//
//  SnippetItemView.swift
//  SimpleCPApp
//
//  Individual snippet item with context menu
//

import SwiftUI

struct SnippetItemView: View {
    @EnvironmentObject var appState: AppState
    let item: ClipboardItem
    let folderName: String

    @State private var isHovered = false
    @State private var showingEditDialog = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.typeIcon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Snippet name
                Text(item.snippetName ?? item.displayString)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Content preview
                Text(item.truncatedContent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Tags
                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text("#\(tag)")
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

            // Quick copy button (shown on hover)
            if isHovered {
                Button(action: {
                    Task {
                        await appState.copyToClipboard(item: item)
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("Copy to Clipboard")
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
            Button("Copy to Clipboard") {
                Task {
                    await appState.copyToClipboard(item: item)
                }
            }

            Button("Edit Snippet...") {
                showingEditDialog = true
            }

            Divider()

            Menu("Move to Folder") {
                ForEach(appState.snippetFolders.filter { $0.name != folderName }) { folder in
                    Button(folder.name) {
                        Task {
                            let request = MoveSnippetRequest(toFolder: folder.name)
                            try? await appState.apiClient.moveSnippet(
                                folder: folderName,
                                id: item.clipId,
                                request: request
                            )
                            await appState.loadSnippets()
                        }
                    }
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                Task {
                    await appState.deleteSnippet(folder: folderName, item: item)
                }
            }
        }
    }
}

#Preview {
    SnippetItemView(
        item: ClipboardItem(
            clipId: "1",
            content: "Sample snippet content",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            contentType: "text",
            displayString: "Sample snippet",
            sourceApp: nil,
            itemType: "snippet",
            hasName: true,
            snippetName: "My Snippet",
            folderPath: "Email Templates",
            tags: ["email", "template"]
        ),
        folderName: "Email Templates"
    )
    .environmentObject(AppState())
    .frame(width: 400)
}

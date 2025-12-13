//
//  RecentClipsColumn+Flyout.swift
//  SimpleCP
//
//  Clip group flyout components
//

import SwiftUI

// MARK: - Clip Group Flyout

struct ClipGroupFlyout: View {
    let range: String
    let clips: [ClipItem]
    let clipboardManager: ClipboardManager
    let onSaveAsSnippet: (ClipItem) -> Void
    let onPasteToActiveApp: () -> Void
    let onHoverChange: (Bool) -> Void
    let onClose: () -> Void

    @State private var hoveredClipId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text(range)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(clips.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Clips List
            if clips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No clips")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(clips) { clip in
                            FlyoutClipRow(
                                clip: clip,
                                isHovered: hoveredClipId == clip.id,
                                onPaste: {
                                    clipboardManager.copyToClipboard(clip.content)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onPasteToActiveApp()
                                        onClose()
                                    }
                                },
                                onCopy: { clipboardManager.copyToClipboard(clip.content) },
                                onSave: { onSaveAsSnippet(clip) },
                                onDelete: { clipboardManager.removeFromHistory(item: clip) }
                            )
                            .onHover { isHovered in hoveredClipId = isHovered ? clip.id : nil }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(minWidth: 300, maxWidth: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onHover { hovering in onHoverChange(hovering) }
    }
}

// MARK: - Flyout Clip Row

struct FlyoutClipRow: View {
    let clip: ClipItem
    let isHovered: Bool
    let onPaste: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: contentTypeIcon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(clip.preview)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)

                Text(clip.displayTime)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHovered {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onCopy() }
        .contextMenu {
            Button("Paste Immediately") { onPaste() }
                .keyboardShortcut(.return)
            Divider()
            Button("Copy to Clipboard") { onCopy() }
            Button("Save as Snippet...") { onSave() }
            Divider()
            Button("Remove from History") { onDelete() }
        }
    }

    private var contentTypeIcon: String {
        switch clip.contentType {
        case .text: return "doc.text"
        case .url: return "link"
        case .email: return "envelope"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .unknown: return "doc.questionmark"
        }
    }
}

//
//  RecentClipsColumn+ClipItemRow.swift
//  SimpleCP
//
//  Individual clip row component
//

import SwiftUI

// MARK: - Clip Item Row

struct ClipItemRow: View {
    let index: Int
    let clip: ClipItem
    let isHovered: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleSelect: () -> Void
    let onSelectMultiple: (Int) -> Void
    let onSave: () -> Void

    @State private var showPopover = false
    @State private var hoverTimer: Timer?
    @Environment(\.fontPreferences) private var fontPrefs
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false
    @AppStorage("clipPreviewDelay") private var clipPreviewDelay = 0.7
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        HStack(spacing: 8) {
            SelectionButton(
                isSelected: isSelected,
                index: index,
                clipboardManager: clipboardManager,
                onToggleSelect: onToggleSelect,
                onSelectMultiple: onSelectMultiple
            )

            Text(clip.preview)
                .font(fontPrefs.clipContentFont())
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture { onCopy() }
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            ClipContentPopover(clip: clip)
        }
        .onHover { hovering in
            if hovering && showSnippetPreviews {
                hoverTimer = Timer.scheduledTimer(withTimeInterval: clipPreviewDelay, repeats: false) { _ in
                    showPopover = true
                }
            } else {
                hoverTimer?.invalidate()
                hoverTimer = nil
                showPopover = false
            }
        }
    }
}

// MARK: - Selection Button with Option+Click

struct SelectionButton: View {
    let isSelected: Bool
    let index: Int
    let clipboardManager: ClipboardManager
    let onToggleSelect: () -> Void
    let onSelectMultiple: (Int) -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: {
            if NSEvent.modifierFlags.contains(.option) {
                onSelectMultiple(index)
            } else {
                onToggleSelect()
            }
        }) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { hovering in isHovering = hovering }
        .help(NSEvent.modifierFlags.contains(.option) ? "Select all clips up to #\(index)" : "Select this clip")
    }
}

// MARK: - Clip Content Popover

struct ClipContentPopover: View {
    let clip: ClipItem
    @Environment(\.fontPreferences) private var fontPrefs

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: contentTypeIcon)
                    .foregroundColor(.secondary)
                Text(contentTypeLabel)
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(clip.displayTime)
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
            }

            Divider()

            ScrollView {
                Text(clip.content)
                    .font(fontPrefs.clipContentFont())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 400, maxHeight: 300)

            HStack {
                Text("\(clip.content.count) characters")
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
                Spacer()
                if clip.content.components(separatedBy: .newlines).count > 1 {
                    Text("\(clip.content.components(separatedBy: .newlines).count) lines")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 300)
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

    private var contentTypeLabel: String {
        switch clip.contentType {
        case .text: return "Text"
        case .url: return "URL"
        case .email: return "Email"
        case .code: return "Code"
        case .unknown: return "Unknown"
        }
    }
}

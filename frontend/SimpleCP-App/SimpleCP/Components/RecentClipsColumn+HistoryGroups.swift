//
//  RecentClipsColumn+HistoryGroups.swift
//  SimpleCP
//
//  History group disclosure and row components
//

import SwiftUI

// MARK: - History Group Disclosure

struct HistoryGroupDisclosure: View {
    let range: String
    let clips: [ClipItem]
    let isExpanded: Bool
    let onToggle: () -> Void
    @Binding var hoveredClipId: UUID?
    @Binding var selectedClipIds: Set<UUID>
    let onSaveAsSnippet: (ClipItem) -> Void
    let clipboardManager: ClipboardManager
    let onPasteToActiveApp: () -> Void
    let onCopyAndRestoreFocus: (String) -> Void

    @State private var isHovered: Bool = false
    @State private var showFlyout: Bool = false
    @State private var hoverTimer: Timer?
    @State private var flyoutHovered: Bool = false
    @AppStorage("clipGroupFlyoutDelay") private var clipGroupFlyoutDelay = 0.5

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(range)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Text("(\(clips.count) clips)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: clipGroupFlyoutDelay, repeats: false) { _ in
                        showFlyout = true
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !isHovered && !flyoutHovered { showFlyout = false }
                    }
                }
            }
            .popover(isPresented: $showFlyout, arrowEdge: .trailing) {
                ClipGroupFlyout(
                    range: range, clips: clips, clipboardManager: clipboardManager,
                    onSaveAsSnippet: onSaveAsSnippet, onPasteToActiveApp: onPasteToActiveApp,
                    onHoverChange: { hovering in flyoutHovered = hovering },
                    onClose: { showFlyout = false; flyoutHovered = false }
                )
                .onAppear { flyoutHovered = true }
                .onDisappear { flyoutHovered = false }
            }

            if isExpanded {
                expandedClipsView
            }
        }
    }

    private var expandedClipsView: some View {
        VStack(spacing: 1) {
            ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                ClipItemRow(
                    index: Int(range.components(separatedBy: " - ").first ?? "0")! + index,
                    clip: clip,
                    isHovered: hoveredClipId == clip.id,
                    isSelected: selectedClipIds.contains(clip.id),
                    onCopy: { onCopyAndRestoreFocus(clip.content) },
                    onToggleSelect: {
                        if selectedClipIds.contains(clip.id) { selectedClipIds.remove(clip.id) }
                        else { selectedClipIds.insert(clip.id) }
                    },
                    onSelectMultiple: { upToIndex in
                        let clipsToSelect = Array(clipboardManager.clipHistory.prefix(upToIndex))
                        for clipItem in clipsToSelect { selectedClipIds.insert(clipItem.id) }
                    },
                    onSave: { onSaveAsSnippet(clip) }
                )
                .onHover { isHovered in hoveredClipId = isHovered ? clip.id : nil }
                .contextMenu {
                    Button("Paste Immediately") {
                        clipboardManager.copyToClipboard(clip.content)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onPasteToActiveApp() }
                    }
                    Divider()
                    Button("Copy") { clipboardManager.copyToClipboard(clip.content) }
                    Button("Save as Snippet...") { onSaveAsSnippet(clip) }
                    Divider()
                    Button(selectedClipIds.contains(clip.id) ? "Deselect" : "Select") {
                        if selectedClipIds.contains(clip.id) { selectedClipIds.remove(clip.id) }
                        else { selectedClipIds.insert(clip.id) }
                    }
                    Button("Remove from History") {
                        clipboardManager.removeFromHistory(item: clip)
                        selectedClipIds.remove(clip.id)
                    }
                }
            }
        }
        .padding(.leading, 20)
    }
}

// MARK: - History Group Row (Deprecated - keeping for compatibility)

struct HistoryGroupRow: View {
    let range: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.secondary)
            Text(range)
                .font(.system(size: 12))
            Text("(\(count) clips)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

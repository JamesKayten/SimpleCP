//
//  RecentClipsColumn.swift
//  SimpleCP
//
//  Main clips column view.
//  Extensions: +ClipItemRow, +HistoryGroups, +Flyout, +PasteActions
//

import SwiftUI
import ApplicationServices
import Carbon.HIToolbox

struct RecentClipsColumn: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    let onSaveAsSnippet: (ClipItem) -> Void

    @State private var hoveredClipId: UUID?
    @State private var selectedClipIds: Set<UUID> = []
    @State private var expandedGroups: Set<String> = []
    @Environment(\.fontPreferences) private var fontPrefs

    @AppStorage("pasteHideDelay") private var pasteHideDelay = 0.1
    @AppStorage("pasteActivateDelay") private var pasteActivateDelay = 0.4

    private var filteredClips: [ClipItem] {
        if searchText.isEmpty { return clipboardManager.clipHistory }
        return clipboardManager.clipHistory.filter { clip in
            clip.content.localizedCaseInsensitiveContains(searchText) ||
            clip.preview.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentClips: [ClipItem] { Array(filteredClips.prefix(10)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader
            Divider()
            clipsList
        }
    }

    // MARK: - Column Header

    private var columnHeader: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.secondary)
            Text("CLIPS")
                .font(fontPrefs.interfaceFont(weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()

            Button(action: { deleteSelectedClips() }) {
                Image(systemName: "trash")
                    .foregroundColor(selectedClipIds.isEmpty ? .secondary : .red)
            }
            .buttonStyle(.plain)
            .help(selectedClipIds.isEmpty ? "Select clips to delete" : "Delete \(selectedClipIds.count) selected clip(s)")
            .disabled(selectedClipIds.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .contextMenu { headerContextMenu }
    }

    @ViewBuilder
    private var headerContextMenu: some View {
        Button(action: {
            SaveSnippetWindowManager.shared.showDialog(
                content: clipboardManager.currentClipboard,
                clipboardManager: clipboardManager,
                onDismiss: {}
            )
        }) {
            Label("Save Current Clipboard as Snippet", systemImage: "square.and.arrow.down")
        }
        Divider()
        Button(action: { selectedClipIds = Set(recentClips.map { $0.id }) }) {
            Label("Select All Clips", systemImage: "checkmark.circle")
        }
        Button(action: { selectedClipIds.removeAll() }) {
            Label("Deselect All", systemImage: "circle")
        }
        Divider()
        Text("\(clipboardManager.clipHistory.count) clips in history")
            .foregroundColor(.secondary)
    }

    // MARK: - Clips List

    private var clipsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(recentClips.enumerated()), id: \.element.id) { index, clip in
                    clipRow(for: clip, at: index)
                }

                if filteredClips.count > 10 {
                    Divider().padding(.vertical, 8)
                    ForEach(historyGroups, id: \.range) { group in
                        HistoryGroupDisclosure(
                            range: group.range, clips: group.clips,
                            isExpanded: expandedGroups.contains(group.range),
                            onToggle: { toggleGroup(group.range) },
                            hoveredClipId: $hoveredClipId, selectedClipIds: $selectedClipIds,
                            onSaveAsSnippet: onSaveAsSnippet, clipboardManager: clipboardManager,
                            onPasteToActiveApp: pasteToActiveApp, onCopyAndRestoreFocus: copyAndRestoreFocus
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func clipRow(for clip: ClipItem, at index: Int) -> some View {
        ClipItemRow(
            index: index + 1, clip: clip,
            isHovered: hoveredClipId == clip.id,
            isSelected: selectedClipIds.contains(clip.id),
            onCopy: { copyAndRestoreFocus(clip.content) },
            onToggleSelect: { toggleSelection(clip.id) },
            onSelectMultiple: { upToIndex in selectMultiple(upTo: upToIndex) },
            onSave: { onSaveAsSnippet(clip) }
        )
        .onHover { isHovered in hoveredClipId = isHovered ? clip.id : nil }
        .contextMenu { clipContextMenu(for: clip) }
    }

    @ViewBuilder
    private func clipContextMenu(for clip: ClipItem) -> some View {
        Button("Paste Immediately") {
            clipboardManager.copyToClipboard(clip.content)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { pasteToActiveApp() }
        }
        Divider()
        Button("Copy") { clipboardManager.copyToClipboard(clip.content) }
        Button("Save as Snippet...") { onSaveAsSnippet(clip) }
        Divider()
        Button(selectedClipIds.contains(clip.id) ? "Deselect" : "Select") { toggleSelection(clip.id) }
        Button("Remove from History") {
            clipboardManager.removeFromHistory(item: clip)
            selectedClipIds.remove(clip.id)
        }
    }

    // MARK: - History Groups

    private var historyGroups: [(range: String, clips: [ClipItem])] {
        var groups: [(String, [ClipItem])] = []
        let total = filteredClips.count

        for i in stride(from: 11, to: total + 1, by: 10) {
            let start = i
            let end = min(i + 9, total)
            let clipsInRange = Array(filteredClips[safe: start - 1..<end] ?? [])
            if !clipsInRange.isEmpty {
                groups.append(("\(start) - \(end)", clipsInRange))
            }
        }
        return groups
    }

    // MARK: - Actions

    private func deleteSelectedClips() {
        guard !selectedClipIds.isEmpty else { return }
        let clipsToDelete = clipboardManager.clipHistory.filter { selectedClipIds.contains($0.id) }
        for clip in clipsToDelete { clipboardManager.removeFromHistory(item: clip) }
        selectedClipIds.removeAll()
    }

    private func toggleSelection(_ id: UUID) {
        if selectedClipIds.contains(id) { selectedClipIds.remove(id) }
        else { selectedClipIds.insert(id) }
    }

    private func selectMultiple(upTo index: Int) {
        let clipsToSelect = Array(recentClips.prefix(index))
        for clipItem in clipsToSelect { selectedClipIds.insert(clipItem.id) }
    }

    private func toggleGroup(_ range: String) {
        if expandedGroups.contains(range) { expandedGroups.remove(range) }
        else { expandedGroups.insert(range) }
    }

    private func copyAndRestoreFocus(_ content: String) {
        clipboardManager.copyToClipboard(content)
        restoreFocusToPreviousApp()
    }

    private func restoreFocusToPreviousApp() {
        guard let targetApp = MenuBarManager.shared.previouslyActiveApp,
              !targetApp.isTerminated else {
            print("⚠️ No valid target app to restore focus to")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            targetApp.activate(options: [.activateIgnoringOtherApps])
            print("✅ Restored focus to: \(targetApp.localizedName ?? "unknown")")
        }
    }

    private func pasteToActiveApp() {
        let targetApp = MenuBarManager.shared.previouslyActiveApp
        let targetPID = targetApp?.processIdentifier
        MenuBarManager.shared.hidePopover()

        DispatchQueue.main.asyncAfter(deadline: .now() + pasteHideDelay) {
            if let app = targetApp, !app.isTerminated {
                app.activate(options: [.activateIgnoringOtherApps])
                DispatchQueue.main.asyncAfter(deadline: .now() + self.pasteActivateDelay) {
                    PasteActionHelper.executePaste(targetPID: targetPID)
                }
            } else {
                let workspace = NSWorkspace.shared
                if let frontmost = workspace.runningApplications.first(where: {
                    $0.activationPolicy == .regular &&
                    $0.bundleIdentifier != Bundle.main.bundleIdentifier && !$0.isTerminated
                }) {
                    let fallbackPID = frontmost.processIdentifier
                    frontmost.activate(options: [.activateIgnoringOtherApps])
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.pasteActivateDelay) {
                        PasteActionHelper.executePaste(targetPID: fallbackPID)
                    }
                } else {
                    PasteActionHelper.executePaste(targetPID: nil)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RecentClipsColumn(searchText: "", onSaveAsSnippet: { _ in })
        .environmentObject(ClipboardManager())
        .frame(width: 300, height: 400)
}

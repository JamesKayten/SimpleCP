//
//  FolderView.swift
//  SimpleCP
//
//  Folder view component for SavedSnippetsColumn.
//  Extensions: +Flyout
//

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let folder: SnippetFolder
    let snippets: [Snippet]
    let searchText: String
    let isSelected: Bool

    @Binding var hoveredSnippetId: UUID?
    @Binding var editingSnippetId: UUID?

    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var showFlyout = false
    @State private var hoverTimer: Timer?
    @State private var isFlyoutHovered = false
    @State private var hideWorkItem: DispatchWorkItem?
    @AppStorage("folderFlyoutDelay") private var folderFlyoutDelay = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            folderHeader
        }
        .onDisappear {
            hoverTimer?.invalidate()
            hoverTimer = nil
            hideWorkItem?.cancel()
            hideWorkItem = nil
        }
    }

    private var folderHeader: some View {
        HStack(spacing: 8) {
            Text(folder.name.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Text("\(snippets.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.15)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle().fill(
                isSelected ? Color.accentColor.opacity(0.1) :
                (isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color(NSColor.controlBackgroundColor))
            )
        )
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.secondary.opacity(0.2)),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                hideWorkItem?.cancel()
                hideWorkItem = nil
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: folderFlyoutDelay, repeats: false) { _ in
                    if !snippets.isEmpty { showFlyout = true }
                }
            } else {
                hoverTimer?.invalidate()
                hoverTimer = nil
                let workItem = DispatchWorkItem { [weak hoverTimer] in
                    guard hoverTimer == nil else { return }
                    if !self.isFlyoutHovered { self.showFlyout = false }
                }
                hideWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
            }
        }
        .popover(isPresented: $showFlyout, arrowEdge: .trailing) {
            FolderSnippetsFlyout(
                folder: folder, snippets: snippets, clipboardManager: clipboardManager,
                onHoverChange: { hovering in
                    isFlyoutHovered = hovering
                    if !hovering {
                        let workItem = DispatchWorkItem {
                            if !self.isHovered && !self.isFlyoutHovered { self.showFlyout = false }
                        }
                        self.hideWorkItem?.cancel()
                        self.hideWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
                    } else {
                        self.hideWorkItem?.cancel()
                        self.hideWorkItem = nil
                    }
                },
                onClose: { showFlyout = false }
            )
        }
        .contextMenu { folderContextMenu }
    }

    @ViewBuilder
    private var folderContextMenu: some View {
        Button("Add Snippet from Clipboard") { addSnippetToFolder() }
        Divider()
        Button("Rename Folder...") {
            RenameFolderWindowManager.shared.showDialog(folder: folder, clipboardManager: clipboardManager, onDismiss: {})
        }
        Divider()
        Button("Export Folder...") { clipboardManager.exportFolder(folder) }
        Divider()
        Button("Delete Folder") { deleteFolder() }
    }

    private func deleteFolder() {
        let alert = NSAlert()
        alert.messageText = "Delete Folder"
        alert.informativeText = "Are you sure you want to delete '\(folder.name)' and all its snippets?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { clipboardManager.deleteFolder(folder) }
            }
        } else {
            if alert.runModal() == .alertFirstButtonReturn { clipboardManager.deleteFolder(folder) }
        }
    }

    private func addSnippetToFolder() {
        let content = clipboardManager.currentClipboard
        let suggestedName = clipboardManager.suggestSnippetName(for: content)
        clipboardManager.saveAsSnippet(name: suggestedName, content: content, folderId: folder.id)
    }
}

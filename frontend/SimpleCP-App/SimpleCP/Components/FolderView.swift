//
//  FolderView.swift
//  SimpleCP
//
//  Folder view component for SavedSnippetsColumn
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
            // Collection Header Bar
            HStack(spacing: 8) {
                Text(folder.name.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                // Snippet count badge
                Text("\(snippets.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(
                        isSelected ? Color.accentColor.opacity(0.1) : 
                        (isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color(NSColor.controlBackgroundColor))
                    )
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.secondary.opacity(0.2)),
                alignment: .bottom
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Single click: select folder
                onSelect()
            }
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    // Cancel any pending hide operations
                    hideWorkItem?.cancel()
                    hideWorkItem = nil
                    
                    // Start timer to show flyout after user-configured delay
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: folderFlyoutDelay, repeats: false) { _ in
                        if !snippets.isEmpty {
                            showFlyout = true
                        }
                    }
                } else {
                    // Cancel timer if we stop hovering
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    
                    // Hide flyout after a short delay, unless hovering over flyout
                    let workItem = DispatchWorkItem { [weak hoverTimer] in
                        guard hoverTimer == nil else { return } // Timer is still active, abort
                        if !self.isFlyoutHovered {
                            self.showFlyout = false
                        }
                    }
                    hideWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
                }
            }
            .popover(isPresented: $showFlyout, arrowEdge: .trailing) {
                FolderSnippetsFlyout(
                    folder: folder,
                    snippets: snippets,
                    clipboardManager: clipboardManager,
                    onHoverChange: { hovering in
                        isFlyoutHovered = hovering
                        if !hovering {
                            // Hide flyout when mouse leaves
                            let workItem = DispatchWorkItem {
                                if !self.isHovered && !self.isFlyoutHovered {
                                    self.showFlyout = false
                                }
                            }
                            self.hideWorkItem?.cancel()
                            self.hideWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
                        } else {
                            // Cancel hide if hovering back over flyout
                            self.hideWorkItem?.cancel()
                            self.hideWorkItem = nil
                        }
                    },
                    onClose: {
                        showFlyout = false
                    }
                )
            }
            .contextMenu {
                Button("Add Snippet from Clipboard") {
                    addSnippetToFolder()
                }
                Divider()
                Button("Rename Folder...") {
                    RenameFolderWindowManager.shared.showDialog(
                        folder: folder,
                        clipboardManager: clipboardManager,
                        onDismiss: {}
                    )
                }
                Divider()
                Button("Export Folder...") {
                    clipboardManager.exportFolder(folder)
                }
                Divider()
                Button("Delete Folder") {
                    deleteFolder()
                }
            }
        }
        .onDisappear {
            // Clean up timers and work items when view disappears
            hoverTimer?.invalidate()
            hoverTimer = nil
            hideWorkItem?.cancel()
            hideWorkItem = nil
        }
    }

    private func deleteFolder() {
        let alert = NSAlert()
        alert.messageText = "Delete Folder"
        alert.informativeText = "Are you sure you want to delete '\(folder.name)' and all its snippets?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        // Ensure alert appears in front
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    clipboardManager.deleteFolder(folder)
                }
            }
        } else {
            if alert.runModal() == .alertFirstButtonReturn {
                clipboardManager.deleteFolder(folder)
            }
        }
    }

    private func addSnippetToFolder() {
        let content = clipboardManager.currentClipboard
        let suggestedName = clipboardManager.suggestSnippetName(for: content)
        clipboardManager.saveAsSnippet(name: suggestedName, content: content, folderId: folder.id)
    }

    private func duplicateSnippet(_ snippet: Snippet) {
        var newSnippet = snippet
        newSnippet = Snippet(
            name: snippet.name + " (Copy)",
            content: snippet.content,
            tags: snippet.tags,
            folderId: snippet.folderId
        )
        clipboardManager.saveAsSnippet(
            name: newSnippet.name,
            content: newSnippet.content,
            folderId: newSnippet.folderId,
            tags: newSnippet.tags
        )
    }
    

}

// MARK: - Folder Snippets Flyout

struct FolderSnippetsFlyout: View {
    let folder: SnippetFolder
    let snippets: [Snippet]
    let clipboardManager: ClipboardManager
    let onHoverChange: (Bool) -> Void
    let onClose: () -> Void
    
    @State private var hoveredSnippetId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text(folder.icon)
                    .font(.system(size: 16))
                Text(folder.name)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(snippets.count)")
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
            
            // Snippets List
            if snippets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No snippets")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(snippets) { snippet in
                            FlyoutSnippetRow(
                                snippet: snippet,
                                isHovered: hoveredSnippetId == snippet.id,
                                onPaste: {
                                    clipboardManager.copyToClipboard(snippet.content)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        pasteToActiveApp()
                                        onClose()
                                    }
                                },
                                onCopy: {
                                    clipboardManager.copyToClipboard(snippet.content)
                                },
                                onEdit: {
                                    EditSnippetWindowManager.shared.showDialog(
                                        snippet: snippet,
                                        clipboardManager: clipboardManager,
                                        onDismiss: {}
                                    )
                                },
                                onDelete: {
                                    clipboardManager.deleteSnippet(snippet)
                                }
                            )
                            .onHover { isHovered in
                                hoveredSnippetId = isHovered ? snippet.id : nil
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(minWidth: 300, maxWidth: 400)
        .background(
            ZStack {
                // Ensure solid background to prevent transparency issues
                Color(NSColor.windowBackgroundColor)
                    .opacity(1.0)
            }
        )
        .onHover { hovering in
            onHoverChange(hovering)
        }
    }
    
    private func pasteToActiveApp() {
        // Check accessibility permissions using the proper API with prompt option
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            // Show our custom dialog instead of system prompt
            showAccessibilityPermissionDialog()
            return
        }
        
        // We have permissions, proceed with paste
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create and post Cmd+V
        guard let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("❌ Failed to create keyboard events")
            return
        }
        
        keyVDown.flags = .maskCommand
        keyVUp.flags = .maskCommand
        
        keyVDown.post(tap: .cghidEventTap)
        keyVUp.post(tap: .cghidEventTap)
    }
    
    private func showAccessibilityPermissionDialog() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "SimpleCP needs Accessibility permissions to paste automatically.\n\nClick 'Open Settings' to grant permission, then restart SimpleCP."
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .informational
            
            // Ensure alert appears in front
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                alert.beginSheetModal(for: window) { response in
                    if response == .alertFirstButtonReturn {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            } else {
                if alert.runModal() == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

// MARK: - Flyout Snippet Row

struct FlyoutSnippetRow: View {
    let snippet: Snippet
    let isHovered: Bool
    let onPaste: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            if snippet.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                    .fixedSize()
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(snippet.preview)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                if !snippet.tags.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(snippet.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        if snippet.tags.count > 3 {
                            Text("+\(snippet.tags.count - 3)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 4)
            
            // Hover action button
            if isHovered {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .contextMenu {
            Button("Paste Immediately") {
                onPaste()
            }
            .keyboardShortcut(.return)
            
            Divider()
            
            Button("Copy to Clipboard") {
                onCopy()
            }
            
            Button("Edit...") {
                onEdit()
            }
            
            Divider()
            
            Button("Delete") {
                onDelete()
            }
        }
    }
}


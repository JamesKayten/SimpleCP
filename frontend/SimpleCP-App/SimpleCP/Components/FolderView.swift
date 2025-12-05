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
    @State private var flyoutHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder Header
            HStack(spacing: 6) {
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3)
                }

                Text(folder.icon)
                    .font(.system(size: 14))

                Text(folder.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))

                Spacer()

                // Expand/Collapse indicator
                Image(systemName: folder.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                if !folder.isExpanded {
                    Text("(\(snippets.count))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        showFlyout ? Color.accentColor.opacity(0.25) :
                        isSelected ? Color.accentColor.opacity(0.15) : 
                        (isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isHovered ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Single click: select folder and toggle expansion
                print("🔵 FOLDER CLICKED: '\(folder.name)' (ID: \(folder.id))")
                onSelect()
                clipboardManager.toggleFolderExpansion(folder.id)
            }
            .onHover { hovering in
                print("🔶 SIMPLE HOVER: \(hovering) on folder: \(folder.name)")
                isHovered = hovering
                if hovering {
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        print("🟦 SHOWING FLYOUT for folder: \(folder.name)")
                        showFlyout = true
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    // Keep flyout open if mouse is over flyout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !isHovered && !flyoutHovered {
                            showFlyout = false
                        }
                    }
                }
            }
            .popover(isPresented: $showFlyout, arrowEdge: .trailing) {
                FolderSnippetsFlyout(
                    folder: folder,
                    snippets: snippets,
                    clipboardManager: clipboardManager,
                    onHoverChange: { hovering in
                        flyoutHovered = hovering
                    },
                    onClose: { 
                        showFlyout = false
                        flyoutHovered = false
                    }
                )
                .onAppear {
                    print("✅ FLYOUT APPEARED for folder: \(folder.name)")
                    flyoutHovered = true
                }
                .onDisappear {
                    flyoutHovered = false
                }
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
                Button("Change Icon...") {
                    changeIcon()
                }
                Divider()
                Button("Delete Folder") {
                    deleteFolder()
                }
            }

            // Snippets in folder (when expanded)
            if folder.isExpanded {
                ForEach(snippets) { snippet in
                    SnippetItemRow(
                        snippet: snippet,
                        isHovered: hoveredSnippetId == snippet.id,
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
                    .contextMenu {
                        Button("Paste Immediately") {
                            clipboardManager.copyToClipboard(snippet.content)
                            // Simulate paste command (Cmd+V)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                pasteToActiveApp()
                            }
                        }
                        Divider()
                        Button("Copy to Clipboard") {
                            clipboardManager.copyToClipboard(snippet.content)
                        }
                        Button("Edit...") {
                            EditSnippetWindowManager.shared.showDialog(
                                snippet: snippet,
                                clipboardManager: clipboardManager,
                                onDismiss: {}
                            )
                        }
                        Button("Duplicate") {
                            duplicateSnippet(snippet)
                        }
                        Divider()
                        Button("Delete") {
                            clipboardManager.deleteSnippet(snippet)
                        }
                    }
                }

                // Quick add snippet divider
                if !snippets.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }

                // Quick add button
                Button(action: {
                    addSnippetToFolder()
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.secondary)
                        Text("Add snippet here...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }

    private func changeIcon() {
        let alert = NSAlert()
        alert.messageText = "Change Folder Icon"
        alert.informativeText = "Enter a new icon (emoji) for '\(folder.name)':"
        alert.addButton(withTitle: "Change")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = folder.icon
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let newIcon = textField.stringValue
            if !newIcon.isEmpty {
                var updatedFolder = folder
                updatedFolder.changeIcon(to: newIcon)
                clipboardManager.updateFolder(updatedFolder)
            }
        }
    }

    private func deleteFolder() {
        let alert = NSAlert()
        alert.messageText = "Delete Folder"
        alert.informativeText = "Are you sure you want to delete '\(folder.name)' and all its snippets?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            clipboardManager.deleteFolder(folder)
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
    
    private func pasteToActiveApp() {
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            // Show alert and open System Settings
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "SimpleCP needs Accessibility permissions to paste automatically.\n\nClick 'Open Settings' to grant permission, then restart SimpleCP."
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .informational
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // Open System Settings to Accessibility
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            return
        }
        
        // Create a paste event (Cmd+V)
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down event for Cmd+V
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyVDown?.flags = .maskCommand
        
        // Key up event for Cmd+V
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyVUp?.flags = .maskCommand
        
        // Post the events
        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
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
        .background(Color(NSColor.windowBackgroundColor))
        .onHover { hovering in
            onHoverChange(hovering)
        }
    }
    
    private func pasteToActiveApp() {
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            // Show alert and open System Settings
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "SimpleCP needs Accessibility permissions to paste automatically.\n\nClick 'Open Settings' to grant permission, then restart SimpleCP."
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .informational
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // Open System Settings to Accessibility
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            return
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyVDown?.flags = .maskCommand
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyVUp?.flags = .maskCommand
        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
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
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                Text(snippet.preview)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
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
            
            Spacer()
            
            // Hover action button
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


//
//  FolderView+Flyout.swift
//  SimpleCP
//
//  Flyout components for folder snippet preview
//

import SwiftUI

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
            HStack(spacing: 8) {
                Text(folder.icon).font(.system(size: 16))
                Text(folder.name).font(.system(size: 13, weight: .semibold))
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

            if snippets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.system(size: 32)).foregroundColor(.secondary)
                    Text("No snippets").font(.system(size: 12)).foregroundColor(.secondary)
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
                                    restoreFocusToPreviousApp()
                                },
                                onEdit: {
                                    EditSnippetWindowManager.shared.showDialog(
                                        snippet: snippet,
                                        clipboardManager: clipboardManager,
                                        onDismiss: {}
                                    )
                                },
                                onDelete: { clipboardManager.deleteSnippet(snippet) }
                            )
                            .onHover { isHovered in hoveredSnippetId = isHovered ? snippet.id : nil }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(minWidth: 300, maxWidth: 400)
        .background(Color(NSColor.windowBackgroundColor).opacity(1.0))
        .onHover { hovering in onHoverChange(hovering) }
    }

    private func restoreFocusToPreviousApp() {
        guard let targetApp = MenuBarManager.shared.previouslyActiveApp,
              !targetApp.isTerminated else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            targetApp.activate(options: [.activateIgnoringOtherApps])
        }
    }

    private func pasteToActiveApp() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted {
            showAccessibilityPermissionDialog()
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }

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
            if snippet.isFavorite {
                Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.yellow).fixedSize()
            } else {
                Image(systemName: "doc.text").font(.system(size: 11)).foregroundColor(.secondary).fixedSize()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.name).font(.system(size: 12, weight: .medium)).lineLimit(1).truncationMode(.tail)
                Text(snippet.preview).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(2).truncationMode(.tail)
                if !snippet.tags.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(snippet.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)").font(.system(size: 9)).foregroundColor(.secondary)
                        }
                        if snippet.tags.count > 3 {
                            Text("+\(snippet.tags.count - 3)").font(.system(size: 9)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            if isHovered {
                Image(systemName: "arrow.right.circle.fill").font(.system(size: 16)).foregroundColor(.accentColor).fixedSize()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture { onCopy() }
        .contextMenu {
            Button("Paste Immediately") { onPaste() }.keyboardShortcut(.return)
            Divider()
            Button("Copy to Clipboard") { onCopy() }
            Button("Edit...") { onEdit() }
            Divider()
            Button("Delete") { onDelete() }
        }
    }
}

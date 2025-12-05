//
//  EditSnippetWindowManager.swift
//  SimpleCP
//
//  Window manager for Edit Snippet dialog to avoid MenuBarExtra event issues
//

import SwiftUI
import AppKit

class EditSnippetWindowManager: ObservableObject {
    static let shared = EditSnippetWindowManager()
    
    private var dialogWindow: NSWindow?
    
    func showDialog(snippet: Snippet, clipboardManager: ClipboardManager, onDismiss: @escaping () -> Void) {
        // Close existing window if any
        closeDialog()
        
        // Create the SwiftUI view
        let dialogView = EditSnippetDialogContent(
            snippet: snippet,
            onDismiss: {
                self.closeDialog()
                onDismiss()
            }
        )
        .environmentObject(clipboardManager)
        .frame(width: 500, height: 400)
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: dialogView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        
        // Use NSPanel for floating dialog
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Edit Snippet"
        panel.contentView = hostingView
        panel.center()
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        
        // Make panel visible and key
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        
        self.dialogWindow = panel
    }
    
    func closeDialog() {
        dialogWindow?.close()
        dialogWindow = nil
    }
}

// Separate content view
struct EditSnippetDialogContent: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let snippet: Snippet
    let onDismiss: () -> Void
    
    @State private var editedName: String
    @State private var editedContent: String
    @State private var editedTags: String
    
    init(snippet: Snippet, onDismiss: @escaping () -> Void) {
        self.snippet = snippet
        self.onDismiss = onDismiss
        _editedName = State(initialValue: snippet.name)
        _editedContent = State(initialValue: snippet.content)
        _editedTags = State(initialValue: snippet.tags.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Edit Snippet")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name:")
                    .font(.subheadline)
                TextField("Snippet name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Content:")
                    .font(.subheadline)
                TextEditor(text: $editedContent)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.3))
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (comma-separated):")
                    .font(.subheadline)
                TextField("tag1, tag2, tag3", text: $editedTags)
                    .textFieldStyle(.roundedBorder)
            }
            
            Spacer()
            
            Divider()
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
    }
    
    private func saveChanges() {
        var updatedSnippet = snippet
        updatedSnippet.name = editedName
        updatedSnippet.update(content: editedContent)
        updatedSnippet.tags = editedTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        clipboardManager.updateSnippet(updatedSnippet)
        onDismiss()
    }
}

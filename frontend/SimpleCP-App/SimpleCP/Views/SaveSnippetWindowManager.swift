//
//  SaveSnippetWindowManager.swift
//  SimpleCP
//
//  Window manager for Save Snippet dialog to avoid MenuBarExtra event issues
//

import SwiftUI
import AppKit

// AppKit TextField wrapper for better focus handling
struct AppKitTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var onCommit: () -> Void = {}
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        
        // Ensure the text field accepts first responder
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onCommit: () -> Void
        
        init(text: Binding<String>, onCommit: @escaping () -> Void) {
            _text = text
            self.onCommit = onCommit
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                text = textField.stringValue
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onCommit()
                return true
            }
            return false
        }
    }
}

class SaveSnippetWindowManager: ObservableObject {
    static let shared = SaveSnippetWindowManager()
    
    private var dialogWindow: NSWindow?
    
    func showDialog(content: String, clipboardManager: ClipboardManager, onDismiss: @escaping () -> Void) {
        // Close existing window if any
        closeDialog()
        
        // CRITICAL: For menu bar apps, we need to temporarily change activation policy
        // to allow the window to receive keyboard events
        let wasAccessory = NSApp.activationPolicy() == .accessory
        if wasAccessory {
            NSApp.setActivationPolicy(.regular)
        }
        
        // Create the SwiftUI view
        let dialogView = SaveSnippetDialogContent(
            content: content,
            onDismiss: {
                // Restore activation policy when closing
                if wasAccessory {
                    NSApp.setActivationPolicy(.accessory)
                }
                self.closeDialog()
                onDismiss()
            }
        )
        .environmentObject(clipboardManager)
        .frame(width: 400, height: 500)
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: dialogView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        
        // Use NSPanel instead of NSWindow - panels are better for auxiliary windows
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Save as Snippet"
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

// Separate content view to avoid binding issues
struct SaveSnippetDialogContent: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let content: String
    let onDismiss: () -> Void
    
    @State private var snippetName: String = ""
    @State private var selectedFolderId: UUID?
    @State private var createNewFolder: Bool = false
    @State private var newFolderName: String = ""
    @State private var tags: String = ""
    @State private var contentPreview: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Save as Snippet")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Content Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Content Preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(contentPreview)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
            }
            
            // Snippet Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Snippet Name:")
                    .font(.caption)
                AppKitTextField(text: $snippetName, placeholder: "Name", onCommit: {
                    if !snippetName.isEmpty {
                        saveSnippet()
                    }
                })
                .frame(height: 22)
            }
            
            // Folder Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Folder:")
                    .font(.caption)
                ScrollView {
                    VStack(spacing: 2) {
                        folderRow(label: "None", folderId: nil)
                        ForEach(clipboardManager.folders) { folder in
                            folderRow(label: "\(folder.icon) \(folder.name)", folderId: folder.id)
                        }
                    }
                }
                .frame(height: 80)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .id(clipboardManager.folders.count) // Force refresh when folder count changes
            }
            
            // New Folder Toggle
            Button(action: {
                createNewFolder.toggle()
                print("🔵 Create new folder toggled: \(createNewFolder)")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: createNewFolder ? "checkmark.square.fill" : "square")
                        .foregroundColor(createNewFolder ? .blue : .secondary)
                    Text("Create new folder")
                        .font(.caption)
                        .foregroundColor(createNewFolder ? .blue : .primary)
                }
            }
            .buttonStyle(.plain)
            .help(createNewFolder ? "Hide folder creation" : "Show folder creation")
            
            // New Folder Input
            if createNewFolder {
                HStack(spacing: 8) {
                    AppKitTextField(text: $newFolderName, placeholder: "Folder name", onCommit: createFolder)
                        .frame(height: 22)
                        .onChange(of: newFolderName) { newValue in
                            print("🔵 newFolderName changed to: '\(newValue)' (isEmpty: \(newValue.isEmpty))")
                        }
                    
                    Button(action: {
                        print("➕ Create folder button tapped. Folder name: '\(newFolderName)'")
                        print("➕ isEmpty check: \(newFolderName.isEmpty)")
                        if !newFolderName.isEmpty {
                            createFolder()
                        } else {
                            print("➕ Button was disabled, folder name is empty!")
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(newFolderName.isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.borderless)
                    .help(newFolderName.isEmpty ? "Enter a folder name" : "Create folder '\(newFolderName)'")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(4)
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                AppKitTextField(text: $tags, placeholder: "#tag1 #tag2")
                    .frame(height: 22)
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
                    saveSnippet()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(snippetName.isEmpty || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .onAppear {
            contentPreview = content
            snippetName = clipboardManager.suggestSnippetName(for: content)
            if selectedFolderId == nil {
                selectedFolderId = clipboardManager.folders.first?.id
            }
        }
    }
    
    private func folderRow(label: String, folderId: UUID?) -> some View {
        Button(action: {
            selectedFolderId = folderId
        }) {
            HStack {
                Circle()
                    .fill(selectedFolderId == folderId ? Color.blue : Color.clear)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.caption)
                Spacer()
            }
            .padding(4)
            .background(selectedFolderId == folderId ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func createFolder() {
        print("🔵 createFolder() called")
        print("🔵 newFolderName: '\(newFolderName)'")
        
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("🔵 Folder name is empty, returning")
            return
        }
        
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔵 Creating folder with name: '\(trimmedName)'")
        
        let newFolderID = clipboardManager.createFolder(name: trimmedName)
        print("🔵 Folder created with ID: \(newFolderID)")
        print("🔵 Total folders now: \(clipboardManager.folders.count)")
        
        // Update UI state - force refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectedFolderId = newFolderID
            self.createNewFolder = false
            self.newFolderName = ""
            print("🔵 Folder creation complete, UI state updated")
        }
    }
    
    private func saveSnippet() {
        guard !snippetName.isEmpty else { return }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let tagArray = tags
            .components(separatedBy: CharacterSet(charactersIn: "#, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        clipboardManager.saveAsSnippet(
            name: snippetName,
            content: content,
            folderId: selectedFolderId,
            tags: tagArray
        )
        
        onDismiss()
    }
}

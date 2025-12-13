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
        
        // CRITICAL: For menu bar apps in accessory mode, we need to temporarily change 
        // activation policy to allow the window to receive keyboard events
        // This is coordinated with AppDelegate's activation policy management
        let wasAccessory = NSApp.activationPolicy() == .accessory
        let needsTemporaryPromotion = wasAccessory && !UserDefaults.standard.bool(forKey: "showInDock")
        
        if needsTemporaryPromotion {
            NSApp.setActivationPolicy(.regular)
        }
        
        // Create the SwiftUI view
        let dialogView = SaveSnippetDialogContent(
            content: content,
            onDismiss: {
                // Restore activation policy when closing (if needed)
                if needsTemporaryPromotion {
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
    @State private var folderListRefreshID = UUID() // Force folder list refresh
    
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
                        ForEach(clipboardManager.folders, id: \.id) { folder in
                            folderRow(label: "\(folder.icon) \(folder.name)", folderId: folder.id)
                                .id(folder.id) // Ensure unique identity per folder
                        }
                    }
                    .id(folderListRefreshID) // Force refresh when this ID changes
                }
                .frame(height: 80)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
            }
            
            // New Folder Toggle
            Button(action: {
                createNewFolder.toggle()
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
                    
                    Button(action: {
                        if !newFolderName.isEmpty {
                            createFolder()
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
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clipboardManager.logger.debug("⚠️ Dialog: Empty folder name, skipping creation")
            return
        }
        
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        clipboardManager.logger.info("📁 Dialog: Creating new folder '\(trimmedName, privacy: .public)'")
        
        // Check if folder already exists
        if clipboardManager.folders.contains(where: { $0.name == trimmedName }) {
            // Folder already exists - just select it
            clipboardManager.logger.debug("ℹ️ Dialog: Folder '\(trimmedName, privacy: .public)' already exists, selecting it")
            if let existingFolder = clipboardManager.folders.first(where: { $0.name == trimmedName }) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.selectedFolderId = existingFolder.id
                }
                self.createNewFolder = false
                self.newFolderName = ""
            }
            return
        }
        
        // Create folder - this updates @Published property which should trigger view update
        let newFolder = clipboardManager.createFolder(name: trimmedName)
        clipboardManager.logger.debug("✅ Dialog: Folder created with ID \(newFolder.id)")
        
        // The @Published property should handle the update, but we need to ensure
        // the view has time to re-render before selecting the new folder
        // Use a very short delay to let SwiftUI complete its update cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Verify the folder exists in the list
            if self.clipboardManager.folders.contains(where: { $0.id == newFolder.id }) {
                self.clipboardManager.logger.debug("✅ Dialog: Folder verified in list, selecting")
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.selectedFolderId = newFolder.id
                    self.createNewFolder = false
                    self.newFolderName = ""
                }
            } else {
                // If folder somehow didn't appear, force a refresh
                self.clipboardManager.logger.warning("⚠️ Dialog: Folder not found in list, forcing refresh")
                self.folderListRefreshID = UUID()
                
                // Try again after refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.clipboardManager.logger.debug("🔄 Dialog: Retrying folder selection after refresh")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.selectedFolderId = newFolder.id
                        self.createNewFolder = false
                        self.newFolderName = ""
                    }
                }
            }
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

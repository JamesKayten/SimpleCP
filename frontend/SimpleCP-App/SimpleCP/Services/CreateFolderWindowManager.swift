//
//  CreateFolderWindowManager.swift
//  SimpleCP
//
//  Window manager for Create Folder dialog to avoid MenuBarExtra event issues
//

import SwiftUI
import AppKit

class CreateFolderWindowManager: ObservableObject {
    static let shared = CreateFolderWindowManager()
    
    private var dialogWindow: NSWindow?
    
    func showDialog(clipboardManager: ClipboardManager, onDismiss: @escaping () -> Void) {
        // Close existing window if any
        closeDialog()
        
        // Create the SwiftUI view
        let dialogView = CreateFolderDialogContent(
            onDismiss: {
                self.closeDialog()
                onDismiss()
            }
        )
        .environmentObject(clipboardManager)
        .frame(width: 400, height: 200)
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: dialogView)
        
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Create New Folder"
        window.contentView = hostingView
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        
        // Make window float above everything and activate properly
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // Multiple attempts to ensure focus
        DispatchQueue.main.async {
            window.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeFirstResponder(window.contentView)
        }
        
        self.dialogWindow = window
    }
    
    func closeDialog() {
        dialogWindow?.close()
        dialogWindow = nil
    }
}

// Separate content view to avoid binding issues
struct CreateFolderDialogContent: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let onDismiss: () -> Void
    
    @State private var folderName: String = ""
    @State private var errorMessage: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    
    private var folderExists: Bool {
        clipboardManager.folders.contains { $0.name.lowercased() == folderName.lowercased() }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Create New Folder")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Folder Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Folder Name:")
                    .font(.subheadline)
                TextField("Enter folder name", text: $folderName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        createFolder()
                    }
                    .onChange(of: folderName) { _ in
                        // Clear error when user types
                        errorMessage = nil
                    }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else if folderExists {
                    Text("A folder with this name already exists")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Divider()
            
            // Action Buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create Folder") {
                    createFolder()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty || folderExists)
            }
        }
        .padding(16)
        .onAppear {
            folderName = ""
            
            // Focus the text field after a longer delay to ensure window is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func createFolder() {
        guard !folderName.isEmpty else { return }
        
        // Check for duplicate folder names (case-insensitive)
        if folderExists {
            errorMessage = "A folder with this name already exists"
            return
        }
        
        _ = clipboardManager.createFolder(name: folderName)
        print("✅ Folder created: \(folderName)")
        onDismiss()
    }
}

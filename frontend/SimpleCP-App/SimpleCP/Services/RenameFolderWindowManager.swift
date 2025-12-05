//
//  RenameFolderWindowManager.swift
//  SimpleCP
//
//  Window manager for Rename Folder dialog to avoid MenuBarExtra event issues
//

import SwiftUI
import AppKit

class RenameFolderWindowManager: ObservableObject {
    static let shared = RenameFolderWindowManager()
    
    func showDialog(folder: SnippetFolder, clipboardManager: ClipboardManager, onDismiss: @escaping () -> Void) {
        // Use NSAlert with text field - much more reliable for menu bar apps
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Rename Folder"
            alert.informativeText = "Enter a new name for '\(folder.name)':"
            alert.addButton(withTitle: "Rename")
            alert.addButton(withTitle: "Cancel")
            
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            textField.stringValue = folder.name
            textField.placeholderString = "Folder name"
            alert.accessoryView = textField
            
            alert.window.level = .floating
            
            // Make alert appear and focus text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                alert.window.makeKey()
                textField.becomeFirstResponder()
                
                // Select all text for easy editing
                if let textEditor = textField.currentEditor() {
                    textEditor.selectAll(nil)
                }
            }
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                let newName = textField.stringValue.trimmingCharacters(in: .whitespaces)
                if !newName.isEmpty {
                    var updatedFolder = folder
                    updatedFolder.rename(to: newName)
                    clipboardManager.updateFolder(updatedFolder)
                }
            }
            
            onDismiss()
        }
    }
}

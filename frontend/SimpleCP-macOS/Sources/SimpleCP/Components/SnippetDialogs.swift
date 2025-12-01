//
//  SnippetDialogs.swift
//  SimpleCP
//
//  Dialog components for editing snippets and renaming folders
//

import SwiftUI

// MARK: - Edit Snippet Dialog

struct EditSnippetDialog: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.dismiss) private var dismiss

    @State private var snippet: Snippet
    @State private var editedName: String
    @State private var editedContent: String
    @State private var editedTags: String

    init(snippet: Snippet) {
        _snippet = State(initialValue: snippet)
        _editedName = State(initialValue: snippet.name)
        _editedContent = State(initialValue: snippet.content)
        _editedTags = State(initialValue: snippet.tags.joined(separator: ", "))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Snippet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name:")
                    .font(.subheadline)
                TextField("Snippet name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content:")
                    .font(.subheadline)
                TextEditor(text: $editedContent)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (comma-separated):")
                    .font(.subheadline)
                TextField("tag1, tag2, tag3", text: $editedTags)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func saveChanges() {
        var updatedSnippet = snippet
        updatedSnippet.name = editedName
        updatedSnippet.update(content: editedContent)
        updatedSnippet.tags = editedTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        clipboardManager.updateSnippet(updatedSnippet)
        dismiss()
    }
}

// MARK: - Rename Folder Dialog

struct RenameFolderDialog: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.dismiss) private var dismiss

    let folder: SnippetFolder
    @Binding var newName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Folder")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("New name for '\(folder.name)':")
                    .font(.subheadline)
                TextField("Folder name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        // Pre-select the text for easy editing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let window = NSApplication.shared.keyWindow,
                               let textField = window.firstResponder as? NSTextField {
                                textField.selectText(nil)
                            }
                        }
                    }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    renameFolder()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func renameFolder() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            var updatedFolder = folder
            updatedFolder.rename(to: trimmedName)
            clipboardManager.updateFolder(updatedFolder)
        }
        dismiss()
    }
}

//
//  SaveSnippetDialog.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct SaveSnippetDialog: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Binding var isPresented: Bool

    let content: String

    @State private var snippetName: String = ""
    @State private var selectedFolderId: UUID?
    @State private var createNewFolder: Bool = false
    @State private var newFolderName: String = ""
    @State private var tags: String = ""
    @State private var contentPreview: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Save as Snippet")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Content Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Preview:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(contentPreview)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                }
                .frame(height: 100)
            }

            // Snippet Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Snippet Name:")
                    .font(.subheadline)

                TextField("Enter snippet name", text: $snippetName)
                    .textFieldStyle(.roundedBorder)
            }

            // Folder Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Save to Folder:")
                    .font(.subheadline)

                Picker("", selection: $selectedFolderId) {
                    Text("None")
                        .tag(nil as UUID?)
                    ForEach(clipboardManager.folders) { folder in
                        HStack {
                            Text(folder.icon)
                            Text(folder.name)
                        }
                        .tag(folder.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)

                // Create new folder option
                Toggle("Create new folder:", isOn: $createNewFolder)
                    .font(.subheadline)

                if createNewFolder {
                    HStack {
                        TextField("New folder name", text: $newFolderName)
                            .textFieldStyle(.roundedBorder)

                        Button(action: {
                            createFolder()
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .disabled(newFolderName.isEmpty)
                    }
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (optional):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("e.g., #email #template #meeting", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Action Buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save Snippet") {
                    saveSnippet()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(snippetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
        .onAppear {
            setupInitialState()
        }
    }

    // MARK: - Setup

    private func setupInitialState() {
        contentPreview = content
        snippetName = clipboardManager.suggestSnippetName(for: content)

        // Select first folder by default
        if let firstFolder = clipboardManager.folders.first {
            selectedFolderId = firstFolder.id
        }
    }

    // MARK: - Actions

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }

        clipboardManager.createFolder(name: newFolderName)

        // Select the newly created folder
        if let newFolder = clipboardManager.folders.last {
            selectedFolderId = newFolder.id
        }

        // Reset new folder creation
        createNewFolder = false
        newFolderName = ""
    }

    private func saveSnippet() {
        // Parse tags
        let tagArray = tags
            .components(separatedBy: CharacterSet(charactersIn: "#, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Save the snippet
        clipboardManager.saveAsSnippet(
            name: snippetName,
            content: content,
            folderId: selectedFolderId,
            tags: tagArray
        )

        // Close dialog
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    SaveSnippetDialog(
        isPresented: .constant(true),
        content: "This is a sample clipboard content that will be saved as a snippet.\n\nIt can be multiline and contain various types of text."
    )
    .environmentObject(ClipboardManager())
}

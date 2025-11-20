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
                    print("Dialog close button clicked")
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

            // Folder Selection - Simple Button List
            VStack(alignment: .leading, spacing: 8) {
                Text("Save to Folder:")
                    .font(.subheadline)

                VStack(spacing: 4) {
                    // None option
                    HStack {
                        Circle()
                            .fill(selectedFolderId == nil ? Color.blue : Color.clear)
                            .frame(width: 8, height: 8)
                        Text("None")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedFolderId == nil ? Color.blue.opacity(0.1) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFolderId = nil
                    }

                    // Existing folders
                    ForEach(clipboardManager.folders) { folder in
                        HStack {
                            Circle()
                                .fill(selectedFolderId == folder.id ? Color.blue : Color.clear)
                                .frame(width: 8, height: 8)
                            Text(folder.icon)
                            Text(folder.name)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedFolderId == folder.id ? Color.blue.opacity(0.1) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFolderId = folder.id
                        }
                    }
                }
                .frame(maxHeight: 120)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Create new folder option
                HStack {
                    Button(action: {
                        createNewFolder.toggle()
                    }) {
                        HStack {
                            Image(systemName: createNewFolder ? "checkmark.square" : "square")
                            Text("Create new folder:")
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    Spacer()
                }

                if createNewFolder {
                    HStack {
                        TextField("New folder name", text: $newFolderName)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(newFolderName.isEmpty ? .gray : .blue)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !newFolderName.isEmpty {
                                print("Create folder button clicked in dialog")
                                createFolder()
                            }
                        }
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

                HStack {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    print("Cancel button clicked")
                    isPresented = false
                }

                HStack {
                    Text("Save Snippet")
                        .foregroundColor(snippetName.isEmpty ? .secondary : .white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(snippetName.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !snippetName.isEmpty {
                        print("Save Snippet button clicked")
                        saveSnippet()
                    }
                }
            }
        }
        .padding()
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .allowsHitTesting(true)
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
        print("createFolder called with name: '\(newFolderName)'")
        guard !newFolderName.isEmpty else {
            print("Empty folder name, returning")
            return
        }

        clipboardManager.createFolder(name: newFolderName)
        print("Folder created: \(newFolderName)")

        // Select the newly created folder
        if let newFolder = clipboardManager.folders.last {
            selectedFolderId = newFolder.id
            print("Selected new folder: \(newFolder.name)")
        }

        // Reset new folder creation
        createNewFolder = false
        newFolderName = ""
        print("Folder creation UI reset")
    }

    private func saveSnippet() {
        print("saveSnippet called with name: '\(snippetName)'")

        // Parse tags
        let tagArray = tags
            .components(separatedBy: CharacterSet(charactersIn: "#, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        print("Parsed tags: \(tagArray)")
        print("Selected folder ID: \(selectedFolderId?.uuidString ?? "None")")

        // Save the snippet
        clipboardManager.saveAsSnippet(
            name: snippetName,
            content: content,
            folderId: selectedFolderId,
            tags: tagArray
        )

        print("Snippet saved successfully")

        // Close dialog with slight delay to prevent MenuBarExtra dismissal
        print("Closing dialog")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPresented = false
        }
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

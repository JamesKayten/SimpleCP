//
//  SaveSnippetDialog.swift
//  SimpleCP
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Save as Snippet").font(.headline)
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

            Text("Content Preview:").font(.caption).foregroundColor(.secondary)
            Text(contentPreview)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)

            Text("Snippet Name:").font(.caption)
            TextField("Name", text: $snippetName)
                .textFieldStyle(.roundedBorder)

            Text("Folder:").font(.caption)
            VStack(spacing: 2) {
                folderRow(label: "None", folderId: nil)
                ForEach(clipboardManager.folders) { folder in
                    folderRow(label: "\(folder.icon) \(folder.name)", folderId: folder.id)
                }
            }
            .frame(maxHeight: 60)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)

            Button(action: {
                createNewFolder.toggle()
            }) {
                HStack {
                    Image(systemName: createNewFolder ? "checkmark.square" : "square")
                    Text("New folder").font(.caption)
                }
            }
            .buttonStyle(.plain)

            if createNewFolder {
                HStack {
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onSubmit {
                            guard !newFolderName.isEmpty else { return }
                            let newFolderID = clipboardManager.createFolder(name: newFolderName)
                            selectedFolderId = newFolderID
                            createNewFolder = false
                            newFolderName = ""
                        }
                    Button(action: {
                        guard !newFolderName.isEmpty else { return }
                        let newFolderID = clipboardManager.createFolder(name: newFolderName)
                        selectedFolderId = newFolderID
                        createNewFolder = false
                        newFolderName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newFolderName.isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newFolderName.isEmpty)
                }
            }

            Text("Tags:").font(.caption).foregroundColor(.secondary)
            TextField("#tag1 #tag2", text: $tags)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)

                Button("Save") {
                    guard !snippetName.isEmpty else { return }
                    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        // TODO: Show error message for empty content
                        return
                    }
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
                    isPresented = false
                }
                .buttonStyle(.plain)
                .disabled(snippetName.isEmpty || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((snippetName.isEmpty || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? Color.gray : Color.blue)
                .foregroundColor((snippetName.isEmpty || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .secondary : .white)
                .cornerRadius(4)
            }
        }
        .padding(10)
        .frame(width: 380)
        .onAppear {
            // Initialize state when dialog appears
            contentPreview = content
            snippetName = clipboardManager.suggestSnippetName(for: content)
            
            // Set default folder selection only if not already set
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
                Text(label).font(.caption)
                Spacer()
            }
            .padding(3)
            .background(selectedFolderId == folderId ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

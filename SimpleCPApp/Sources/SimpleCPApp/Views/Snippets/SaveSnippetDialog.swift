//
//  SaveSnippetDialog.swift
//  SimpleCPApp
//
//  Complete snippet save workflow dialog
//

import SwiftUI
import AppKit

struct SaveSnippetDialog: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let prefillItem: ClipboardItem?

    @State private var snippetName: String = ""
    @State private var selectedFolder: String = ""
    @State private var createNewFolder: Bool = false
    @State private var newFolderName: String = ""
    @State private var tags: String = ""
    @State private var content: String = ""

    init(prefillItem: ClipboardItem? = nil) {
        self.prefillItem = prefillItem
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("💾 Save as Snippet")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            // Content preview
            GroupBox("Content Preview") {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
            }

            // Snippet name
            VStack(alignment: .leading, spacing: 4) {
                Text("Snippet Name:")
                    .font(.headline)
                TextField("Enter snippet name", text: $snippetName)
                    .textFieldStyle(.roundedBorder)
            }

            // Folder selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Save to Folder:")
                    .font(.headline)

                if !createNewFolder {
                    HStack {
                        Picker("", selection: $selectedFolder) {
                            Text("Select folder...").tag("")
                            ForEach(appState.snippetFolders) { folder in
                                Text(folder.name).tag(folder.name)
                            }
                        }
                        .labelsHidden()

                        Spacer()
                    }
                }

                Toggle("Create new folder:", isOn: $createNewFolder)

                if createNewFolder {
                    TextField("New folder name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (optional):")
                    .font(.headline)
                TextField("Enter tags separated by spaces", text: $tags)
                    .textFieldStyle(.roundedBorder)
                Text("Example: email template work")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Action buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save Snippet") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(snippetName.isEmpty || (selectedFolder.isEmpty && !createNewFolder) || (createNewFolder && newFolderName.isEmpty))
            }
        }
        .padding(24)
        .frame(width: 500)
        .onAppear {
            loadContent()
            suggestName()
        }
    }

    private func loadContent() {
        if let item = prefillItem {
            content = item.content
        } else {
            // Get current clipboard content
            if let pasteboardString = NSPasteboard.general.string(forType: .string) {
                content = pasteboardString
            }
        }
    }

    private func suggestName() {
        // Auto-suggest name based on content
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !firstLine.isEmpty {
            // Use first line or first few words
            let words = firstLine.components(separatedBy: .whitespaces).prefix(5)
            snippetName = words.joined(separator: " ")

            // Trim to reasonable length
            if snippetName.count > 50 {
                snippetName = String(snippetName.prefix(50)) + "..."
            }
        }

        // Set default folder if only one exists
        if appState.snippetFolders.count == 1 {
            selectedFolder = appState.snippetFolders[0].name
        }
    }

    private func saveSnippet() {
        Task {
            // Create new folder if needed
            let targetFolder: String
            if createNewFolder {
                await appState.createFolder(name: newFolderName)
                targetFolder = newFolderName
            } else {
                targetFolder = selectedFolder
            }

            // Parse tags
            let tagArray = tags
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }

            // Create snippet
            await appState.createSnippet(
                from: prefillItem,
                name: snippetName,
                folder: targetFolder,
                tags: tagArray
            )

            dismiss()
        }
    }
}

#Preview {
    SaveSnippetDialog(
        prefillItem: ClipboardItem(
            clipId: "1",
            content: "Sample content for preview",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            contentType: "text",
            displayString: "Sample content",
            sourceApp: nil,
            itemType: "history",
            hasName: false,
            snippetName: nil,
            folderPath: nil,
            tags: []
        )
    )
    .environmentObject(AppState())
}

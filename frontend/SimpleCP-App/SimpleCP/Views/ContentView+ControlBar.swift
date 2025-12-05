//
//  ContentView+ControlBar.swift
//  SimpleCP
//
//  Control bar and action methods extension for ContentView
//

import SwiftUI

extension ContentView {
    // MARK: - Control Bar

    var controlBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                print("Save snippet button clicked")
                SaveSnippetWindowManager.shared.showDialog(
                    content: clipboardManager.currentClipboard,
                    clipboardManager: clipboardManager,
                    onDismiss: {}
                )
            }) {
                Label("Save as Snippet", systemImage: "square.and.arrow.down")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderedProminent)
            .focusable()
            .help("Save current clipboard as snippet")

            Button(action: {
                print("New folder button clicked - creating auto-named folder")
                createAutoNamedFolder()
            }) {
                Label("New Folder", systemImage: "folder.badge.plus")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderedProminent)
            .focusable()
            .help("Create new snippet folder")

            Menu {
                Button("Create Folder") {
                    print("Menu: Create folder clicked")
                    createAutoNamedFolder()
                }
                Menu("Rename Folder...") {
                    if clipboardManager.folders.isEmpty {
                        Text("No folders to rename")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(clipboardManager.folders) { folder in
                            Button("\(folder.icon) \(folder.name)") {
                                RenameFolderWindowManager.shared.showDialog(
                                    folder: folder,
                                    clipboardManager: clipboardManager,
                                    onDismiss: {}
                                )
                            }
                        }
                    }
                }
                Divider()
                Button("Delete Empty Folders") {
                    deleteEmptyFolders()
                }
            } label: {
                Label("Manage Folders", systemImage: "folder")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .frame(height: 22)

            Button(action: {
                clearHistory()
            }) {
                Label("Clear History", systemImage: "trash")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .help("Clear all clipboard history")

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Actions

    func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear History"
        alert.informativeText = "Are you sure you want to clear all clipboard history?"
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            clipboardManager.clearHistory()
        }
    }

    func createAutoNamedFolder() {
        // Generate a unique folder name
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"

        // Find the next available folder name
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }

        // Create the folder immediately without any dialog
        _ = clipboardManager.createFolder(name: proposedName)
        print("✅ Auto-created folder: \(proposedName)")
    }

    func deleteEmptyFolders() {
        let emptyFolders = clipboardManager.folders.filter { folder in
            clipboardManager.getSnippets(for: folder.id).isEmpty
        }

        for folder in emptyFolders {
            clipboardManager.deleteFolder(folder)
        }
    }

    func exportSnippets() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SimpleCP-Snippets.json"

        if panel.runModal() == .OK, let url = panel.url {
            let data = ExportData(
                snippets: clipboardManager.snippets,
                folders: clipboardManager.folders
            )

            if let encoded = try? JSONEncoder().encode(data) {
                try? encoded.write(to: url)
            }
        }
    }

    func importSnippets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(ExportData.self, from: data) {
                // Merge imported data
                for folder in decoded.folders {
                    if !clipboardManager.folders.contains(where: { $0.id == folder.id }) {
                        clipboardManager.folders.append(folder)
                    }
                }
                for snippet in decoded.snippets {
                    if !clipboardManager.snippets.contains(where: { $0.id == snippet.id }) {
                        clipboardManager.snippets.append(snippet)
                    }
                }
            }
        }
    }
}

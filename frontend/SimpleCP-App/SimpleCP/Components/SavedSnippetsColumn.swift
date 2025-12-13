//
//  SavedSnippetsColumn.swift
//  SimpleCP
//
//  Extensions: +SnippetRow
//

import SwiftUI

struct SavedSnippetsColumn: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    @Binding var selectedFolderId: UUID?

    @State private var hoveredSnippetId: UUID?
    @State private var editingSnippetId: UUID?
    @Environment(\.fontPreferences) private var fontPrefs

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty { return clipboardManager.snippets }
        return clipboardManager.snippets.filter { snippet in
            snippet.name.localizedCaseInsensitiveContains(searchText) ||
            snippet.content.localizedCaseInsensitiveContains(searchText) ||
            snippet.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var sortedFolders: [SnippetFolder] {
        clipboardManager.folders.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader
            Divider()
            foldersList
        }
    }

    private var columnHeader: some View {
        HStack {
            Image(systemName: "folder.fill").foregroundColor(.secondary)
            Text("SNIPPETS").font(fontPrefs.interfaceFont(weight: .semibold)).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .contextMenu { headerContextMenu }
    }

    @ViewBuilder
    private var headerContextMenu: some View {
        Button(action: { createAutoNamedFolder() }) { Label("New Folder", systemImage: "folder.badge.plus") }
        Divider()
        Button(action: { exportSnippets() }) { Label("Export All Snippets...", systemImage: "square.and.arrow.up") }
        Button(action: { importSnippets() }) { Label("Import Snippets...", systemImage: "square.and.arrow.down") }
        Divider()
        Button(action: { deleteEmptyFolders() }) { Label("Delete Empty Folders", systemImage: "trash") }
        Divider()
        Text("\(clipboardManager.snippets.count) snippets in \(clipboardManager.folders.count) folders").foregroundColor(.secondary)
    }

    private var foldersList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(sortedFolders) { folder in
                    let folderSnippets = getSnippets(for: folder.id)
                    if !folderSnippets.isEmpty || searchText.isEmpty {
                        FolderView(
                            folder: folder, snippets: folderSnippets, searchText: searchText,
                            isSelected: selectedFolderId == folder.id,
                            hoveredSnippetId: $hoveredSnippetId, editingSnippetId: $editingSnippetId,
                            onSelect: { selectedFolderId = folder.id }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func getSnippets(for folderId: UUID) -> [Snippet] {
        let folderSnippets = clipboardManager.getSnippets(for: folderId)
        if searchText.isEmpty { return folderSnippets }
        return folderSnippets.filter { snippet in
            filteredSnippets.contains(where: { $0.id == snippet.id })
        }
    }

    // MARK: - Folder Management

    private func createAutoNamedFolder() {
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }
        _ = clipboardManager.createFolder(name: proposedName)
        print("✅ Auto-created folder: \(proposedName)")
    }

    private func deleteEmptyFolders() {
        let emptyFolders = clipboardManager.folders.filter { folder in
            clipboardManager.getSnippets(for: folder.id).isEmpty
        }

        if emptyFolders.isEmpty {
            let alert = NSAlert()
            alert.messageText = "No Empty Folders"
            alert.informativeText = "There are no empty folders to delete."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Delete Empty Folders"
        alert.informativeText = "Are you sure you want to delete \(emptyFolders.count) empty folder(s)?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            for folder in emptyFolders { clipboardManager.deleteFolder(folder) }
            print("✅ Deleted \(emptyFolders.count) empty folder(s)")
        }
    }

    // MARK: - Export/Import

    private func exportSnippets() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SimpleCP-Snippets-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        panel.message = "Export all snippets and folders to a JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            let data = ExportData(snippets: clipboardManager.snippets, folders: clipboardManager.folders)
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(data).write(to: url)
                print("✅ Exported \(clipboardManager.snippets.count) snippets")
            } catch {
                showExportError(error)
            }
        }
    }

    private func importSnippets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Import snippets and folders from a JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(ExportData.self, from: data)
                var foldersAdded = 0, snippetsAdded = 0

                for folder in decoded.folders {
                    if !clipboardManager.folders.contains(where: { $0.id == folder.id }) {
                        clipboardManager.folders.append(folder)
                        foldersAdded += 1
                    }
                }
                for snippet in decoded.snippets {
                    if !clipboardManager.snippets.contains(where: { $0.id == snippet.id }) {
                        clipboardManager.snippets.append(snippet)
                        snippetsAdded += 1
                    }
                }
                showImportSuccess(snippetsAdded: snippetsAdded, foldersAdded: foldersAdded)
            } catch {
                showImportError(error)
            }
        }
    }

    private func showExportError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Export Failed"
        alert.informativeText = "Could not export snippets: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showImportError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Import Failed"
        alert.informativeText = "Could not import snippets: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showImportSuccess(snippetsAdded: Int, foldersAdded: Int) {
        let alert = NSAlert()
        alert.messageText = "Import Successful"
        alert.informativeText = "Added \(snippetsAdded) snippets and \(foldersAdded) folders"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

#Preview {
    SavedSnippetsColumn(searchText: "", selectedFolderId: .constant(nil))
        .environmentObject(ClipboardManager())
        .frame(width: 300, height: 400)
}

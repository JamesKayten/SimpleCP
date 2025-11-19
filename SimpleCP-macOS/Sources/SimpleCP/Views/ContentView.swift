//
//  ContentView.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var showSaveSnippetDialog = false
    @State private var selectedClipForSave: ClipItem?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Search Bar
            searchBar

            // Control Bar
            controlBar

            Divider()

            // Two-Column Layout
            HSplitView {
                // Left Column: Recent Clips
                RecentClipsColumn(
                    searchText: searchText,
                    onSaveAsSnippet: { clip in
                        selectedClipForSave = clip
                        showSaveSnippetDialog = true
                    }
                )
                .frame(minWidth: 250, idealWidth: 300)

                // Right Column: Saved Snippets
                SavedSnippetsColumn(searchText: searchText)
                    .frame(minWidth: 250, idealWidth: 300)
            }
        }
        .sheet(isPresented: $showSaveSnippetDialog) {
            SaveSnippetDialog(
                content: selectedClipForSave?.content ?? clipboardManager.currentClipboard,
                isPresented: $showSaveSnippetDialog
            )
            .environmentObject(clipboardManager)
        }
        // Error alert for clipboard manager errors
        .alert("Error", isPresented: $clipboardManager.showError, presenting: clipboardManager.lastError) { error in
            Button("OK", role: .cancel) {
                clipboardManager.lastError = nil
            }
        } message: { error in
            VStack(alignment: .leading, spacing: 8) {
                if let description = error.errorDescription {
                    Text(description)
                }
                if let recovery = error.recoverySuggestion {
                    Text("\n\(recovery)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("SimpleCP")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                openWindow(id: "settings")
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clips and snippets...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                showSaveSnippetDialog = true
            }) {
                Label("Save as Snippet", systemImage: "square.and.arrow.down")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .help("Save current clipboard as snippet")

            Menu {
                Button("Create Folder...") {
                    createNewFolder()
                }
                Button("Rename Folder...") {
                    // TODO: Implement
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

            Button(action: {
                exportSnippets()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .help("Export snippets")

            Button(action: {
                importSnippets()
            }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .help("Import snippets")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Actions

    private func createNewFolder() {
        let alert = NSAlert()
        alert.messageText = "Create New Folder"
        alert.informativeText = "Enter a name for the new folder:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "Folder name"
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let folderName = textField.stringValue
            if !folderName.isEmpty {
                clipboardManager.createFolder(name: folderName)
            }
        }
    }

    private func clearHistory() {
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

    private func deleteEmptyFolders() {
        let emptyFolders = clipboardManager.folders.filter { folder in
            clipboardManager.getSnippets(for: folder.id).isEmpty
        }

        for folder in emptyFolders {
            clipboardManager.deleteFolder(folder)
        }
    }

    private func exportSnippets() {
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

    private func importSnippets() {
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

// MARK: - Export Data Model

struct ExportData: Codable {
    let snippets: [Snippet]
    let folders: [SnippetFolder]
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .frame(width: 600, height: 400)
}

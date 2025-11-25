//
//  ContentView.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var backendService: BackendService
    @State private var searchText = ""
    @State private var showSaveSnippetDialog = false
    @State private var selectedClipForSave: ClipItem?
    @State private var showCreateFolderSheet = false
    @State private var newFolderName = ""
    @State private var showRenameFolderPicker = false
    @State private var folderToRename: SnippetFolder?
    @State private var renameFolderNewName = ""
    @State private var selectedFolderId: UUID?

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
                SavedSnippetsColumn(searchText: searchText, selectedFolderId: $selectedFolderId)
                    .frame(minWidth: 250, idealWidth: 300)
            }
        }
        .focusable()
        .sheet(isPresented: $showSaveSnippetDialog) {
            SaveSnippetDialog(
                isPresented: $showSaveSnippetDialog,
                content: selectedClipForSave?.content ?? clipboardManager.currentClipboard
            )
            .environmentObject(clipboardManager)
        }
        .sheet(item: $folderToRename) { folder in
            RenameFolderDialogView(
                folder: folder,
                newName: $renameFolderNewName,
                onRename: { newName in
                    var updatedFolder = folder
                    updatedFolder.rename(to: newName)
                    clipboardManager.updateFolder(updatedFolder)
                    folderToRename = nil
                },
                onCancel: {
                    folderToRename = nil
                }
            )
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
            HStack(spacing: 8) {
                Text("SimpleCP")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Connection Status Indicator
                connectionStatusIndicator
            }

            Spacer()

            Button(action: {
                print("Settings button clicked - TODO: implement settings")
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

    // MARK: - Connection Status Indicator

    private var connectionStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(connectionStatusColor.opacity(0.3), lineWidth: 1)
                        .scaleEffect(connectionPulseScale)
                        .animation(connectionAnimation, value: backendService.isRunning)
                )

            Text(connectionStatusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(connectionStatusBackgroundColor)
        .cornerRadius(8)
        .help(connectionTooltipText)
        .onTapGesture {
            // Allow manual restart on tap
            if !backendService.isRunning {
                backendService.restartBackend()
            }
        }
    }

    // MARK: - Connection Status Properties

    private var connectionStatusColor: Color {
        if backendService.isRunning {
            return .green
        } else if backendService.isMonitoring {
            return .orange
        } else {
            return .red
        }
    }

    private var connectionStatusText: String {
        if backendService.isRunning {
            return "Connected"
        } else if backendService.isMonitoring {
            return "Connecting..."
        } else {
            return "Offline"
        }
    }

    private var connectionStatusBackgroundColor: Color {
        if backendService.isRunning {
            return Color.green.opacity(0.1)
        } else if backendService.isMonitoring {
            return Color.orange.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }

    private var connectionTooltipText: String {
        if backendService.isRunning {
            return "Backend is connected and running"
        } else if backendService.isMonitoring {
            if backendService.restartCount > 0 {
                return "Reconnecting... (attempt \(backendService.restartCount))"
            }
            return "Connecting to backend..."
        } else {
            return "Backend is offline - tap to restart"
        }
    }

    private var connectionPulseScale: CGFloat {
        backendService.isMonitoring && !backendService.isRunning ? 1.5 : 1.0
    }

    private var connectionAnimation: Animation? {
        if backendService.isMonitoring && !backendService.isRunning {
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        }
        return .easeInOut(duration: 0.3)
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
                print("Save snippet button clicked")
                showSaveSnippetDialog = true
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
                                renameFolderNewName = folder.name
                                folderToRename = folder
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

    private func createAutoNamedFolder() {
        // Generate a unique folder name
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"

        // Find the next available folder name
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }

        // Create the folder immediately without any dialog
        clipboardManager.createFolder(name: proposedName)
        print("✅ Auto-created folder: \(proposedName)")
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

// MARK: - Create Folder Sheet

struct CreateFolderSheet: View {
    @Binding var isPresented: Bool
    @Binding var folderName: String
    let clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Create New Folder")
                    .font(.headline)
                Spacer()
                Button(action: {
                    print("Folder dialog close button clicked")
                    isPresented = false
                }) {
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
            }

            Divider()

            // Action Buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    print("Folder creation cancelled")
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create Folder") {
                    print("Creating folder with name: '\(folderName)'")
                    if !folderName.isEmpty {
                        clipboardManager.createFolder(name: folderName)
                        print("✅ Folder created: \(folderName)")
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Rename Folder Dialog View

struct RenameFolderDialogView: View {
    let folder: SnippetFolder
    @Binding var newName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void

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
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    let trimmedName = newName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty {
                        onRename(trimmedName)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .frame(width: 600, height: 400)
}

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    // Data
    @Published var recentClips: [ClipboardItem] = []
    @Published var snippetFolders: [SnippetFolder] = []

    // UI State
    @Published var showCreateSnippet = false
    @Published var showManageFolders = false
    @Published var showClearHistory = false
    @Published var showSettings = false

    // Selection State
    @Published var selectedClipForSnippet: ClipboardItem?
    @Published var selectedFolderForQuickAdd: String?

    // API Client
    private var apiClient: APIClient?

    init() {
        // Load initial data (will be replaced with API calls)
        loadSampleData()
    }

    // MARK: - Data Loading

    func loadSampleData() {
        recentClips = ClipboardItem.samples
        snippetFolders = SnippetFolder.samples
    }

    func setAPIClient(_ client: APIClient) {
        self.apiClient = client
    }

    func refreshData() async {
        guard let apiClient = apiClient else { return }

        do {
            async let clips = apiClient.getHistory()
            async let snippets = apiClient.getSnippets()

            recentClips = try await clips
            let snippetsDict = try await snippets

            // Convert snippets dictionary to folder array
            snippetFolders = snippetsDict.map { folderName, items in
                SnippetFolder(
                    name: folderName,
                    icon: iconForFolder(folderName),
                    snippets: items
                )
            }.sorted { $0.name < $1.name }
        } catch {
            print("Error refreshing data: \(error)")
        }
    }

    // MARK: - Clipboard Operations

    func removeClip(_ clip: ClipboardItem) {
        recentClips.removeAll { $0.id == clip.id }

        Task {
            guard let apiClient = apiClient else { return }
            try? await apiClient.deleteHistoryItem(id: clip.clipId)
        }
    }

    func clearAllHistory() {
        recentClips.removeAll()

        Task {
            guard let apiClient = apiClient else { return }
            try? await apiClient.clearHistory()
        }
    }

    // MARK: - Snippet Operations

    func createSnippet(name: String, content: String, folderName: String, tags: [String]) {
        Task {
            guard let apiClient = apiClient else { return }

            let request = CreateSnippetRequest(
                content: content,
                snippetName: name,
                folderPath: folderName,
                tags: tags
            )

            do {
                try await apiClient.createSnippet(request: request)
                await refreshData()
            } catch {
                print("Error creating snippet: \(error)")
            }
        }
    }

    func deleteSnippet(_ snippet: ClipboardItem, from folderName: String) {
        if let folderIndex = snippetFolders.firstIndex(where: { $0.name == folderName }) {
            snippetFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        }

        Task {
            guard let apiClient = apiClient else { return }
            try? await apiClient.deleteSnippet(folderId: folderName, itemId: snippet.clipId)
        }
    }

    func editSnippet(_ snippet: ClipboardItem, in folderName: String) {
        // TODO: Implement edit snippet dialog
        print("Edit snippet: \(snippet.snippetName ?? "Unnamed")")
    }

    func renameSnippet(_ snippet: ClipboardItem, in folderName: String) {
        // TODO: Implement rename snippet dialog
        print("Rename snippet: \(snippet.snippetName ?? "Unnamed")")
    }

    func duplicateSnippet(_ snippet: ClipboardItem, in folderName: String) {
        // TODO: Implement duplicate snippet
        print("Duplicate snippet: \(snippet.snippetName ?? "Unnamed")")
    }

    func moveSnippet(_ snippet: ClipboardItem, from sourceFolderName: String, to targetFolderName: String) {
        // Remove from source folder
        if let sourceIndex = snippetFolders.firstIndex(where: { $0.name == sourceFolderName }) {
            snippetFolders[sourceIndex].snippets.removeAll { $0.id == snippet.id }
        }

        // Add to target folder
        if let targetIndex = snippetFolders.firstIndex(where: { $0.name == targetFolderName }) {
            var updatedSnippet = snippet
            snippetFolders[targetIndex].snippets.append(updatedSnippet)
        }

        // TODO: Update via API
    }

    // MARK: - Folder Operations

    func toggleFolder(_ folderName: String) {
        if let index = snippetFolders.firstIndex(where: { $0.name == folderName }) {
            snippetFolders[index].isExpanded.toggle()
        }
    }

    func createFolder(name: String, icon: String = "folder.fill") {
        let newFolder = SnippetFolder(name: name, icon: icon)
        snippetFolders.append(newFolder)

        Task {
            guard let apiClient = apiClient else { return }
            try? await apiClient.createFolder(name: name)
        }
    }

    func renameFolder(_ oldName: String) {
        // TODO: Implement rename folder dialog
        print("Rename folder: \(oldName)")
    }

    func changeFolderIcon(_ folderName: String) {
        // TODO: Implement icon picker
        print("Change icon for folder: \(folderName)")
    }

    func deleteFolder(_ folderName: String) {
        snippetFolders.removeAll { $0.name == folderName }

        Task {
            guard let apiClient = apiClient else { return }
            try? await apiClient.deleteFolder(name: folderName)
        }
    }

    // MARK: - Utilities

    private func iconForFolder(_ folderName: String) -> String {
        switch folderName.lowercased() {
        case let name where name.contains("email"):
            return "envelope.fill"
        case let name where name.contains("code"):
            return "chevron.left.forwardslash.chevron.right"
        case let name where name.contains("text"):
            return "text.alignleft"
        case let name where name.contains("work"):
            return "briefcase.fill"
        default:
            return "folder.fill"
        }
    }
}

// MARK: - Preview Support

extension AppState {
    static var preview: AppState {
        let state = AppState()
        state.loadSampleData()
        return state
    }
}

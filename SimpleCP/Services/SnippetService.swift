import Foundation

// Service for snippet CRUD operations
@MainActor
class SnippetService: ObservableObject {
    private let apiClient: APIClient
    private let appState: AppState

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    // Load snippets from backend
    func loadSnippets() async {
        appState.isLoading = true
        appState.errorMessage = nil

        do {
            let snippets = try await apiClient.getSnippets()
            appState.updateSnippets(from: snippets)
        } catch {
            appState.errorMessage = "Failed to load snippets: \(error.localizedDescription)"
        }

        appState.isLoading = false
    }

    // Create new snippet
    func createSnippet(content: String, name: String, folder: String, tags: [String]) async {
        do {
            let request = CreateSnippetRequest(
                content: content,
                snippetName: name,
                folderPath: folder,
                tags: tags
            )
            try await apiClient.createSnippet(request: request)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to create snippet: \(error.localizedDescription)"
        }
    }

    // Update snippet
    func updateSnippet(folderId: String, itemId: String, name: String?, tags: [String]?) async {
        do {
            let request = UpdateSnippetRequest(snippetName: name, tags: tags)
            try await apiClient.updateSnippet(folderId: folderId, itemId: itemId, request: request)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to update snippet: \(error.localizedDescription)"
        }
    }

    // Delete snippet
    func deleteSnippet(folderId: String, itemId: String) async {
        do {
            try await apiClient.deleteSnippet(folderId: folderId, itemId: itemId)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to delete snippet: \(error.localizedDescription)"
        }
    }

    // Create folder
    func createFolder(name: String) async {
        do {
            try await apiClient.createFolder(name: name)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    // Rename folder
    func renameFolder(oldName: String, newName: String) async {
        do {
            try await apiClient.renameFolder(oldName: oldName, newName: newName)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to rename folder: \(error.localizedDescription)"
        }
    }

    // Delete folder
    func deleteFolder(name: String) async {
        do {
            try await apiClient.deleteFolder(name: name)
            await loadSnippets()
        } catch {
            appState.errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    // Refresh data from backend
    func refresh() async {
        await loadSnippets()
    }
}

import Foundation

@MainActor
class ClipboardService: ObservableObject {
    @Published var historyItems: [ClipboardItem] = []
    @Published var snippetFolders: [SnippetFolder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    func fetchHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            historyItems = try await apiClient.getHistory()
        } catch {
            errorMessage = "Failed to fetch history: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchSnippets() async {
        isLoading = true
        errorMessage = nil

        do {
            snippetFolders = try await apiClient.getAllSnippets()
        } catch {
            errorMessage = "Failed to fetch snippets: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func copyItem(_ item: ClipboardItem) async {
        do {
            try await apiClient.copyToClipboard(clipId: item.id)
        } catch {
            errorMessage = "Failed to copy item: \(error.localizedDescription)"
        }
    }

    func search(query: String) async -> SearchResults? {
        guard !query.isEmpty else { return nil }

        do {
            return try await apiClient.search(query: query)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            return nil
        }
    }

    func createSnippet(from item: ClipboardItem, name: String, folder: String) async {
        do {
            _ = try await apiClient.createSnippet(
                clipId: item.id,
                name: name,
                folder: folder
            )
            // Refresh snippets after creation
            await fetchSnippets()
        } catch {
            errorMessage = "Failed to create snippet: \(error.localizedDescription)"
        }
    }
}
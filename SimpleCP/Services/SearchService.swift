import Foundation

// Service for search functionality
@MainActor
class SearchService: ObservableObject {
    private let apiClient: APIClient
    private let appState: AppState

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    // Search across history and snippets
    func search(query: String) async {
        guard !query.isEmpty else {
            appState.clearSearch()
            return
        }

        appState.isSearching = true
        appState.errorMessage = nil

        do {
            let results = try await apiClient.search(query: query)
            appState.searchResults = results
        } catch {
            appState.errorMessage = "Search failed: \(error.localizedDescription)"
        }

        appState.isSearching = false
    }

    // Clear search
    func clearSearch() {
        appState.clearSearch()
    }
}

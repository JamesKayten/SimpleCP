import Foundation

// Service for clipboard history operations
@MainActor
class ClipboardService: ObservableObject {
    private let apiClient: APIClient
    private let appState: AppState

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    // Load history from backend
    func loadHistory() async {
        appState.isLoading = true
        appState.errorMessage = nil

        do {
            let items = try await apiClient.getHistory()
            appState.historyItems = items
        } catch {
            appState.errorMessage = "Failed to load history: \(error.localizedDescription)"
        }

        appState.isLoading = false
    }

    // Load history folders
    func loadHistoryFolders() async {
        do {
            let folders = try await apiClient.getHistoryFolders()
            appState.historyFolders = folders
        } catch {
            appState.errorMessage = "Failed to load history folders: \(error.localizedDescription)"
        }
    }

    // Delete history item
    func deleteHistoryItem(_ item: ClipboardItem) async {
        do {
            try await apiClient.deleteHistoryItem(id: item.clipId)
            await loadHistory()
            await loadHistoryFolders()
        } catch {
            appState.errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // Clear all history
    func clearHistory() async {
        do {
            try await apiClient.clearHistory()
            appState.historyItems = []
            appState.historyFolders = []
        } catch {
            appState.errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }

    // Copy item to clipboard
    func copyToClipboard(_ item: ClipboardItem) async {
        do {
            try await apiClient.copyToClipboard(itemId: item.clipId)
        } catch {
            appState.errorMessage = "Failed to copy to clipboard: \(error.localizedDescription)"
        }
    }

    // Refresh data from backend
    func refresh() async {
        await loadHistory()
        await loadHistoryFolders()
    }
}
